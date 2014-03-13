--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

--[[
Replaces several SoundData methods with FFI implementations. This can result
in a performance increase of up to 10x when calling the methods, especially
in simple code which had to fall back to interpreted mode specifically because
the normal SoundData methods couldn't be compiled by the JIT.
]]

--[[
NOTE: This was written specifically for LÖVE 0.9.0 and 0.9.1. Future versions
of LÖVE may change SoundData (either internally or externally) enough to cause
these replacements to break horribly.
]]

assert(love and love.sound, "love.sound is required")
assert(jit, "LuaJIT is required")

local tonumber, assert = tonumber, assert

local ffi = require("ffi")

local bytetypes = {ffi.typeof("int8_t *"), ffi.typeof("int16_t *")}
local typemaxvals = {0x7F, 0x7FFF}


local sounddata_mt
if debug then
	sounddata_mt = debug.getregistry()["SoundData"]
else
	sounddata_mt = getmetatable(love.sound.newSoundData(1))
end

local _getBitDepth = sounddata_mt.__index.getBitDepth
local _getSampleCount = sounddata_mt.__index.getSampleCount
local _getChannels = sounddata_mt.__index.getChannels

-- Holds SoundData objects as keys, and information about the objects as values.
-- Uses weak keys so the SoundData objects can still be GC'd properly.
local sd_registry = {__mode = "k"}

function sd_registry:__index(sounddata)
	local bytedepth = _getBitDepth(sounddata) / 8
	local pointer = ffi.cast(bytetypes[bytedepth], sounddata:getPointer())
	
	local p = {
		bytedepth=bytedepth,
		pointer=pointer,
		size=sounddata:getSize(),
		maxvalue = typemaxvals[bytedepth],
		samplecount = _getSampleCount(sounddata),
		channels = _getChannels(sounddata),
	}
	
	self[sounddata] = p
	return p
end

setmetatable(sd_registry, sd_registry)


-- FFI version of SoundData:getSample
local function SoundData_FFI_getSample(sounddata, i)
	local p = sd_registry[sounddata]
	assert(i >= 0 and i < p.size/p.bytedepth, "Attempt to get out-of-range sample!")
	return tonumber(p.pointer[i]) / p.maxvalue
end

-- FFI version of SoundData:setSample
local function SoundData_FFI_setSample(sounddata, i, value)
	local p = sd_registry[sounddata]
	assert(i >= 0 and i < p.size/p.bytedepth, "Attempt to set out-of-range sample!")
	p.pointer[i] = value * p.maxvalue
end

-- FFI version of SoundData:getSampleCount
local function SoundData_FFI_getSampleCount(sounddata)
	local p = sd_registry[sounddata]
	return p.samplecount	
end

-- FFI version of SoundData:getChannels
local function SoundData_FFI_getChannels(sounddata)
	local p = sd_registry[sounddata]
	return p.channels
end

-- Overwrite love's functions with the new FFI versions.
sounddata_mt.__index.getSample = SoundData_FFI_getSample
sounddata_mt.__index.setSample = SoundData_FFI_setSample
sounddata_mt.__index.getSampleCount = SoundData_FFI_getSampleCount
sounddata_mt.__index.getChannels = SoundData_FFI_getChannels

