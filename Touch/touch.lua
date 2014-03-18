--[[
FFI wrapper for SDL 2's touch input functionality.
Example usage:

local touch = require("touch")

function love.draw()
	for i=1, touch.getTouchCount() do		
		local id, x, y, pressure = touch.getTouch(i)
		
		local sx, sy = x*love.graphics.getWidth(), y*love.graphics.getHeight()
		
		love.graphics.point(sx, sy)
		love.graphics.print(("id: %d"):format(id), sx, sy + love.graphics.getPointSize())
	end
end
]]

assert(jit, "LuaJIT is required")

local tonumber = tonumber
local ffi = require("ffi")

local touch = {}

-- SDL_touch.h
ffi.cdef[[
typedef int64_t SDL_TouchID;
typedef int64_t SDL_FingerID;

typedef struct SDL_Finger
{
    SDL_FingerID id;
    float x;
    float y;
    float pressure;
} SDL_Finger;

int SDL_GetNumTouchDevices(void);
SDL_TouchID SDL_GetTouchDevice(int index);
int SDL_GetNumTouchFingers(SDL_TouchID touchID);
SDL_Finger *SDL_GetTouchFinger(SDL_TouchID touchID, int index);
]]

-- SDL_events.h
-- TODO
ffi.cdef[[

]]

local types = {
	SDL_TouchID = ffi.typeof("SDL_TouchID"),
	SDL_FingerID = ffi.typeof("SDL_FingerID"),
	SDL_Finger = ffi.typeof("SDL_Finger"),
	SDL_FingerPtr = ffi.typeof("SDL_Finger *"),
}

-- Windows...
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C


-- Gets the number of currently active touches.
function touch.getTouchCount()
	local count = 0
	for i=1, sdl.SDL_GetNumTouchDevices() do
		count = count + sdl.SDL_GetNumTouchFingers(sdl.SDL_GetTouchDevice(i-1))
	end
	return count
end

-- Gets information about a currently active touch. Note that the index is *not stable*.
-- Returns an ID, normalized x and y coordinates, and the pressure of the touch.
-- The ID is only guaranteed to be unique for the duration of the touch press.
function touch.getTouch(index)
	assert(type(index) == "number")
	index = index - 1
	
	local deviceID = types.SDL_TouchID(0)
	
	local touchcount = 0
	local fingerindex = -1
	
	-- Find the device and finger index from the given external index.
	for i=1, sdl.SDL_GetNumTouchDevices() do
		deviceID = sdl.SDL_GetTouchDevice(i-1)
		local fingercount = sdl.SDL_GetNumTouchFingers(deviceID)
		
		if index < touchcount + fingercount then
			fingerindex = index - touchcount
			break
		end
		
		touchcount = touchcount + fingercount
	end
	
	if fingerindex < 0 then
		return error("Invalid touch index", 2)
	end
	
	local finger = sdl.SDL_GetTouchFinger(deviceID, fingerindex)
	
	if finger == nil then
		return error("Cannot get touch info", 2)
	end
	
	return tonumber(finger.id), tonumber(finger.x), tonumber(finger.y), tonumber(finger.pressure)
end

return touch
