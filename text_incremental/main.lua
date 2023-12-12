-- Tested with LÖVE 11.4 and 11.5.

-- NOTE: There are some issues with this snippet in 12.0-development, as of commit a51ea94. If you watch demo text #2,
-- the sentence 'The five boxing wizards jump quickly' suddenly completes upon reaching the word 'five'. I think this
-- is because the 'f' and 'i' are shaped into a single 'ﬁ' glyph, and it seems that the coloredtext mapping code in
-- 12.0 is a work in progress. See this comment:
-- https://github.com/love2d/love/blob/a51ea9430b1428ac01accda28c13e3e02366e195/src/modules/font/freetype/HarfbuzzShaper.cpp#L247

-- Catch accidental global assignments
require("lib.strict")

--[[

	This snippet demonstrates a method of incrementally printing a string, one character at a time,
	using LÖVE coloredtext tables and love.graphics.printf(). The logic is implemented as part of a
	simple text box abstraction.

	How it works: When you assign a message to the text box, it converts the string to a
	coloredtext array, where every character gets its own color table. All color tables start with
	an alpha value of zero. Printing glyphs is then just a matter of progressively changing the
	color for each code point, independent of actually drawing the coloredtext table in love.draw().

	Two timing methods are provided: the default counts elapsed time, while the 'distance' method
	maps time to the width of characters.

	I'm not 100% happy with how this turned out, so it's presented in the form of a snippet and
	not a library / drop-in solution.

	Limitations:
	* I guess there could be conflicts with shaders. It's also not as optimized as it could be.
	* 'coloredtext' array creation happens at the initial call. The bigger the input string, the
	  longer it will take to generate the array. This might be an issue for very big strings. (Or
	  maybe not. I haven't tested anything bigger than a few paragraphs.) Either way, if you want
	  pages and pages of scrollable text, you will likely require a different approach.

--]]


local MIT_LICENSE_TEXT = [[
Copyright 2022 RBTS
Some textual contents sourced from the public domain -- see source code for links.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]


local utf8 = require("utf8")

-- Normally I wouldn't include auxiliary dependencies like QuickPrint in a small snippet, but I
-- need help printing instructions and state without string concatenation adding noise to the
-- memory counter.
local quickPrint = require("lib.quick_print.quick_print")
local qp = quickPrint.new()

love.keyboard.setKeyRepeat(true)

-- Demo state
local demo_font_size = 16
local demo_font = love.graphics.newFont(demo_font_size)
local ui_font = love.graphics.newFont(13)

local demo_speed_mult = 1.0

-- Recycle color tables here.
-- (I would probably do this in a real implementation, though as a snippet, it muddles things a bit.
-- I've already written it though, so I'll leave it as-is.)
local demo_color_stack = {}
local demo_color_stack_max = 1024

local function colorTableToStack(color_t)
	if #demo_color_stack < demo_color_stack_max and type(color_t) == "table" then
		table.insert(demo_color_stack, color_t)
	end
end


love.graphics.setFont(demo_font)


-- Demo strings to use.
local demo_messages = {
	-- 1
	"INSTRUCTIONS!"
	.. "\n"
	.. "\n\n* Hold SPACE to temporarily accelerate the speed of printing."
	.. "\n\n* Press RETURN (ENTER) to complete the message immediately."
	.. "\n\n* Hold UP/DOWN to scroll, or PAGEUP/PAGEDOWN to scroll faster."
	.. "\n\n* Press TAB or SHIFT+TAB to cycle through messages."
	.. "\n\n* Press F1 to switch between a timer-based delimiter and a distance-based one."
	.. "\n\n* Press F3/F4 to adjust the timer threshold (lower is faster)."
	.. "\n\n* Press F5/F6 to resize the font."
	.. "\n\n* Press F7/F8 to adjust the distance threshold (higher is faster)."
	.. "\n\t(This is reset to a value based on the width of the 'M' glyph when you adjust the font size.)"
	.. "\n\n* Press F9, F10 or F11 to set the printing alignment to left, center or right, respectively."
	.. "\n\n* Press F12 to toggle VSync."
	.. "\n\n* Resize the window to change the text box size."
	.. "\n\n",

	-- 2
	"The quick brown fox jumps over the lazy dog.\n\nJackdaws love my big sphinx of quartz.\n\nThe five boxing wizards jump quickly.\n\nAaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz\n\n0123456789\n\näëïöüÿ",

	-- 3
	[[
Thin glyphs:
|||||||||||||||||||||||||||||||||||||||||

Wide glyphs:
WWWWWWWWWWWWW
]],

	-- 4
	-- https://www.lipsum.com/
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",

	-- 5
	-- https://www.gutenberg.org/files/120/120-h/120-h.htm
	[[
THE appearance of the island when I came on deck next morning was altogether changed. Although the breeze had now utterly ceased, we had made a great deal of way during the night and were now lying becalmed about half a mile to the south-east of the low eastern coast. Grey-coloured woods covered a large part of the surface. This even tint was indeed broken up by streaks of yellow sand-break in the lower lands, and by many tall trees of the pine family, out-topping the others—some singly, some in clumps; but the general colouring was uniform and sad. The hills ran up clear above the vegetation in spires of naked rock. All were strangely shaped, and the Spy-glass, which was by three or four hundred feet the tallest on the island, was likewise the strangest in configuration, running up sheer from almost every side and then suddenly cut off at the top like a pedestal to put a statue on.

The Hispaniola was rolling scuppers under in the ocean swell. The booms were tearing at the blocks, the rudder was banging to and fro, and the whole ship creaking, groaning, and jumping like a manufactory. I had to cling tight to the backstay, and the world turned giddily before my eyes, for though I was a good enough sailor when there was way on, this standing still and being rolled about like a bottle was a thing I never learned to stand without a qualm or so, above all in the morning, on an empty stomach.

Perhaps it was this—perhaps it was the look of the island, with its grey, melancholy woods, and wild stone spires, and the surf that we could both see and hear foaming and thundering on the steep beach—at least, although the sun shone bright and hot, and the shore birds were fishing and crying all around us, and you would have thought anyone would have been glad to get to land after being so long at sea, my heart sank, as the saying is, into my boots; and from the first look onward, I hated the very thought of Treasure Island.]],

	-- 6
	-- https://opensource.org/licenses/MIT
	MIT_LICENSE_TEXT,
}
local demo_message_i = 1

-- Size of the text box relative to the application window. 1.0 == use the whole window.
local demo_text_box_scale = 0.8

-- Initialized in love.load
local demo_text_box


-- * Helpers *

--- This just copies the first four numeric fields (red, green, blue, alpha) from one table to another.
local function copyColor(col_from, col_to)
	col_to[1], col_to[2], col_to[3], col_to[4] = col_from[1], col_from[2], col_from[3], col_from[4]
end


--- Break a string into an array of color + code point pairs. We will cram some additional metadata into the color table
--  as named fields.
-- @param str The string to convert.
-- @param color_t The default colors to assign.
-- @param colored_text An existing array to write to or overwrite.
-- @param font The font used by the text box.
-- @return Nothing. 'colored_text' is modified in-place.
local function stringToColoredText(str, color_t, colored_text, font)

	local last_glyph = utf8.offset(str, -1)

	local i = 1 -- Byte offset in UTF-8 string
	local j = 1 -- Index in coloredtext table

	while i <= #str do
		local i2 = utf8.offset(str, 2, i)

		local char_header = table.remove(demo_color_stack) or {}
		copyColor(color_t, char_header)

		local string_left = string.sub(str, 1, i - 1)
		local sub_str = string.sub(str, i, i2 - 1)

		char_header.w = font:getWidth(sub_str)

		-- If applicable, subtract kerning offset from width (this is used for the distance update mode).
		if i < last_glyph then
			local glyph_right = utf8.codepoint(str, utf8.offset(str, 2, i))
			if glyph_right ~= 0x0a then -- line feed ("\n")
				char_header.w = char_header.w - font:getKerning(utf8.codepoint(sub_str), glyph_right)
			end
		end

		colored_text[j] = char_header
		colored_text[j + 1] = sub_str

		j = j + 2
		i = i2
	end

	-- Trim unused entries, and return unused color tables to the stack
	for k = #colored_text, j + 1, -1 do
		colorTableToStack(colored_text[k])
		colored_text[k] = nil
	end
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

	-- The RGBA values to apply to visible and yet-to-be-displayed glyphs.
	text_box.color_on = {1, 1, 1, 1}
	text_box.color_off = {1, 1, 1, 0}

	text_box.running = false

	-- Is true when the full message has been written out.
	text_box.complete = false

	text_box.advance_mode = "time" -- "time", "distance"

	-- Count progress in terms of Unicode code points.
	text_box.visible_u_chars = 0

	-- time mode
	text_box.timer = 0
	text_box.timer_max = 6/256 -- lower is faster

	-- distance mode
	text_box.distance_pixels_per_second = 128 -- higher is faster
	text_box.distance_x = 0
	text_box.distance_x_next = 0

	-- "left", "center", "right", and technically "justify", though that might give unexpected results with
	-- only a few words on a line.
	text_box.align = "left"

	text_box.n_lines = 1 -- Used to determine Y scroll bound.
	text_box.scroll_y = 0
	text_box.scroll_y_min = 0
	text_box.scroll_y_max = 0

	return text_box
end


local function textBoxEnforceScrollYBounds(text_box)
	text_box.scroll_y = math.max(text_box.scroll_y_min, math.min(text_box.scroll_y, text_box.scroll_y_max))
end


--- Refresh a text box's visual state (following a resize or other graphical change).
local function textBoxRefresh(text_box)

	local font = text_box.font

	-- Convert source string to a coloredtext sequence, where each code-point gets its own color table
	-- (plus some additional metadata.)
	stringToColoredText(text_box.source_text, text_box.color_off, text_box.colored_text, font)

	-- Catch up to the latest visible code point.
	local visible_u_chars = text_box.visible_u_chars
	if text_box.complete then
		visible_u_chars = math.huge
	end

	local index = 1

	while visible_u_chars > 0 and index <= #text_box.colored_text do

		local color_entry = text_box.colored_text[index]
		if not color_entry then
			break
		end

		copyColor(text_box.color_on, color_entry)
		index = index + 2
		visible_u_chars = visible_u_chars - 1
	end

	-- Need getWrap() to determine the number of lines in the text.
	local width, wrapped_lines = font:getWrap(text_box.source_text, text_box.w)
	text_box.n_lines = #wrapped_lines

	local line_h = math.ceil(font:getHeight() * font:getLineHeight())

	-- Allow scrolling one line above and below the text.
	text_box.scroll_y_min = -line_h
	text_box.scroll_y_max = line_h + math.ceil(text_box.n_lines * line_h - text_box.h)
	textBoxEnforceScrollYBounds(text_box)
end


--- Set up a text box to print a new message. Reset Y scroll position.
local function textBoxInitMessage(text_box, str)

	text_box.running = true
	text_box.complete = false

	text_box.visible_u_chars = 0

	text_box.timer = 0
	text_box.distance_x = 0

	text_box.source_text = str

	textBoxRefresh(text_box)

	text_box.scroll_y = text_box.scroll_y_min
end


--- Immediately finalize a message.
local function textBoxCompleteMessage(text_box)
	if not text_box.complete then
		text_box.visible_u_chars = math.huge
		text_box.complete = true

		textBoxRefresh(text_box)
	end
end


--- The text box per-frame tick callback.
local function textBoxTick(text_box, dt)

	if text_box.running then
		if text_box.advance_mode == "time" then

			text_box.timer = text_box.timer + dt

			local safety = 1024
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

			local safety = 1024
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


-- * Demo interface logic *


local function resizeCenterTextBox(text_box, win_scale)

	local old_w, old_h = text_box.w, text_box.h
	local win_w, win_h = love.graphics.getDimensions()

	text_box.w = math.max(0, math.floor(0.5 + win_w*win_scale))
	text_box.h = math.max(0, math.floor(0.5 + win_h*win_scale))
	text_box.x = math.floor(0.5 + win_w/2 - text_box.w/2)
	text_box.y = math.floor(0.5 + win_h/2 - text_box.h/2)

	-- Reconstruct text box state if the dimensions have changed.
	if text_box.w ~= old_w or text_box.h ~= old_h then
		textBoxRefresh(text_box)
	end
end


local function demoReloadFont(size)

	local old_font = demo_font
	demo_font = love.graphics.newFont(size)

	demo_text_box.font = demo_font

	if old_font then
		old_font:release()
	end

	collectgarbage("collect")
	collectgarbage("collect")
end


local function setSensiblePixelsPerSecond(text_box, font)
	local M_width = font:getWidth("M")
	text_box.distance_pixels_per_second = M_width * 24
end


-- * / Demo interface logic *


-- * LÖVE Callbacks *

function love.load(arguments)
	demo_text_box = newTextBox(demo_font)

	resizeCenterTextBox(demo_text_box, demo_text_box_scale)
	setSensiblePixelsPerSecond(demo_text_box, demo_font)

	textBoxInitMessage(demo_text_box, demo_messages[demo_message_i])
end


function love.resize(w, h)
	resizeCenterTextBox(demo_text_box, demo_text_box_scale)
end


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()

	elseif sc == "return" or sc == "kpenter" then
		textBoxCompleteMessage(demo_text_box)

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

	elseif sc == "f3" then
		demo_text_box.timer_max = math.max(0, demo_text_box.timer_max - 1/256)

	elseif sc == "f4" then
		demo_text_box.timer_max = math.min(1, demo_text_box.timer_max + 1/256)

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

	elseif sc == "f7" then
		demo_text_box.distance_pixels_per_second = math.min(4096, demo_text_box.distance_pixels_per_second - 10)

	elseif sc == "f8" then
		demo_text_box.distance_pixels_per_second = math.max(0, demo_text_box.distance_pixels_per_second + 10)

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

	local scanDown = love.keyboard.isScancodeDown

	if scanDown("up") then
		demo_text_box.scroll_y = demo_text_box.scroll_y - 350*dt
		textBoxEnforceScrollYBounds(demo_text_box)

	elseif scanDown("pageup") then
		demo_text_box.scroll_y = demo_text_box.scroll_y - 700*dt
		textBoxEnforceScrollYBounds(demo_text_box)		

	elseif scanDown("down") then
		demo_text_box.scroll_y = demo_text_box.scroll_y + 350*dt
		textBoxEnforceScrollYBounds(demo_text_box)

	elseif scanDown("pagedown") then
		demo_text_box.scroll_y = demo_text_box.scroll_y + 700*dt
		textBoxEnforceScrollYBounds(demo_text_box)
	end

	if scanDown("space") then
		demo_speed_mult = 4.0
	else
		demo_speed_mult = 1.0
	end

	textBoxTick(demo_text_box, dt * demo_speed_mult)
end


function love.draw()

	-- Draw the text box.

	love.graphics.push("all")

	love.graphics.setFont(demo_font)

	local font = demo_text_box.font
	local text_h = font:getHeight() * font:getLineHeight()

	local border = 4

	love.graphics.translate(demo_text_box.x, demo_text_box.y)

	love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
	love.graphics.setLineWidth(border*2)
	love.graphics.rectangle("line", -border, -border, demo_text_box.w + border*2, demo_text_box.h + border*2)
	love.graphics.setColor(0.25, 0.25, 0.25, 1.0)
	love.graphics.rectangle("fill", 0, 0, demo_text_box.w, demo_text_box.h)

	love.graphics.setScissor(demo_text_box.x, demo_text_box.y, demo_text_box.w, demo_text_box.h)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(demo_text_box.colored_text, 0, math.floor(-demo_text_box.scroll_y), demo_text_box.w, demo_text_box.align)

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

	qp:write4("Message # ", demo_message_i, "/", #demo_messages)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("align: ", demo_text_box.align)
	qp:advanceXCoarse(a_course, a_marg)

	qp:down()

	qp:write2("Vsync: ", love.window.getVSync())
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("Font sz: ", demo_font_size)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("Advance mode: ", demo_text_box.advance_mode)
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

	qp:write2("timer_max: ", demo_text_box.timer_max)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("dist p/s: ", demo_text_box.distance_pixels_per_second)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("Mem (KB): ", math.floor(collectgarbage("count")*10)/10)
	qp:advanceXCoarse(a_course, a_marg)

	qp:down()

	qp:write2("dist x: ", math.floor(demo_text_box.distance_x*100)/100)
	qp:advanceXCoarse(a_course, a_marg)

	qp:write2("dist x next: ", math.floor(demo_text_box.distance_x_next*100)/100)
	qp:advanceXCoarse(a_course, a_marg)

	love.graphics.pop()
end


-- * / LÖVE Callbacks *


