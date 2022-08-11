--[[
	NOTE: This snippet is obsolete. See 'quadSlice' for a 9slice drawing library:
	https://github.com/rabbitboots/quad_slice

	A basic 9-Slice example using quads (all referencing one image).
	
	REGARDING SEMI-TRANSPARENCY:
	I'm not sure if this is 100% reliable when drawing with semi-transparent alpha. There could be thin
	slivers of overdraw due to floating point rounding. Maybe flooring the coordinates and dimensions
	would work? One possible (though kind of heavy) solution would be to draw the 9-Slice to a canvas at
	full alpha, then draw the canvas at the desired alpha level.
--]]

love.keyboard.setKeyRepeat(true)

local image = love.graphics.newImage("image.png")
--[[
	IMAGE LAYOUT:
	* Each corner is 11x11 pixels in size.
	* The edges are one-pixel slivers of the bottom and right corner tiles.
	* The center is a single pixel from the bottom-right tile.
	* The entire image is surrounded by a perimeter of extruded pixels.

	All border pixels should match the pixels on the connecting tile/edge/center.
--]]

local slice_w = 11
local slice_h = 11

local box_w = 64
local box_h = 64

local mx, my = 0, 0 -- mouse position

local demo_center = true
local demo_linear = true
local demo_floor = true
local demo_zoom = 1.0
local demo_show_tex = false

-- Set up the quads. Layout:
--	1 2 3
--	4 5 6
--	7 8 9

local quads = {}
do
	local START_X, START_Y = 1, 1 -- skip past the extrusion perimeter

	quads[1] = love.graphics.newQuad(START_X,           START_Y,           slice_w, slice_h, image) -- Top-left
	quads[2] = love.graphics.newQuad(START_X + slice_w, START_Y,           1,       slice_h, image) -- Top
	quads[3] = love.graphics.newQuad(START_X + slice_w, START_Y,           slice_w, slice_h, image) -- Top-right
	quads[4] = love.graphics.newQuad(START_X,           START_Y + slice_h, slice_w, 1,       image) -- Left
	quads[5] = love.graphics.newQuad(START_X + slice_w, START_Y + slice_h, 1,       1,       image) -- Center
	quads[6] = love.graphics.newQuad(START_X + slice_w, START_Y + slice_h, slice_w, 1,       image) -- Right
	quads[7] = love.graphics.newQuad(START_X,           START_Y + slice_h, slice_w, slice_h, image) -- Bottom-left
	quads[8] = love.graphics.newQuad(START_X + slice_w, START_Y + slice_h, 1,       slice_h, image) -- Bottom
	quads[9] = love.graphics.newQuad(START_X + slice_w, START_Y + slice_h, slice_w, slice_h, image) -- Bottom-right
end


local function draw9Slice(image, quads, x, y, w, h)

	-- We need column and row dimensions to position and stretch the tiles.
	-- For this demo, we'll just read the quad viewport dimensions every time.
	-- It'd likely be faster to pass these in as arguments.
	local _, _, c1w, r1h = quads[1]:getViewport()
	local _, _, c3w, r3h = quads[9]:getViewport()

	local mid_w = w - c1w - c3w
	local mid_h = h - r1h - r3h

	-- In case of overlap, draw in this order: center, sides, corners.

	-- Draw center
	love.graphics.draw(image, quads[5], x + slice_w,         y + slice_h,         0, mid_w, mid_h)

	-- Draw sides
	love.graphics.draw(image, quads[4], x,                   y + slice_h,         0, 1,     mid_h)
	love.graphics.draw(image, quads[6], x + slice_w + mid_w, y + slice_h,         0, 1,     mid_h)
	love.graphics.draw(image, quads[2], x + slice_w,         y,                   0, mid_w, 1)
	love.graphics.draw(image, quads[8], x + slice_w,         y + slice_h + mid_h, 0, mid_w, 1)

	-- Draw corners
	love.graphics.draw(image, quads[1], x,                   y,                   0, 1,     1)
	love.graphics.draw(image, quads[3], x + slice_w + mid_w, y,                   0, 1,     1)
	love.graphics.draw(image, quads[7], x,                   y + slice_h + mid_h, 0, 1,     1)
	love.graphics.draw(image, quads[9], x + slice_w + mid_w, y + slice_h + mid_h, 0, 1,     1)
end


function love.keypressed(kc, sc)
	-- (Some keyboard controls are in love.update() so they can grab the current frame's delta time.)
	if sc == "escape" then
		love.event.quit()
	elseif sc == "tab" then
		demo_center = not demo_center
	elseif sc == "pagedown" then
		demo_zoom = math.max(1, demo_zoom - 1)
	elseif sc == "pageup" then
		demo_zoom = math.min(64, demo_zoom + 1)
	elseif sc == "1" then
		demo_linear = not demo_linear
		if demo_linear then
			image:setFilter("linear", "linear")
		else
			image:setFilter("nearest", "nearest")
		end
	elseif sc == "2" then
		demo_floor = not demo_floor
	elseif sc == "3" then
		demo_show_tex = not demo_show_tex
	end
end


function love.wheelmoved(x, y)
	demo_zoom = math.min(64, math.max(1, demo_zoom + y))
end


function love.update(dt)
	mx = love.mouse.getX() / demo_zoom
	my = love.mouse.getY() / demo_zoom

	local amp = 128

	local scan = love.keyboard.isScancodeDown

	if scan("lshift", "rshift") then
		amp = amp * 4
	elseif scan ("lctrl", "rctrl") then
		amp = amp / 32
	end

	if scan("left") then
		box_w = box_w - amp * dt
	elseif scan("right") then
		box_w = box_w + amp * dt
	end

	if scan("up") then
		box_h = box_h - amp * dt
	elseif scan("down") then
		box_h = box_h + amp * dt
	end
end


local function down(d)
	d = d and d*16 or 16
	love.graphics.translate(0, d)
end


function love.draw()
	-- Prevent div/0
	box_w = math.max(slice_w*2, box_w)
	box_h = math.max(slice_h*2, box_h)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.scale(demo_zoom)

	local disp_bw, disp_bh = box_w, box_h
	local disp_mx, disp_my = mx, my

	if demo_center then
		disp_mx = disp_mx - disp_bw/2
		disp_my = disp_my - disp_bh/2
	end

	if demo_floor then
		disp_bw = math.floor(disp_bw)
		disp_bh = math.floor(disp_bh)

		disp_mx = math.floor(disp_mx)
		disp_my = math.floor(disp_my)
	end

	draw9Slice(image, quads, disp_mx, disp_my, disp_bw, disp_bh)

	love.graphics.origin()
	
	love.graphics.setColor(0, 0, 0, 0.75)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 100)
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.translate(8, 8)

	love.graphics.print("MOUSE: Move box\tARROW KEYS: Adjust box dimensions\tSHIFT: Faster\tCONTROL: Slower\tTAB: Center/decenter\n1: linear/nearest filtering\t2: flooring on/off\t3: Show texture\tPAGEUP/PAGEDOWN: Zoom\tESCAPE: Quit")

	down(3)
	love.graphics.print("Box W " .. box_w)
	love.graphics.print("Zoom " .. demo_zoom, 175, 0)
	love.graphics.print("Linear Filt. " .. tostring(demo_linear), 350, 0)
	down()
	love.graphics.print("Box H " .. box_h)
	love.graphics.print("Flooring " .. tostring(demo_floor), 175, 0)
	down()
	
	love.graphics.origin()
	if demo_show_tex then
		love.graphics.draw(
			image,
			love.graphics.getWidth() - image:getWidth() - 16,
			love.graphics.getHeight() - image:getHeight() - 16
		)
	end
end
