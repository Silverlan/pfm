include("/pfm/pfm.lua")

if tool.is_filmmaker_open() == false then
	pfm.launch(nil)
end

return true
