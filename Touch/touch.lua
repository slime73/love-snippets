--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.


FFI wrapper for SDL's touch input functionality.
Example usage:

local touch = require("touch")

-- The ID of a touch press is unique only for the duration of the press. Note
-- that it is not an index.
-- Touch x and y coordinates and pressure values are normalized to [0, 1].
-- Currently (as of SDL 2.0.3) there is a bug where touch coordinates are not
-- normalized in Linux - they are in the range of [0, windowsize) instead:
-- https://bugzilla.libsdl.org/show_bug.cgi?id=2307

function touch.pressed(id, x, y, pressure)
	print(string.format("new touch press with id %d at (%.3f, %.3f)", id, x, y))
end

function touch.moved(id, x, y, pressure)
	print(string.format("touch with id %d moved to (%.3f, %.3f)", id, x, y))
end

function touch.released(id, x, y, pressure)
	print(string.format("touch with id %d released at (%.3f, %.3f)", id, x, y))
end

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

ffi.cdef[[
/* SDL_touch.h */

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


/* SDL_events.h */

/* The real enum has far more values, but we only need FingerEvent types. */
typedef enum
{
    SDL_FINGERDOWN = 0x700,
    SDL_FINGERUP,
    SDL_FINGERMOTION
} SDL_FingerEventType;

typedef struct SDL_TouchFingerEvent
{
    uint32_t type;
    uint32_t timestamp;
    SDL_TouchID touchId;
    SDL_FingerID fingerId;
    float x;
    float y;
    float dx;
    float dy;
    float pressure;
} SDL_TouchFingerEvent;

/* The real SDL_Event union has far more event structs, but we only need the
 * SDL_TouchFingerEvent. */
typedef union SDL_Event
{
    uint32_t type;
    SDL_TouchFingerEvent tfinger;
    uint8_t padding[56];
} SDL_Event;

typedef int (*SDL_EventFilter) (void *userdata, SDL_Event *event);
void SDL_AddEventWatch(SDL_EventFilter filter, void *userdata);
]]

-- Windows...
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

local eventnames = {
	[tonumber(ffi.C.SDL_FINGERDOWN)] = "pressed",
	[tonumber(ffi.C.SDL_FINGERUP)] = "released",
	[tonumber(ffi.C.SDL_FINGERMOTION)] = "moved",
}

local function EventFilterFunc(userdata, e)
	local eventname = eventnames[tonumber(e.type)]
	if eventname and type(touch[eventname]) == "function" then
		local id = tonumber(e.tfinger.fingerId)
		local x = tonumber(e.tfinger.x)
		local y = tonumber(e.tfinger.y)
		local pressure = tonumber(e.tfinger.pressure)
		touch[eventname](id, x, y, pressure)
	end
	return 1
end

sdl.SDL_AddEventWatch(EventFilterFunc, nil)


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
	
	local deviceID
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
