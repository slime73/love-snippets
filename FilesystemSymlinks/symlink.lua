--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

--[[
Functions for enabling the usage of symlinks in love.filesystem.
]]

assert(jit, "LuaJIT is required")

local ffi = require("ffi")

-- Windows...
local liblove = jit.os == "Windows" and ffi.load("love") or ffi.C

-- physfs.h
ffi.cdef[[
void PHYSFS_permitSymbolicLinks(int allow);
int PHYSFS_symbolicLinksPermitted(void);
int PHYSFS_isSymbolicLink(const char *fname);
]]

-- Toggles whether symlinks in love.filesystem are enabled.
function EnableSymbolicLinks(enable)
	assert(type(enable) == "boolean")
	liblove.PHYSFS_permitSymbolicLinks(enable and 1 or 0)
end

-- Returns true if symlinks in love.filesystem are currently enabled.
function SymbolicLinksEnabled()
	return liblove.PHYSFS_symbolicLinksPermitted() ~= 0
end

-- Returns true if a filepath in love.filesystem is really a symbolic link.
function IsSymbolicLink(filename)
	assert(type(filename) == "string")
	return liblove.PHYSFS_isSymbolicLink(filename) ~= 0
end
