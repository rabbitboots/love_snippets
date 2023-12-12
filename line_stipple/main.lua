-- Tested with LÖVE 11.4, 11.5 and 12.0-development (17362b6).

--[[

	A line stipple example.
	I made this after trying the two examples on the LÖVE Wiki, here: https://love2d.org/wiki/LineStippleSnippet

	See also this forum thread: https://love2d.org/forums/viewtopic.php?t=83295

	Features of this version:
	* Adds a 'phase' variable which offsets the starting segment and gap.
	* Guards against divide-by-zero.
	* Adds a loop safety limit, so it won't attempt to draw an infinite number of segments.

	It's probably slower as a result of these things.

--]]

love.keyboard.setKeyRepeat(true)

local mx, my = 0, 0
local lx, ly = 300, 300

local seg_len = 25
local gap_len = 25
local phase = 0.0

local demo_show_points = false

local function lineDotted(x1, y1, x2, y2, seg_len, gap_len, phase)

	-- Defaults
	phase = phase or 0.0
	seg_len = seg_len or 7
	gap_len = gap_len or 5

	local dx, dy = (x2-x1), (y2-y1)
	local length = math.sqrt(dx*dx + dy*dy)

	-- Prevent divide by zero
	if length <= 0 or seg_len <= 0 or gap_len <= 0 then
		return
	end

	-- Clamp line drawing to this region. Lines with zero width and height will not be visible.
	local x_min, x_max = math.min(x1, x2), math.max(x1, x2)
	local y_min, y_max = math.min(y1, y2), math.max(y1, y2)

	-- Length of each line segment and gap
	local seg_dx = dx / (length / seg_len)
	local seg_dy = dy / (length / seg_len)

	local gap_dx = dx / (length / gap_len)
	local gap_dy = dy / (length / gap_len)

	-- Phase offset
	phase = phase % 1.0
	x1 = x1 - (seg_dx + gap_dx) * phase
	y1 = y1 - (seg_dy + gap_dy) * phase

	local x, y = x1, y1
	local safety = 2048

	while true do
		love.graphics.line(
			math.max(x_min, math.min(x_max, x)),
			math.max(y_min, math.min(y_max, y)),
			math.max(x_min, math.min(x_max, x + seg_dx)),
			math.max(y_min, math.min(y_max, y + seg_dy))
		)

		x = x + seg_dx + gap_dx
		y = y + seg_dy + gap_dy

		safety = safety - 1

		if safety <= 0
		or x1 < x2 and x > x_max or x1 > x2 and x < x_min
		or y1 < y2 and y > y_max or y1 > y2 and y < y_min
		then
			break
		end
	end
end


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()
		return
	elseif sc == "left" then
		lx = lx - 16
	elseif sc == "right" then
		lx = lx + 16
	elseif sc == "up" then
		ly = ly - 16
	elseif sc == "down" then
		ly = ly + 16
	elseif sc == "1" then
		seg_len = math.max(0, seg_len - 1)
	elseif sc == "2" then
		seg_len = seg_len + 1
	elseif sc == "3" then
		gap_len = math.max(0, gap_len - 1)
	elseif sc == "4" then
		gap_len = gap_len + 1
	elseif sc == "pageup" then
		phase = (phase - 0.1) % 1.0
	elseif sc == "pagedown" then
		phase = (phase + 0.1) % 1.0
	elseif sc == "tab" then
		demo_show_points = not demo_show_points
	end
end


function love.update(dt)
	mx = love.mouse.getX()
	my = love.mouse.getY()
end


function love.draw()
	local lg = love.graphics

	lg.translate(16, 16)

	lg.print("ESCAPE: Quit\tARROW KEYS: Move start\tMOUSE: Move end\tTAB: Show start/end")

	lg.translate(0, 32)

	lg.print("FPS: " .. love.timer.getFPS()); lg.translate(0, 16)
	lg.print("AvgDelta: " .. love.timer.getAverageDelta())

	lg.translate(0, 32)

	lg.print("(1-2) seg_len " .. seg_len); lg.translate(0, 16)
	lg.print("(3-4) gap_len " .. gap_len); lg.translate(0, 16)
	lg.print("(pgup-pgdn) phase " .. phase); lg.translate(0, 16)
	
	lg.origin()
	
	lineDotted(lx, ly, mx, my, seg_len, gap_len, phase)
	
	if demo_show_points then
		lg.circle("line", lx, ly, 16)
		lg.circle("line", mx, my, 16)
	end
end

