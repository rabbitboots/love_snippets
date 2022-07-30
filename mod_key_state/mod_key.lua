--[[
	A simple modkey state handler. This is an alternative to using isDown() for
	modkeys in love.keypressed(). Merged modkey state is also provided (so for
	example, you can check 'modKey.ctrl' instead of checking both the left and
	right ctrl keys).

	Note that some key combos may be reserved and intercepted by the user's OS.
--]]


--[[
	MIT License

	Copyright (c) 2022 RBTS

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]


local modKey = {}


modKey.state = {
	["lctrl"] = false,
	["rctrl"] = false,

	["lalt"] = false,
	["ralt"] = false,

	["lshift"] = false,
	["rshift"] = false,

	["lgui"] = false,
	["rgui"] = false,
}


modKey.ctrl = false
modKey.shift = false
modKey.alt = false
modKey.gui = false


local function updateMod()
	modKey.ctrl = modKey.state["lctrl"] or modKey.state["rctrl"]
	modKey.shift = modKey.state["lshift"] or modKey.state["rshift"]
	modKey.alt = modKey.state["lalt"] or modKey.state["ralt"]
	modKey.gui = modKey.state["lgui"] or modKey.state["rgui"]
end


--- Call in love.keypressed()
function modKey.pressed(sc)
	if modKey.state[sc] ~= nil then
		modKey.state[sc] = true
		updateMod()
	end
end


--- Call in love.keyreleased()
function modKey.released(sc)
	if modKey.state[sc] ~= nil then
		modKey.state[sc] = false
		updateMod()
	end
end


--- Clears state of all keys.
function modKey.clear()
	modKey.ctrl = false
	modKey.shift = false
	modKey.alt = false
	modKey.gui = false

	local state = modKey.state
	for k in pairs(state) do
		state[k] = false
	end
end


return modKey
