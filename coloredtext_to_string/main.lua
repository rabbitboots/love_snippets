--[[

Some functions for converting LÖVE coloredtext sequences to strings and printing them to the
terminal, mainly for debugging purposes.

One quick way to get a string from a coloredtext sequence with the colors removed, if you have a
font object handy:

	local _, wrapped = font:getWrap(coloredtext, math.huge)
	print(wrapped[1])


Printing to terminal with the exact RGB values would be cool, though I'm not sure how to do that
(or how to restore the default text color afterwards). PRs welcome if you're knowledgeable about
this.

--]]


local function coloredTextToString(coloredtext, include_color_tables)

    local temp_t = {}

    for i, entry in ipairs(coloredtext) do
        if type(entry) == "string" then
            table.insert(temp_t, entry)

        elseif type(entry) == "table" then
            if include_color_tables then
            	local temp_str

            	-- (Alpha is optional)
            	if entry[4] then
            		temp_str = string.format("(r=%d g=%d b=%d a=%d)", entry[1]*255, entry[2]*255, entry[3]*255, entry[4]*255)
            	else
            		temp_str = string.format("(r=%d g=%d b=%d)", entry[1]*255, entry[2]*255, entry[3]*255)
            	end
                table.insert(temp_t, temp_str)
            end

        else
            error("bad type for coloredtext entry #" .. i .. " (expected table or string, got " .. type(entry) .. ")")
        end
    end

    return table.concat(temp_t)
end


local function coloredTextToTerminal(coloredtext, line_feed, include_color_tables)

	for i, entry in ipairs(coloredtext) do
		if type(entry) == "string" then
			io.write(entry)

		elseif type(entry) == "table" then
			if include_color_tables then
				local temp_str

				-- (Alpha is optional)
	           	if entry[4] then
	           		temp_str = string.format("(r=%d g=%d b=%d a=%d)", entry[1]*255, entry[2]*255, entry[3]*255, entry[4]*255)
	           	else
	           		temp_str = string.format("(r=%d g=%d b=%d)", entry[1]*255, entry[2]*255, entry[3]*255)
	           	end
				io.write(temp_str)
			end

		else
			error("bad type for coloredtext entry #" .. i .. " (expected table or string, got " .. type(entry) .. ")")
		end
	end

	if line_feed then
		io.write("\n")
	end

	-- If not finishing with a line feed, you may need to call io.flush() to make the text appear.
end


-------------------------------------------------------------------------------


-- Test the above functions.


local RED = {1, 0, 0, 1}
local GREEN = {0, 1, 0, 1}
local BLUE = {0, 0, 1, 1}

local coloredtext = {
	RED, "The ",
	GREEN, "quick ",
	BLUE, "brown ",
	GREEN, "fox ",
	RED, "jumps ",
	GREEN, "over ",
	BLUE, "the ",
	GREEN, "lazy ",
	RED, "dog."
}


local plain_text = coloredTextToString(coloredtext)

-- Print some stuff to the terminal/console.
print("")
print("coloredTextToTerminal():")
coloredTextToTerminal(coloredtext, true)
print("")
print("print(coloredTextToString()):")
print(plain_text)
print("")


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()
	end
end


local font = love.graphics.getFont()
local t_height = font:getHeight()

local ox = 0 
local oy = t_height


-- Uncomment to make the sample text dance for you.
--[[
local time = 0
function love.update(dt)

	time = time + dt

	ox = math.floor(0.5 + math.cos(time * 2) * math.sin(time / 2) * math.sin(time / 2) * 100)
	oy = math.floor(0.5 + math.sin(time * 2) * math.cos(time / 2) * math.cos(time / 2) * 100)
end
--]]


function love.draw()

	local screen_w, screen_h = love.graphics.getDimensions()
	local base_y = math.floor(0.5 + screen_h/2)

	love.graphics.printf(coloredtext, -ox, -oy + base_y - t_height/2, screen_w, "center")
	love.graphics.printf(plain_text, ox, oy + base_y - t_height/2, screen_w, "center")
end

