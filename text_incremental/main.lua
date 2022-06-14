require("lib.strict") -- catch accidental globals

--[[

	Prints a string one character at a time, using LÖVE coloredtext tables and lg.printf().

	It works by writing out the entire string in coloredtext format, assigning one color table
	for every code point in the text. At the start, all code points have zero alpha. Printing
	glyphs is then just a matter of progressively changing the color for each code point,
	independent of actually drawing the coloredtext table in love.draw().

	Two timing methods are provided: the default counts elapsed time, while the other method maps
	time to the width of characters.

	Limitations: I guess there could be conflicts with shaders. It's also not as optimized as it
	could be.

--]]

local utf8 = require("utf8")

-- Normally I wouldn't include this in a small snippet, but I need help printing instructions
-- and state without adding noise to the memory counter.
local quickPrint = require("lib.quick_print.quick_print")
local qp = quickPrint.new()

love.keyboard.setKeyRepeat(true)

local demo_font_size = 16
local demo_font = love.graphics.newFont(demo_font_size)
local ui_font = love.graphics.newFont(13)

love.graphics.setFont(demo_font)

-- Demo strings to use
local demo_messages = {
	"The quick brown fox jumps over the lazy dog.",
}
local demo_message_i = 1

-- Size of the text box relative to the application window.
local demo_text_box_scale = 0.8

-- Initialized in love.load
local demo_text_box


-- * Helpers *


local function copyColor(col_from, col_to)
	col_to[1], col_to[2], col_to[3], col_to[4] = col_from[1], col_from[2], col_from[3], col_from[4]
end


--- Break a string into an array of color + code point pairs. We will cram some additional metadata into the color table
--  as named fields.
-- @param str The string to convert.
-- @param color_t The default colors to assign.
-- @return A coloredtext version of 'str'.
local function stringToColoredText(str, color_t, font)

	local colored_text = {}

	local last_glyph = utf8.offset(str, -1)

	local i = 1
	while i <= #str do
		local i2 = utf8.offset(str, 2, i)

		local char_header = {}
		copyColor(color_t, char_header)

		local string_left = string.sub(str, 1, i - 1)
		local sub_str = string.sub(str, i, i2 - 1)

		char_header.x = font:getWidth(string.sub(str, 1, i - 1))
		char_header.w = font:getWidth(sub_str)

		-- If applicable, subtract kerning offset from width (this is used for the distance update mode).
		if i < last_glyph then
			local glyph_right = utf8.codepoint(str, utf8.offset(str, 2, i))
			if glyph_right ~= 0x0a then -- line feed ("\n")
				char_header.w = char_header.w - font:getKerning(utf8.codepoint(sub_str), glyph_right)
			end
		end

		table.insert(colored_text, char_header)
		table.insert(colored_text, sub_str)
		i = i2
	end

	return colored_text
end


-- * / Helpers *


-- * Text box logic *


--- Create a new text box object.
-- @param font (Default: whatever's currently active) The font to use for drawing and measuring.
local function newTextBox(font)

	local text_box = {}

	text_box.x = 0
	text_box.y = 0
	text_box.w = 0
	text_box.h = 0

	text_box.source_text = ""
	text_box.colored_text = {}
	text_box.font = font or love.graphics.getFont()

	text_box.color_on = {1, 1, 1, 1}
	text_box.color_off = {1, 1, 1, 0}

	text_box.running = false

	-- Is true when the full message has been written out.
	text_box.complete = false

	text_box.advance_mode = "time" -- "time", "distance"

	-- Count progress in terms of unicode code points. We can track line and array indexes
	-- within the span of a single tick, but we cannot rely on that across ticks because the
	-- text box may have been re-wrapped.
	text_box.visible_u_chars = 0

	-- time mode
	text_box.timer = 0
	text_box.timer_max = 1/12

	-- distance mode
	text_box.distance_pixels_per_second = 128
	text_box.distance_x = 0
	text_box.distance_x_next = 0

	text_box.align = "left"

	return text_box
end


--- Refresh a text box's visual state (following a resize or other graphical change).
local function textBoxRefresh(text_box)

	local font = text_box.font

	-- Convert source string to a coloredtext sequence, where each code-point gets its own color table
	-- (plus some additional metadata.)
	text_box.colored_text = stringToColoredText(text_box.source_text, text_box.color_off, font)

	-- Catch up to the latest visible code point.
	local visible_u_chars = text_box.visible_u_chars
	if text_box.complete then
		visible_u_chars = math.huge
	end

	local index = 1, 1

	while visible_u_chars > 0 and index <= #text_box.colored_text do

		local color_entry = text_box.colored_text[index]
		if not color_entry then
			break
		end

		copyColor(text_box.color_on, color_entry)
		index = index + 2
		visible_u_chars = visible_u_chars - 1
	end
end


--- Set up a text box to print a new message.
local function textBoxInitMessage(text_box, str)

	text_box.running = true
	text_box.complete = false

	text_box.visible_u_chars = 0

	text_box.timer = 0
	text_box.distance_x = 0

	text_box.source_text = str

	textBoxRefresh(text_box)
end


local function textBoxTick(text_box, dt)

	if text_box.running then
		if text_box.advance_mode == "time" then

			text_box.timer = text_box.timer + dt

			local safety = 64
			while text_box.timer >= text_box.timer_max do

				text_box.timer = text_box.timer - text_box.timer_max
				text_box.visible_u_chars = text_box.visible_u_chars + 1

				local ind_n = text_box.visible_u_chars * 2 - 1
				local c_text = text_box.colored_text

				if ind_n < #c_text then
					local color_t, sub_str = c_text[ind_n], c_text[ind_n + 1]

					copyColor(text_box.color_on, color_t)

				-- Done?
				else
					text_box.running = false
					text_box.complete = true
					break
				end

				safety = safety - 1
				if safety <= 0 then
					break
				end
			end

		elseif text_box.advance_mode == "distance" then

			text_box.distance_x = text_box.distance_x + dt * text_box.distance_pixels_per_second

			local safety = 64
			while safety > 0 do

				if text_box.distance_x >= text_box.distance_x_next then
					text_box.distance_x = text_box.distance_x - text_box.distance_x_next
					text_box.visible_u_chars = text_box.visible_u_chars + 1

					local ind_n = text_box.visible_u_chars * 2 - 1
					local c_text = text_box.colored_text

					if ind_n < #c_text then
						local color_t, sub_str = c_text[ind_n], c_text[ind_n + 1]

						copyColor(text_box.color_on, color_t)
						text_box.distance_x_next = color_t.w

					-- Done?
					else
						text_box.running = false
						text_box.complete = true
						break
					end
				end

				safety = safety - 1
			end
		end
	end
end


-- * / Text box logic *


local function resizeCenterTextBox(text_box, win_scale)

	local old_w, old_h = text_box.w, text_box.h

	local win_w, win_h = love.graphics.getDimensions()

	text_box.w = math.max(0, math.floor(0.5 + win_w*win_scale))
	text_box.h = math.max(0, math.floor(0.5 + win_h*win_scale))
	text_box.x = math.floor(0.5 + win_w/2 - text_box.w/2)
	text_box.y = math.floor(0.5 + win_h/2 - text_box.h/2)

	-- Reconstruct message state if the dimensions have changed.
	if text_box.w ~= old_w or text_box.h ~= old_h then
		textBoxRefresh(text_box)
	end
end


-- * Demo interface logic *


local function demoReplaceFontReferences()
	demo_text_box.font = demo_font
end


local function demoReloadFont(size)

	local old_font = demo_font
	demo_font = love.graphics.newFont(size)

	demoReplaceFontReferences()

	if old_font then
		old_font:release()
	end

	collectgarbage("collect")
	collectgarbage("collect")
end


local function setSensiblePixelsPerSecond(text_box, font)
	local M_width = font:getWidth("M")
	text_box.distance_pixels_per_second = M_width * 9
end


-- * / Demo interface logic *


-- * LÖVE Callbacks *

function love.load(arguments)
	demo_text_box = newTextBox(demo_font)

	resizeCenterTextBox(demo_text_box, demo_text_box_scale)
	setSensiblePixelsPerSecond(demo_text_box, demo_font)
	
	textBoxInitMessage(demo_text_box, "The quick brown fox jumpeth over the lazy doggeth.")
end


function love.resize(w, h)
	resizeCenterTextBox(demo_text_box, demo_text_box_scale)
end


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()

	elseif sc == "tab" then
		if love.keyboard.isScancodeDown("lshift", "rshift") then
			demo_message_i = demo_message_i - 1
			if demo_message_i < 1 then
				demo_message_i = #demo_messages
			end

		else
			demo_message_i = demo_message_i + 1
			if demo_message_i > #demo_messages then
				demo_message_i = 1
			end
		end

		textBoxInitMessage(demo_text_box, demo_messages[demo_message_i])

	elseif sc == "f1" then
		demo_text_box.advance_mode = (demo_text_box.advance_mode == "time") and "distance" or "time"

	elseif sc == "f5" then
		demo_font_size = math.max(1, demo_font_size - 1)
		demoReloadFont(demo_font_size)
		setSensiblePixelsPerSecond(demo_text_box, demo_font)
		textBoxRefresh(demo_text_box)

	elseif sc == "f6" then
		demo_font_size = math.min(72, demo_font_size + 1)
		demoReloadFont(demo_font_size)
		setSensiblePixelsPerSecond(demo_text_box, demo_font)
		textBoxRefresh(demo_text_box)

	elseif sc == "f9" then
		demo_text_box.align = "left"

	elseif sc == "f10" then
		demo_text_box.align = "center"

	elseif sc == "f11" then
		demo_text_box.align = "right"

	elseif sc == "f12" then
		love.window.setVSync(1 - love.window.getVSync())
	end
end


function love.update(dt)
	textBoxTick(demo_text_box, dt)
end


function love.draw()

	-- Draw the text box.

	love.graphics.push("all")

	love.graphics.setFont(demo_font)

	local font = demo_text_box.font
	local text_h = font:getHeight() * font:getLineHeight()

	local border = 4

	love.graphics.translate(demo_text_box.x, demo_text_box.y)

	love.graphics.setColor(0.25, 0.25, 0.25, 1.0)
	love.graphics.rectangle("fill", 0, 0, demo_text_box.w, demo_text_box.h)

	love.graphics.setLineWidth(border)
	love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
	love.graphics.rectangle("line", -border, -border, demo_text_box.w + border*2, demo_text_box.h + border*2)

	love.graphics.setScissor(demo_text_box.x, demo_text_box.y, demo_text_box.w, demo_text_box.h)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(demo_text_box.colored_text, 0, 0, demo_text_box.w, demo_text_box.align)

	love.graphics.pop()

	-- Draw the UI / instructions.

	love.graphics.push("all")

	qp:reset()
	qp:setOrigin(8, 4)
	qp:setVerticalPadding(4)

	local a_course, a_marg = 64, 16

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 48)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(ui_font)

	qp:write1("Esc: Quit")
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("(Shift+)Tab: Cycle message: ", demo_message_i)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write1("Up/Down: Scroll")
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("F9/F10/F11: align: ", demo_text_box.align)
	qp:advanceXCoarse(a_course, a_marg)

	qp:down()

	qp:write2("F12: Vsync: ", love.window.getVSync())
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("F5/F6: Font sz: ", demo_font_size)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("F1: Advance mode: ", demo_text_box.advance_mode)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("FPS: ", love.timer.getFPS())
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("Delta: ", love.timer.getAverageDelta())
	qp:advanceXCoarse(a_course, a_marg)

	local bar2_h = 48
	local bar2_y = love.graphics.getHeight() - bar2_h

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, bar2_y, love.graphics.getWidth(), bar2_h)

	love.graphics.setColor(1, 1, 1, 1)

	qp:setPosition(0, bar2_y)
	qp:write2("timer: ", math.floor(demo_text_box.timer*100)/100)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("F3/F4: timer_max: ", demo_text_box.timer_max)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("F7/F8: dist p/s: ", demo_text_box.distance_pixels_per_second)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("Mem (KB): ", math.floor(collectgarbage("count")*10)/10)
	qp:advanceXCoarse(a_course, a_marg)

	qp:down()

	qp:write2("dist x: ", math.floor(demo_text_box.distance_x*100)/100)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("dist x next: ", math.floor(demo_text_box.distance_x*100)/100)
	qp:advanceXCoarse(a_course, a_marg)

	love.graphics.pop()
end


-- * / LÖVE Callbacks *


