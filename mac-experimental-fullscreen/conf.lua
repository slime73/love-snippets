--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]


--[[
LÖVE 0.9.0 for OS X uses a development version of SDL in between 2.0.1 and 2.0.2.
It includes experimental support for Mac OS 10.7's Spaces-aware fullscreen
(including the button on the top-right of the window.) This snippet enables the
experimental fullscreen support via LuaJIT's FFI.

LÖVE 0.9.1 for OS X uses SDL 2.0.2, which has a much more robust version of this
enabled by default, so this snippet only works in 0.9.0.

This *needs* to be in conf.lua because it has to be executed before the window
module is loaded.
]]


-- Check for 0.9.0+, LuaJIT, and OS X.
if (love._version_minor or 7) >= 9 and jit and jit.os == "OSX" then
	local ffi = require("ffi")
	
	ffi.cdef "int SDL_SetHint(const char *name, const char *value);"
	ffi.C.SDL_SetHint("SDL_VIDEO_FULLSCREEN_SPACES", "1")
end

--[[
-- love.conf goes here:
function love.conf(t)
	-- etc.	
end
]]
