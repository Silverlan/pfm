--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiviewport.lua")
include("/gui/wimodelview.lua")
include("/gui/wiimageicon.lua")
include("/sfm/project_converter/particle_systems.lua")
include("/util/rig.lua")

util.register_class("gui.AssetIcon",gui.ImageIcon)

local function get_icon_location(mdl,assetType,attributeIdentifier)
	if(type(mdl) ~= "string") then mdl = mdl:GetName() end
	mdl = asset.get_normalized_path(mdl,assetType)

	attributeIdentifier = attributeIdentifier or ""
	if(#attributeIdentifier > 0) then mdl = mdl .. "_" .. attributeIdentifier end

	return "model_icons/" .. util.get_string_hash(mdl)
end

local function create_model_view(width,height,parent)
	local el = gui.create("WIModelView",parent)
	el:SetClearColor(Color.Clear)
	el:InitializeViewport(width,height)
	el:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
	el:SetVisible(false)
	return el
end

local function is_character_model(model)
	local mdl = model
	if(type(mdl) == "string") then mdl = game.load_model(mdl) end
	if(mdl == nil) then return false end
	-- If the model is a character, we'll zoom in on the head
	local headData = rig.determine_head_bones(mdl)
	if(headData == nil or headData.headBoneId == nil or headData.headBoneId == -1 or headData.headParentBoneId == nil or headData.headParentBoneId == -1) then return false end
	return true,headData
end

local function set_model_view_model(mdlView,model,settings,iconPath)
	if(settings.particleFileName) then
		local ptFileName = settings.particleFileName
		local ptName = settings.particleName
		game.precache_particle_system(ptFileName)
		local ptC = mdlView:SetParticleSystem(ptName)
		if(util.is_valid(ptC)) then
			-- Simulate the particle system to a point
			-- where it's likely to be in full effect.
			if(settings.dontPreSimulate ~= true) then
				local tSimulate = 1.0
				local tCur = 0.0
				local tDelta = 1.0 /60.0
				while(tCur < tSimulate) do
					ptC:Simulate(tDelta)
					tCur = tCur +tDelta
				end
			end
		end
		-- Camera has to be placed AFTER the particle simulation to ensure
		-- the bounds can be calculated properly
		mdlView:FitCameraToScene()
	else
		mdlView:SetModel(model)
		mdlView:SetAlwaysRender(true)

		local playIdleAnim = true
		local ent = mdlView:GetEntity()
		if(util.is_valid(ent)) then
			local eyeC = ent:GetComponent(ents.COMPONENT_EYE)
			if(eyeC ~= nil) then eyeC:SetBlinkingEnabled(false) end
			local isCharModel,headData = is_character_model(model)
			if(isCharModel) then
				local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
				if(animC ~= nil) then
					-- If the model is a character, we'll zoom in on the head
					local pose = animC:GetGlobalBonePose(headData.headBoneId)
					local poseParent = animC:GetGlobalBonePose(headData.headParentBoneId)
					if(pose ~= nil and poseParent ~= nil) then
						playIdleAnim = false
						pose:SetOrigin(pose:GetOrigin() +(poseParent:GetOrigin() -pose:GetOrigin()) *0.7)
						local min = pose *(headData.headBounds[1] *1.2)
						local max = pose *(headData.headBounds[2] *1.2)
						mdlView:FitCameraToScene(min,max)

						local vc = mdlView:GetViewerCamera()
						if(util.is_valid(vc)) then
							vc:SetRotation(0.0,0.0)
							vc:Rotate(-25,10)
							vc:FitZoomToExtents(min,max)
						end
					end
				end
			end
			if(playIdleAnim) then
				mdlView:PlayIdleAnimation()
			end
			local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
			if(mdlC ~= nil) then
				if(settings.materialOverride) then mdlC:SetMaterialOverride(0,settings.materialOverride)
				else mdlC:ClearMaterialOverride(0) end
			end

			if(settings.skin ~= nil) then ent:SetSkin(settings.skin) end
			if(settings.bodyGroups ~= nil) then
				local bgs = {}
				for g,v in pairs(settings.bodyGroups) do
					ent:SetBodyGroup(g,v)
					table.insert(bgs,{g,v})
				end
				if(#bgs == 1) then
					-- If we're focusing on one bodygroup, we can zoom in on it
					mdlView:SetBodyPart(bgs[1][1],bgs[1][2])
				end
			end
		end
	end

	local lookAtTarget
	local rotation
	local zoom

	iconLocation = iconPath or get_icon_location(model,asset.TYPE_MODEL)
	if(asset.is_loaded(iconLocation,asset.TYPE_MATERIAL)) then
		local mat = game.load_material(iconLocation)
		if(mat ~= nil) then
			local db = mat:GetDataBlock()
			local mv = db:FindBlock("pfm_model_view")
			if(mv ~= nil) then
				lookAtTarget = mv:GetVector("look_at_target")
				rotation = mv:GetVector("rotation")
				zoom = mv:GetFloat("zoom")
			end
		end
	end

	if(settings.modelView ~= nil) then
		lookAtTarget = lookAtTarget or settings.modelView.lookAtTarget
		rotation = rotation or settings.modelView.rotation
		zoom = zoom or settings.modelView.zoom
	end

	if(lookAtTarget ~= nil) then mdlView:SetLookAtTarget(lookAtTarget) end
	if(rotation ~= nil) then mdlView:SetRotation(rotation.x,rotation.y) end
	if(zoom ~= nil) then mdlView:SetZoom(zoom) end
end

local function save_model_icon(mdl,mdlView,iconPath)
	local img = mdlView:GetPresentationTexture():GetImage()
	local iconLocation = iconPath or get_icon_location(mdl,asset.TYPE_MODEL)
	print("Saving icon as " .. iconLocation)

	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R8G8B8A8_UINT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_DXT5
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	util.save_image(img,"materials/" .. iconLocation,texInfo)
	asset.reload(iconLocation,asset.TYPE_TEXTURE)

	local mat = game.create_material(iconLocation,"wguitextured")
	mat:SetTexture("albedo_map",iconLocation)

	local isCharModel = is_character_model(mdl)
	if(isCharModel) then
		local db = mat:GetDataBlock()
		local mv = db:AddBlock("pfm_model_view")
		mv:SetValue("bool","character_model","1")
		mv:SetValue("float","aspect_ratio",tostring(img:GetWidth() /img:GetHeight()))
	end

	mdlView:SetModel() -- Clear model

	local cam = mdlView:GetCamera()
	if(util.is_valid(cam)) then
		local ent = cam:GetEntity()
		local lookAtTarget = mdlView:GetLookAtTarget()
		local xRot,yRot = mdlView:GetRotation()
		local zoom = mdlView:GetZoom()
		local db = mat:GetDataBlock()
		local mv = db:AddBlock("pfm_model_view")
		mv:SetValue("vector","look_at_target",tostring(lookAtTarget))
		mv:SetValue("vector","rotation",tostring(xRot) .. " " .. tostring(yRot) .. " 0")
		mv:SetValue("float","zoom",tostring(zoom))
	end

	mat:Save(iconLocation)
end

util.register_class("gui.AssetIcon.IconGenerator")
function gui.AssetIcon.IconGenerator:__init(width,height,widthChar,heightChar)
	self.m_mdlQueue = {}

	self.m_cbTick = game.add_callback("Tick",function()
		self:ProcessIcon()
	end)

	self.m_modelView = create_model_view(width,height)

	widthChar = widthChar or width
	heightChar = heightChar or height
	-- Icons for character models are drawn at a higher resolution (usually)
	self.m_modelViewCharacter = create_model_view(widthChar,heightChar)
end

function gui.AssetIcon.IconGenerator:Clear()
	util.remove({self.m_modelView,self.m_modelViewCharacter,self.m_cbTick})
end

function gui.AssetIcon.IconGenerator:ProcessIcon()
	if(self.m_saveImage ~= true or util.is_valid(self.m_modelView) == false or util.is_valid(self.m_modelViewCharacter) == false) then return end
	local data = self.m_mdlQueue[1]
	local mdlView = is_character_model(data.model) and self.m_modelViewCharacter or self.m_modelView
	local dtFrameIndex = mdlView:GetFrameIndex() -self.m_tStartFrameIndex
	-- Make sure the model has been set up properly by waiting a few frames
	if(dtFrameIndex < 4) then return end
	table.remove(self.m_mdlQueue,1) -- Remove from queue

	self.m_saveImage = false
	save_model_icon(data.model,mdlView,data.iconPath)
	mdlView:SetVisible(false)
	if(data.callback ~= nil) then data.callback() end

	data = nil
	console.run("asset_clear_unused")

	self:GenerateNextIcon()
end

local texSpherePath = asset.get_normalized_path("pfm/texture_sphere",asset.TYPE_MODEL)
function gui.AssetIcon.IconGenerator:AddModelToQueue(mdl,callback,iconPath,settings)
	settings = settings or {}
	mdl = asset.get_normalized_path(mdl,asset.TYPE_MODEL)
	if(mdl == texSpherePath) then
		-- Bit of a hack; pfm/texture_sphere is used for material icons, we'll use some default settings
		-- for the camera to make it look nice.
		settings.modelView = {
			lookAtTarget = Vector(),
			rotation = Vector(-0.6284,0.4189,0),
			zoom = 120
		}
	end
	table.insert(self.m_mdlQueue,{
		model = mdl,
		callback = callback,
		iconPath = iconPath,
		settings = settings
	})
	if(#self.m_mdlQueue == 1) then self:GenerateNextIcon() end
end

function gui.AssetIcon.IconGenerator:GenerateNextIcon()
	if(#self.m_mdlQueue == 0 or util.is_valid(self.m_modelView) == false or util.is_valid(self.m_modelViewCharacter) == false) then return end
	self.m_saveImage = true
	local data = self.m_mdlQueue[1]
	print("Generating next icon for model " .. data.model .. "...")
	local mdlView = is_character_model(data.model) and self.m_modelViewCharacter or self.m_modelView
	self.m_tStartFrameIndex = mdlView:GetFrameIndex()
	mdlView:SetVisible(true)
	set_model_view_model(mdlView,data.model,data.settings,data.iconPath)
end

------------

gui.AssetIcon.impl = util.get_class_value(gui.AssetIcon,"impl") or {}
gui.AssetIcon.ASSET_TYPE_CUSTOM = -1
gui.AssetIcon.get_icon_location = get_icon_location
function gui.AssetIcon:__init()
	gui.ImageIcon.__init(self)
end
function gui.AssetIcon:GetTypeIdentifier() return "invalid" end
function gui.AssetIcon:OnInitialize()
	gui.ImageIcon.OnInitialize(self)

	gui.AssetIcon.impl.count = gui.AssetIcon.impl.count and (gui.AssetIcon.impl.count +1) or 1
end
function gui.AssetIcon:OnRemove()
	if(util.is_valid(self.m_modelViewerPanel)) then self.m_modelViewerPanel:RemoveSafely() end
	gui.AssetIcon.impl.count = gui.AssetIcon.impl.count and (gui.AssetIcon.impl.count -1) or 0
	if(gui.AssetIcon.impl.count == 0 and gui.AssetIcon.impl.iconGenerator ~= nil) then
		gui.AssetIcon.impl.iconGenerator:Clear()
		gui.AssetIcon.impl.iconGenerator = nil
	end
end
function gui.AssetIcon:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS and self:IsDirectory() == false) then
		local isAltDown = input.get_key_state(input.KEY_LEFT_ALT) ~= input.STATE_RELEASE or
			input.get_key_state(input.KEY_RIGHT_ALT) ~= input.STATE_RELEASE
		if(isAltDown) then
			local pBg = gui.create("WIRect")
			pBg:SetSize(512,512)
			pBg:SetColor(Color.Black)
			self.m_modelViewerPanel = pBg

			local p = create_model_view(pBg:GetWidth(),pBg:GetHeight(),pBg)
			p:SetSize(pBg:GetWidth(),pBg:GetHeight())
			p:SetVisible(true)
			local settings = {
				materialOverride = self:GetMaterialOverride(),
				dontPreSimulate = true
			}
			if(self:GetTypeIdentifier() == "particle") then
				local ptFileName,ptName = self:GetParticleSystemFileName()
				settings.particleFileName = ptFileName
				settings.particleName = ptName
			end

			set_model_view_model(p,self:GetPreviewModel(),settings,self:GetIconLocation())

			local pos = input.get_cursor_pos()
			pos.x = math.max(pos.x -pBg:GetWidth() /2,0)
			pos.y = math.max(pos.y -pBg:GetHeight() /2,0)
			pBg:SetPos(pos)

			p:EnableThinking()
			p:SetRotationModeEnabled(true)
			local cb
			cb = p:AddCallback("Think",function()
				if(self:IsValid() == false) then
					cb:Remove()
					return
				end
				if(input.get_mouse_button_state(input.MOUSE_BUTTON_RIGHT) == input.STATE_RELEASE) then
					local mdl = p:GetModel() or p:GetParticleSystemName()
					if(mdl ~= nil) then
						save_model_icon(mdl,p,self:GetIconLocation())
						self:ReloadFromCache()
					end

					pBg:RemoveSafely()
					cb:Remove()
				end
			end)
			return util.EVENT_REPLY_HANDLED
		end
		local pContext = gui.open_context_menu()
		if(util.is_valid(pContext)) then
			pContext:SetPos(input.get_cursor_pos())
			self:CallCallbacks("PopulateContextMenu",pContext)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.AssetIcon:IsDirectory() return false end
function gui.AssetIcon:IsExportable() return false end
function gui.AssetIcon:Export() return false,"Export for this asset type not supported!" end
function gui.AssetIcon:GetAssetName() return self.m_assetName end
function gui.AssetIcon:GetAssetPath() return self.m_assetPath end
function gui.AssetIcon:GetAsset() return self.m_assetPath .. self.m_assetName end
function gui.AssetIcon:GetAssetType() return self.m_assetType end
function gui.AssetIcon:GetRelativeAsset()
	local path = util.Path(self:GetAsset())
	path:PopFront()
	return path:GetString()
end
function gui.AssetIcon:Reload(importAsset)
	self:ClearIcon()
	self:ReloadFromCache(importAsset)
end
function gui.AssetIcon:IsNativeAsset() return self.m_isNativeAsset or false end
function gui.AssetIcon:SetNativeAsset(nativeAsset) self.m_isNativeAsset = nativeAsset end
function gui.AssetIcon:ReloadFromCache(importAsset)
	self:SetAsset(self.m_assetPath,self.m_assetName,importAsset,self.m_attrData)
end
function gui.AssetIcon:SetAsset(path,assetName,importAsset,attrData)
	attrData = attrData or {}
	self.m_assetPath = path
	self.m_assetName = assetName
	self.m_attrData = attrData

	self:SetText(assetName)
	self:SetTooltip(self:GetAsset())

	path = util.Path(path)
	local root = path:GetFront()
	path:PopFront()
	path = path +assetName
	self:ApplyAsset(path:GetString(),importAsset)
end
function gui.AssetIcon:ApplyAsset(path,importAsset) self:SetMaterial("error",128,128) end
function gui.AssetIcon:ClearIcon()
	local path = util.Path(self.m_assetPath)
	path:PopFront()
	path = path +self.m_assetName
	path = path:GetString()

	local iconLocation = self:GetIconLocation()
	asset.delete(iconLocation,asset.TYPE_MATERIAL)
	asset.delete(iconLocation,asset.TYPE_TEXTURE)
end
function gui.AssetIcon:SetMaterialSphere(matSphere)
	self.m_useMaterialSphere = matSphere
	self:Reload()
end
function gui.AssetIcon:GetPreviewModel()
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	return path:GetString() .. self:GetAssetName()
end
function gui.AssetIcon:GetAssetAttributeIdentifier() return "" end
function gui.AssetIcon:GetIconLocation()
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	path = path +self:GetAssetName()
	return get_icon_location(path:GetString(),self:GetAssetType(),self:GetAssetAttributeIdentifier())
end
function gui.AssetIcon:GetMaterialOverride()
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	return path:GetString() .. self:GetAssetName()
end
gui.register("WIAssetIcon",gui.AssetIcon)

-----------------

util.register_class("gui.DirectoryAssetIcon",gui.AssetIcon)
function gui.DirectoryAssetIcon:__init()
	gui.AssetIcon.__init(self)
end
function gui.DirectoryAssetIcon:ApplyAsset(path,importAsset)
	self:SetMaterial("gui/pfm/folder",64,64)
end
function gui.DirectoryAssetIcon:GetTypeIdentifier() return "directory" end
function gui.DirectoryAssetIcon:IsDirectory() return true end
gui.register("WIDirectoryAssetIcon",gui.DirectoryAssetIcon)

-----------------

util.register_class("gui.ModelAssetIcon",gui.AssetIcon)
function gui.ModelAssetIcon:__init()
	gui.AssetIcon.__init(self)
	self.m_skin = 0
	self.m_bodyGroups = {}
end
function gui.ModelAssetIcon:IsExportable() return true end
function gui.ModelAssetIcon:IsExternalAsset() return false end
function gui.ModelAssetIcon:Export()
	local path = util.Path(self:GetAsset())
	path:PopFront()
	local mdl = game.load_model(path:GetString())
	if(mdl == nil) then return false,"Unable to load model!" end
	local exportInfo = game.Model.ExportInfo()
	exportInfo.verbose = false
	exportInfo.generateAo = false -- true
	exportInfo.exportAnimations = true
	exportInfo.exportSkinnedMeshData = true
	exportInfo.exportImages = true
	exportInfo.exportMorphTargets = true
	exportInfo.saveAsBinary = false
	exportInfo.embedAnimations = true
	return mdl:Export(exportInfo)
end
function gui.ModelAssetIcon:ApplyAsset(path,importAsset)
	self:SetModelAsset(path,importAsset)
end
function gui.ModelAssetIcon:GetTypeIdentifier() return "model" end
function gui.ModelAssetIcon:GetMaterialOverride() end
function gui.ModelAssetIcon:GetAssetAttributeIdentifier()
	local identifier = ""
	if(self.m_skin ~= 0) then identifier = "s" .. self.m_skin end
	if(#self.m_bodyGroups > 0) then
		for _,bg in ipairs(self.m_bodyGroups) do
			if(#identifier > 0) then identifier = identifier .. "_" end
			identifier = identifier .. "b" .. bg[1] .. "x" .. bg[2]
		end
	end
	return identifier
end
function gui.ModelAssetIcon:SetModelAsset(mdl,importAsset)
	local skin = self.m_attrData.skin or 0
	local bodyGroups = self.m_attrData.bodyGroups or {}

	self.m_assetType = asset.TYPE_MODEL
	self.m_skin = skin

	self.m_bodyGroups = {}
	for g,v in pairs(bodyGroups) do table.insert(self.m_bodyGroups,{g,v}) end
	table.sort(self.m_bodyGroups,function(a,b) return a[1] < b[1] end)

	self:SetNativeAsset(asset.exists(mdl,asset.TYPE_MODEL))
	local iconPath = self:GetIconLocation()
	if(asset.exists(iconPath,asset.TYPE_MATERIAL)) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		local size = console.get_convar_int("pfm_asset_icon_size")
		local sizeChar = string.split(console.get_convar_string("pfm_asset_icon_size_character"),"x")
		local wChar = sizeChar[1] and tonumber(sizeChar[1]) or size
		local hChar = sizeChar[2] and tonumber(sizeChar[2]) or size
		print("Creating new icon generator (Resolution: " .. size .. "x" .. size .. "; Char resolution: " .. wChar .. "x" .. hChar .. ")...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(
			size,size,
			wChar,hChar
		)
	end
	if(importAsset == true or self:IsNativeAsset()) then
		local settings = {}
		settings.skin = skin
		settings.bodyGroups = bodyGroups
		gui.AssetIcon.impl.iconGenerator:AddModelToQueue(mdl,function()
			if(self:IsValid() == false) then return end
			self:SetMaterial(iconPath)
			self:CallCallbacks("OnIconReloaded")
		end,iconPath,settings)
	else
		self:SetMaterial("third_party/source_engine",100,30)
	end
end
gui.register("WIModelAssetIcon",gui.ModelAssetIcon)

-----------------

util.register_class("gui.MaterialAssetIcon",gui.AssetIcon)
function gui.MaterialAssetIcon:__init()
	gui.AssetIcon.__init(self)
end
function gui.MaterialAssetIcon:IsExportable() return true end
function gui.MaterialAssetIcon:Export()
	local path = util.Path(self:GetAsset())
	path:PopFront()
	return asset.export_material(path:GetString(),game.Model.ExportInfo.IMAGE_FORMAT_PNG,false)
end
function gui.MaterialAssetIcon:ApplyAsset(path,importAsset)
	self:SetMaterialAsset(path,importAsset)
end
function gui.MaterialAssetIcon:GetTypeIdentifier() return "material" end
function gui.MaterialAssetIcon:GetPreviewModel() return "pfm/texture_sphere" end
function gui.MaterialAssetIcon:SetMaterialAsset(mat,importAsset)
	self.m_assetType = asset.TYPE_MATERIAL
	self:SetNativeAsset(asset.exists(mat,asset.TYPE_MATERIAL))
	local iconPath = self:GetIconLocation()
	if(asset.exists(iconPath,asset.TYPE_MATERIAL)) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	if(importAsset == true or self:IsNativeAsset()) then
		local path = util.Path(mat)
		path:RemoveFileExtension()
		self:SetMaterial(path:GetString())
		if(true) then--self.m_useMaterialSphere) then
			gui.AssetIcon.impl.iconGenerator:AddModelToQueue(self:GetPreviewModel(),function()
				if(self:IsValid() == false) then return end
				self:SetMaterial(iconPath)
			end,iconPath,{
				materialOverride = self:GetMaterialOverride()
			})
		end
	else
		self:SetMaterial("third_party/source_engine",100,30)
		-- TODO: We need a way to determine which game the asset is from!
		-- self:SetMaterial("third_party/gamebryo_logo",100,41)
	end
end
gui.register("WIMaterialAssetIcon",gui.MaterialAssetIcon)

-----------------

util.register_class("gui.ParticleAssetIcon",gui.AssetIcon)
function gui.ParticleAssetIcon:__init()
	gui.AssetIcon.__init(self)
end
function gui.ParticleAssetIcon:OnInitialize()
	gui.AssetIcon.OnInitialize(self)
	self:AddCallback("OnDoubleClick",function(el)
		if(util.is_valid(self) == false) then return end
		local ptFileName,ptName = el:GetParticleSystemFileName()
		if(ptName ~= nil) then
			tool.get_filmmaker():OpenParticleEditor(ptFileName,ptName)
			return
		end
		local ptPath = util.Path(el:GetAsset())
		ptPath:PopFront()
		if(asset.exists(ptPath:GetString(),asset.TYPE_PARTICLE_SYSTEM) == false) then
			-- Attempt to import the particle system from a Source Engine PCF file
			-- TODO: This should be done automatically by 'precache_particle_system'!
			local sePath = util.Path(ptPath)
			sePath:RemoveFileExtension()
			sePath = sePath +".pcf"
			sfm.convert_particle_systems("particles/" .. sePath:GetString())
		end
		game.precache_particle_system(ptPath:GetString())

		self:CallCallbacks("OnParticleSelected",ptPath:GetString())
	end)
end
function gui.ParticleAssetIcon:ApplyAsset(path,importAsset)
	self:SetParticleAsset(path,importAsset)
end
function gui.ParticleAssetIcon:GetTypeIdentifier() return "particle" end
function gui.ParticleAssetIcon:SetParticleAsset(pt,importAsset)
	self.m_assetType = asset.TYPE_PARTICLE_SYSTEM

	local ptFileName,ptName = self:GetParticleSystemFileName()
	if(ptFileName ~= nil) then self:SetNativeAsset(asset.exists(ptFileName,asset.TYPE_PARTICLE_SYSTEM)) end

	local iconPath = self:GetIconLocation()
	if(asset.exists(iconPath,asset.TYPE_MATERIAL)) then
		self:SetMaterial(iconPath)
		return
	end

	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end

	if(ptFileName ~= nil and (importAsset == true or self:IsNativeAsset())) then
		gui.AssetIcon.impl.iconGenerator:AddModelToQueue(pt,function()
			if(self:IsValid() == false) then return end
			self:SetMaterial(iconPath)
		end,iconPath,{
			particleFileName = ptFileName,
			particleName = ptName
		})
	else
		self:SetMaterial("third_party/source_engine",100,30)
	end
end
function gui.ParticleAssetIcon:GetParticleSystemFileName()
	local path = util.Path(self:GetAssetPath())

	-- Check if we're in a particle system file
	local ptPath = path:GetString()
	ptPath = ptPath:sub(0,#ptPath -1)
	local ext = file.get_file_extension(ptPath)
	if(ext == nil or asset.is_supported_extension(ext,asset.TYPE_PARTICLE_SYSTEM) == false) then return self:GetAssetName() end

	path:PopFront()
	path = util.Path(path:GetString() .. self:GetAssetName())

	local ptName = path:GetBack()
	path:PopBack()
	local ptFileName = path:GetString()
	ptFileName = ptFileName:sub(0,#ptFileName -1)
	return ptFileName,ptName
end
gui.register("WIParticleAssetIcon",gui.ParticleAssetIcon)
