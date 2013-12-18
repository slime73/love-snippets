--[[
FFI wrapper for SDL 2.0's simple message box functionality.
Assumes the SDL library's functions are already accessible by the program
(e.g. SDL is dynamically linked to it.) This is the case in LÖVE 0.9.0+.
]]

assert(jit, "LuaJIT is required")

local ffi = require("ffi")

-- SDL_video.h and SDL_messagebox.h (SDL 2.0.1):
ffi.cdef[[
typedef struct SDL_Window SDL_Window;
SDL_Window *SDL_GL_GetCurrentWindow(void);

typedef enum
{
    SDL_MESSAGEBOX_ERROR        = 0x00000010,
    SDL_MESSAGEBOX_WARNING      = 0x00000020,
    SDL_MESSAGEBOX_INFORMATION  = 0x00000040
} SDL_MessageBoxFlags;

int SDL_ShowSimpleMessageBox(uint32_t flags, const char *title, const char *message, SDL_Window *window);
]]

-- Windows...
local sdl = jit.os == "Windows" and ffi.load("SDL2") or ffi.C

local typeconstants = {
	info = ffi.C.SDL_MESSAGEBOX_INFORMATION,
	warning = ffi.C.SDL_MESSAGEBOX_WARNING,
	error = ffi.C.SDL_MESSAGEBOX_ERROR,
}

--[[
Shows a simple message box with a title, some text, and a close button.
NOTE: this function does not return until the user closes the messagebox!

Arguments:
	mtype (string): The type of message box: "info", "warning", or "error".
	title (string): The title of the message box.
	message (string): The text in the main message area of the message box.
	standalone (boolean): Whether the message box is a standalone window or attached to the game's main window.
	                      NOTE: using a standalone message box while in fullscreen can cause a hard lock in Mac OS X!
]]
function ShowSimpleMessageBox(mtype, title, message, standalone)
	local flags = typeconstants[mtype]
	
	assert(flags, "Invalid message box type")
	assert(type(title) == "string", "Invalid message box title type (expecting string)")
	assert(type(message) == "string", "Invalid message box message type (expecting string)")
	
	local window = nil
	if not standalone then
		window = sdl.SDL_GL_GetCurrentWindow()
	end
	
	local result = sdl.SDL_ShowSimpleMessageBox(flags, title, message, window)
	return result >= 0
end
