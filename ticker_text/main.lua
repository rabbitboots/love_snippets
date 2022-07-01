
local utf8 = require("utf8")

local function dummyFunc() end

local function newTickerText(font)

	local self = {}

	self.chunks = {}

	self.font = font or love.graphics.getFont()

	self.scroll_x = 0
	self.x_min = -math.huge
	self.x_max = math.huge
	self.phase = 0.0
	self.amp = 1.0
	self.rate = 44.0

	self.pos_scale_x = 1/16

	self.loop = false

	self.call_chunkOffset = dummyFunc

	return self
end


local function tickerDraw(self, x, y)

	local font = love.graphics.getFont()
	local pos_x = 0
	local last_glyph = false

	for i, chunk in ipairs(self.chunks) do
		local xx, yy = self.call_chunkOffset(self, i, pos_x)

		love.graphics.print(chunk, x + xx, y + yy)

		pos_x = pos_x + font:getWidth(chunk)
		if last_glyph then
			pos_x = pos_x + font:getKerning(last_glyph, string.sub(chunk, utf8.offset(chunk, -1)))
		end
		last_glyph = string.sub(chunk, 1, utf8.offset(chunk, 2) - 1)
	end
end


local function chunkSine(self, chunk_n, pos_x)
	return pos_x, math.floor(0.5 + math.sin(((self.phase + pos_x) * self.pos_scale_x) * self.amp) * 10)
end


local ticker = newTickerText()
ticker.call_chunkOffset = chunkSine


  local txt = "The quick brown fox jumps over the lazy dog."
--local txt = "__________________________________________________________________"
--local txt = ".................................................................."
for pos, code in utf8.codes(txt) do
	table.insert(ticker.chunks, utf8.char(code))
end


function love.keypressed(kc, sc)
	if sc == "escape" then
		love.event.quit()
	end
end


function love.update(dt)
	ticker.phase = (ticker.phase + dt * ticker.rate)
end


function love.draw()
	tickerDraw(ticker, 300, 300)
end


