--[[

LÖVE Version: 11.4

This snippet gets all of the system cursors reported by LÖVE/SDL2 and sets them according to a basic hierarchy:

* The "override" cursor, if applicable
* Cursors associated with widgets (represented as simple axis-aligned rectangles)
* The default cursor

--]]


if not love.mouse.isCursorSupported() then -- touchscreen-oriented platforms
	error("this system does not support custom cursors.")
end

love.keyboard.setKeyRepeat(true)

local image_bg = love.graphics.newImage("res/bg.png")


-- Get the system cursors.
-- Depending on your OS, you may get some duplicates instead the expected images.
local sys_curs = {}


-- https://love2d.org/wiki/CursorType
local cursor_id_list = {
	-- NOTE: 'image' is not valid for getSystemCursor().
	"arrow",
	"ibeam",
	"wait",
	"waitarrow",
	"crosshair",
	"sizenwse",
	"sizenesw",
	"sizewe",
	"sizens",
	"sizeall",
	"no",
	"hand"
}

local cursor_id_default = "arrow"
local cursor_id_busy = "wait"

local override_enabled = false
local cursor_override = cursor_id_busy

local cursor_id_current = cursor_id_default
local cursor_id_last = false

local widgets = {}

-- UI chrome
local status_bar_h = 48


local function loadSystemCursor(id)

	local cur = {}

	cur.id = id
	cur.obj = love.mouse.getSystemCursor(id)

	sys_curs[id] = cur
end


local function reloadCursor()
	love.mouse.setCursor(sys_curs[cursor_id_current].obj)
end


local function sign(num)
	return num < 0 and -1 or num > 0 and 1 or 0
end


function love.load()

	local win_w, win_h = love.graphics.getDimensions()

	-- Make some fake widgets.
	for i, id in ipairs(cursor_id_list) do
		loadSystemCursor(id)

		local wid = {}

		wid.w = love.math.random(32, 256)
		wid.h = love.math.random(32, 256)
		wid.x = love.math.random(0, win_w - wid.w)
		wid.y = love.math.random(0, win_h - wid.h)

		wid.dx = love.math.random(-1, 1) * love.math.random(64, 128)
		wid.dy = love.math.random(-1, 1) * love.math.random(64, 128)

		wid.r = love.math.random()
		wid.g = love.math.random()
		wid.b = love.math.random()
		wid.a = 1.0

		wid.cursor_id = id

		table.insert(widgets, wid)
	end
end


function love.keypressed(kc, sc)

	-- Quit!
	if sc == "escape" then
		love.event.quit()

	-- Toggle the override cursor.
	elseif sc == "tab" then
		override_enabled = not override_enabled

	-- Pick the override cursor.
	elseif sc >= "1" and sc <= "9" then
		cursor_override = cursor_id_list[tonumber(sc)]

	elseif sc == "0" then
		cursor_override = cursor_id_list[10]

	elseif sc == "-" then
		cursor_override = cursor_id_list[11]

	elseif sc == "=" then
		cursor_override = cursor_id_list[12]
	end

	-- Debug: test changing the cursor 65536 times in one frame.
	--[[
	if kc == "t" then
		local time_start = love.timer.getTime()
		for i = 1, 2^16 do
			local ii = ((i-1) % #cursor_id_list) + 1
			local cur = sys_curs[ cursor_id_list[ii] ]
			love.mouse.setCursor(cur.obj)
		end
		print(love.timer.getTime() - time_start)
	end
	--]]
end


function love.update(dt)

	local win_w, win_h = love.graphics.getDimensions()

	local mouse_1 = love.mouse.isDown(1)
	local mouse_2 = love.mouse.isDown(2)

	local mouse_x, mouse_y = love.mouse.getPosition()

	local mouse_power = 500

	-- Per-widget behavior. (All of this loop is totally unrelated to handling the cursor.)
	for i, wid in ipairs(widgets) do

		-- Move the widgets around.
		wid.x = wid.x + wid.dx * dt
		wid.y = wid.y + wid.dy * dt

		-- Pull widget toward the cursor
		if mouse_1 then
			wid.dx = wid.dx + mouse_power * dt * sign(mouse_x - wid.x - wid.w/2)
			wid.dy = wid.dy + mouse_power * dt * sign(mouse_y - wid.y - wid.h/2)

		-- Halt widget
		elseif mouse_2 then
			wid.dx = wid.dx * (1 - dt * 8.0) -- probably not correct but whatever
			wid.dy = wid.dy * (1 - dt * 8.0)

			-- Bring to a stop beneath a certain threshold.
			if math.abs(wid.dx) < 0.01 then
				wid.dx = 0
			end
			if math.abs(wid.dy) < 0.01 then
				wid.dy = 0
			end
		end

		-- Slow widget down if they are faster than 256 pixels per second on either axis.
		if math.abs(wid.dx) > 256 then
			wid.dx = wid.dx * (1 - dt * 0.5)
		end
		if math.abs(wid.dy) > 256 then
			wid.dy = wid.dy * (1 - dt * 0.5)
		end

		-- Bounce off of window edges
		if wid.x < 0 then
			wid.dx = math.abs(wid.dx)
		end
		if wid.x + wid.w >= win_w then
			wid.dx = -math.abs(wid.dx)
		end
		if wid.y < 0 then
			wid.dy = math.abs(wid.dy)
		end
		if wid.y + wid.h >= win_h then
			wid.dy = -math.abs(wid.dy)
		end

		-- Keep widget in window
		wid.x = math.max(0, math.min(wid.x, win_w - wid.w))
		wid.y = math.max(0, math.min(wid.y, win_h - wid.h))
	end

	-- Okay, onto the actual cursor handling.

	local widget_mouse_over = false

	-- Widgets with higher indexes are rendered later, so we can just iterate backwards to find the
	-- topmost widget that the mouse is hovering over.
	if mouse_y < win_h - status_bar_h then
		for i = #widgets, 1, -1 do
			local wid = widgets[i]

			if mouse_x >= wid.x and mouse_x < wid.x + wid.w and mouse_y >= wid.y and mouse_y < wid.y + wid.h then
				widget_mouse_over = wid
				break
			end
		end
	end

	-- Cursor override is in effect: always set the override ID.
	if override_enabled then
		cursor_id_current = cursor_override

	-- Not hovering over anything: display the default cursor.
	elseif not widget_mouse_over then
		cursor_id_current = cursor_id_default

	-- Hovering over something: display its cursor ID.
	else
		cursor_id_current = widget_mouse_over.cursor_id
	end

	-- Update cursor if its ID is different from the previous frame.
	--[[
	One can update the cursor repeatedly in a single frame, and the new cursor will show up, even if the application
	is hanging / busylooping. If you find a suitable use for this (???), you can return the cursor to its previous
	setting once the busyloop is done by blanking out your equivalent of 'cursor_id_last'.
	--]]
	if cursor_id_current ~= cursor_id_last then
		reloadCursor()
		cursor_id_last = cursor_id_current
	end
end


function love.draw()

	local win_w, win_h = love.graphics.getDimensions()

	love.graphics.push("all")

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(image_bg, 0, 0, 0, win_w / image_bg:getWidth(), win_h / image_bg:getHeight(), 0, 0, 0, 0)

	for i, wid in ipairs(widgets) do

		local wx = math.floor(wid.x)
		local wy = math.floor(wid.y)
		local ww = math.floor(wid.w)
		local wh = math.floor(wid.h)

		love.graphics.setScissor(wx, wy, ww, wh)
		love.graphics.setColor(wid.r, wid.g, wid.b, wid.a)
		love.graphics.rectangle("fill", wx, wy, ww, wh)
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
		love.graphics.rectangle("line", wx+1, wy+1, ww-2, wh-2)

		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.printf(wid.cursor_id, wx + 4, wy + 4, ww - 8, "left")
		if (wid.r + wid.g + wid.b) / 3 < 0.5 then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(0, 0, 0, 1)
		end
		love.graphics.printf(wid.cursor_id, wx + 4, wy + 4, ww - 8, "left")
	end

	love.graphics.pop()
	
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, win_h - status_bar_h, win_w, status_bar_h)

	love.graphics.setColor(1,1,1,1)
	love.graphics.print("TAB: Toggle cursor override (" .. tostring(override_enabled) ..
		")\t1-9,0,-,=: Set override cursor (" .. tostring(cursor_override) ..
		")\tESCAPE: Quit\nMouse1: agitate widgets\tMouse2: calm widgets",
		8, win_h - status_bar_h + 8
	)
end

