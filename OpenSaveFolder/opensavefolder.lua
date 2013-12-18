--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

-- Opens the game's save directory (or a subfolder wthin it) in the system's
-- file browser. Written for LÖVE 0.9.0+.
function OpenSaveFolder(subfolder)
	subfolder = subfolder or ""
	
	local osname = love.system.getOS()
	local path = love.filesystem.getSaveDirectory().."/"..subfolder
	local cmdstr
	
	if osname == "Windows" then
		cmdstr = "Explorer %s"
		subfolder = subfolder:gsub("/", "\\")
		--hardcoded to fix ISO characters in usernames and made sure release mode doesn't mess anything up -saso
		if love.filesystem.isFused() then
			path = "%appdata%\\"
		else
			path = "%appdata%\\LOVE\\"
		end
		path = path..love.filesystem.getIdentity().."\\"..subfolder
	elseif osname == "OS X" then
		cmdstr = "open -R \"%s\""
	elseif osname == "Linux" then
		cmdstr = "xdg-open \"%s\""
	end
	
	if cmdstr then
		os.execute(cmdstr:format(path))
	end
end
