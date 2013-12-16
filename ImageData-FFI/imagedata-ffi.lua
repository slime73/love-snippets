--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

--[[
Unlike LÖVE's regular ImageData methods, this is *NOT THREAD-SAFE!*
You *need* to do your own synchronization if you want to use ImageData in
threads with this method.
]]

assert(love and love.image, "love.image is required")
assert(jit, "LuaJIT is required")

local tonumber, assert = tonumber, assert

local ffi = require("ffi")

pcall(ffi.cdef, [[
typedef struct ImageData_Pixel
{
	uint8_t r;
	uint8_t g;
	uint8_t b;
	uint8_t a;
} ImageData_Pixel;
]])

local pixelptr = ffi.typeof("ImageData_Pixel *")

local function inside(x, y, w, h)
	return x >= 0 and x < w and y >= 0 and y < h
end

local function ImageData_FFI_mapPixel(imagedata, func, ix, iy, iw, ih)
	local idw, idh = imagedata:getDimensions()
	
	ix = ix or 0
	iy = iy or 0
	iw = iw or idw
	ih = ih or idh
	
	assert(inside(ix, iy, idw, idh) and inside(ix+iw-1, iy+ih-1, idw, idh), "Invalid rectangle dimensions")
	
	local pixels = ffi.cast(pixelptr, imagedata:getPointer())
	
	for y=iy, iy+ih-1 do
		for x=ix, ix+iw-1 do
			local p = pixels[y*idw+x]
			local r, g, b, a = func(x, y, tonumber(p.r), tonumber(p.g), tonumber(p.b), tonumber(p.a))
			pixels[y*idw+x].r = r
			pixels[y*idw+x].g = g
			pixels[y*idw+x].b = b
			pixels[y*idw+x].a = a ~= nil and a or 255
		end
	end
end

local mt
if debug then
	mt = debug.getregistry()["ImageData"]
else
	mt = getmetatable(love.image.newImageData(1,1))
end

mt.__index.mapPixel = ImageData_FFI_mapPixel
