include("/sfm/project_converter.lua")
include("/gui/wifiledialog.lua")

pfm.register_log_category("sfm")

local pEditor
tool = tool or {}
tool.close_filmmaker = function()
	local entScene = ents.find_by_class("pfm_scene")[1]
	if(util.is_valid(entScene)) then entScene:Remove() end -- TODO: Do this properly once the actual filmmaker tool is ready
	if(tool.is_editor_open() == false) then return end
	pEditor:Remove()
	pEditor = nil
end
tool.is_filmmaker_open = function() return util.is_valid(pEditor) end
tool.open_filmmaker = function(projectFilePath)
	tool.close_filmmaker()
	pfm.log("Converting SFM project '" .. projectFilePath .. "' to PFM...",pfm.LOG_CATEGORY_SFM)
	local pfmScene = sfm.ProjectConverter.convert_project(projectFilePath)
	if(pfmScene == false) then
		pfm.log("Unable to convert SFM project '" .. projectFilePath .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	pfm.log("Initializing PFM scene...",pfm.LOG_CATEGORY_PFM)
	local entScene = ents.create("pfm_scene")
	if(util.is_valid(entScene) == false) then
		pfm.log("Unable to initialize PFM scene: Count not create 'pfm_scene' entity!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	entScene:GetComponent(ents.COMPONENT_PFM_SCENE):SetScene(pfmScene)
	entScene:Spawn()
	return entScene
	--[[include("/gui/editors/filmmaker/filmmaker.lua")
	tool.close_editor()
	pEditor = gui.create("WIFilmmaker")
	pEditor:SetAutoAlignToParent(true)

	pEditor:Open()
	return pEditor]]
end

local pOpenDialogue
console.register_command("pfm",function(pl)
	if(util.is_valid(pOpenDialogue)) then pOpenDialogue:Remove() end
	pOpenDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
		local entScene = tool.open_filmmaker(fileName)
		if(entScene == false) then return end
		local sceneC = entScene:GetComponent(ents.COMPONENT_PFM_SCENE)
		if(sceneC == nil) then return end
		sceneC:Start()
	end)
	pOpenDialogue:SetRootPath("sfm_sessions")
	pOpenDialogue:SetExtensions({"dmx"})
	pOpenDialogue:Update()
end)
