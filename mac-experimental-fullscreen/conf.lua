--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]


--[[
SDL 2.0.2's experimental fullscreen support for Mac OS 10.7+ (fullscreen button
on the top-right of the window), enabled via LuaJIT's FFI.

This snippet *needs* to be in conf.lua because it has to be executed before the
window module is required.
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
