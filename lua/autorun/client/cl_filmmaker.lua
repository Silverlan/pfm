local pEditor
tool = tool or {}
tool.close_filmmaker = function()
	if(tool.is_editor_open() == false) then return end
	pEditor:Remove()
	pEditor = nil
end
tool.is_filmmaker_open = function() return util.is_valid(pEditor) end
tool.open_filmmaker = function()
	include("/gui/editors/filmmaker/filmmaker.lua")
	tool.close_editor()
	pEditor = gui.create("WIFilmmaker")
	pEditor:SetAutoAlignToParent(true)

	pEditor:Open()
	return pEditor
end

console.register_command("tool_filmmaker",function(pl)
	tool.open_filmmaker()
end)

console.register_command("fm",function(pl)
	tool.open_filmmaker()
end)
