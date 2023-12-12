-- Tested with LÖVE 11.4, 11.5 and 12.0-development (17362b6).

require("lib.strict")

--[[
	LÖVE version: 11.4

	If the framerate is low, love.keyboard.is[Scancode]Down() can lead to some ordering issues when used
	within love.keypressed():

	function love.keypressed(key, scancode, isrepeat)
		local ctrl_held = love.keyboard.isDown("lctrl", "rctrl")

		if ctrl_held and key == "q" then
			love.event.quit()
		end
	end

	This snippet demonstrates a workaround, by maintaining a table of modkey state that is updated in
	love.keypressed() and love.keyreleased().

	To reproduce the effect:

	* Run with console output (ie lovec.exe on Windows)
	* Press '0' to toggle a one second sleep on each frame.
	* Watch the spinning circle to determine the start and end of frame-times.
	* Between frames, press and release a modifier key, like shift.
	* Observe the console output. For the mod key, the 'isDown()' functions return false while
	'modKey.state' should return true.

	isDown() is still convenient for debugging, and probably not a huge issue for small applications that
	are unlikely to have framerate problems.
--]]


local modKey = require("mod_key")
local quickPrint = require("lib.quick_print.quick_print")

local function dummyFunc() end

local frame_n = 0
local slowdown_flag = false

local font = love.graphics.newFont(16)
love.graphics.setFont(font)

local qp = quickPrint.new()


local function printKeyState()
	local kcDown = love.keyboard.isDown
	local m_state = modKey.state

	print(frame_n, 'isDown "lctrl" / "rctrl": ', kcDown("lctrl"), kcDown("rctrl"))
	print(frame_n, 'isDown "lshift" / "rshift": ', kcDown("lshift"), kcDown("rshift"))
	print(frame_n, 'isDown "lalt" / "ralt": ', kcDown("lalt"), kcDown("ralt"))
	print(frame_n, 'isDown "lgui" / "rgui": ', kcDown("lgui"), kcDown("rgui"))
	print("...")
	print(frame_n, 'modKey.state "lctrl" / "rctrl": ', m_state["lctrl"], m_state["rctrl"])
	print(frame_n, 'modKey.state "lshift" / "rshift": ', m_state["lshift"], m_state["rshift"])
	print(frame_n, 'modKey.state "lalt" / "ralt": ', m_state["lalt"], m_state["ralt"])
	print(frame_n, 'modKey.state "lgui" / "rgui": ', m_state["lgui"], m_state["rgui"])
end


function love.keypressed(kc, sc, isrepeat)
	modKey.pressed(kc)

	print("---------------------------------------------------------------")
	print(frame_n, 'love.keypressed kc / sc / isrepeat: ', kc, sc, isrepeat)
	print("...")
	printKeyState()

	if kc == "escape" then
		love.event.quit()

	elseif kc == "0" then
		slowdown_flag = not slowdown_flag
	end
end


function love.keyreleased(kc, sc)
	modKey.released(kc)

	print("---------------------------------------------------------------")
	print(frame_n, 'love.keyreleased kc / sc: ', kc, sc)
	print("...")
	printKeyState()
end


function love.update(dt)
	frame_n = frame_n + 1
end


function love.draw()
	local time = love.timer.getTime()

	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.circle("fill", 600, 300, 32)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", 600 + math.cos(time * math.pi/2) * 32, 300 + math.sin(time * math.pi/2) * 32, 16)

	qp:setOrigin(416, 16)
	qp:reset()
	qp:print("Check console output for messages")
	qp:down()
	qp:print("(0) Toggle 1fps slow mode: ", slowdown_flag)
	qp:print("(Esc) Quit")
	qp:down()

	qp:setOrigin(16, 16)
	qp:reset()
	qp:print("Detected modkey state")
	qp:down()
	qp:print("lctrl: ", modKey.state.lctrl)
	qp:print("rctrl: ", modKey.state.rctrl)
	qp:down()
	qp:print("lshift: ", modKey.state.lshift)
	qp:print("rshift: ", modKey.state.rshift)
	qp:down()
	qp:print("lalt: ", modKey.state.lalt)
	qp:print("ralt: ", modKey.state.ralt)
	qp:down()
	qp:print("lgui: ", modKey.state.lgui)
	qp:print("rgui: ", modKey.state.rgui)
	qp:down()

	qp:down()
	qp:print("Merged modifier state")
	qp:down()
	qp:print("ctrl: ", modKey.ctrl)
	qp:down()
	qp:print("shift: ", modKey.shift)
	qp:down()
	qp:print("alt: ", modKey.alt)
	qp:down()
	qp:print("gui: ", modKey.gui)
	qp:down()

	if slowdown_flag then
		love.timer.sleep(1.0)
	end
end

