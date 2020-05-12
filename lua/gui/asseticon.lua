--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiviewport.lua")
include("/gui/wimodelview.lua")
include("/gui/wiimageicon.lua")

util.register_class("gui.AssetIcon",gui.ImageIcon)

local function get_icon_location(mdl)
	if(type(mdl) ~= "string") then mdl = mdl:GetName() end
	return "model_icons/" .. util.get_string_hash(mdl)
end

local function create_model_view(width,height,parent)
	local el = gui.create("WIModelView",parent)
	el:SetClearColor(Color.Clear)
	el:InitializeViewport(width,height)
	el:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
	return el
end

local function set_model_view_model(mdlView,model,materialOverride,iconPath)
	mdlView:SetModel(model)
	mdlView:PlayIdleAnimation()

	local ent = mdlView:GetEntity()
	if(util.is_valid(ent)) then
		local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
		if(mdlC ~= nil) then
			if(materialOverride) then mdlC:SetMaterialOverride(0,materialOverride)
			else mdlC:ClearMaterialOverride(0) end
		end
	end

	if(type(model) == "string") then model = game.load_model(model) end
	if(model == nil) then return end

	iconLocation = iconPath or get_icon_location(model)
	if(asset.is_loaded(iconLocation,asset.TYPE_MATERIAL) == false) then print(iconLocation) return end
	local mat = game.load_material(iconLocation)
	if(mat == nil) then return end
	local db = mat:GetDataBlock()
	local mv = db:FindBlock("pfm_model_view")
	if(mv == nil) then return end
	local lookAtTarget = mv:GetVector("look_at_target")
	local rotation = mv:GetVector("rotation")
	local zoom = mv:GetFloat("zoom")
	if(pos ~= nil) then mdlView:SetLookAtTarget(lookAtTarget) end
	if(rotation ~= nil) then mdlView:SetRotation(rotation.x,rotation.y) end
	if(zoom ~= nil) then mdlView:SetZoom(zoom) end
end

local function save_model_icon(mdl,mdlView,iconPath)
	local img = mdlView:GetPresentationTexture():GetImage()
	local iconLocation = iconPath or get_icon_location(mdl)
	print("Saving icon as " .. iconLocation)

	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R8G8B8A8_UINT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_DXT5
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	util.save_image(img,"materials/" .. iconLocation,texInfo)
	game.load_texture(iconLocation,bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_RELOAD))

	local mat = game.create_material(iconLocation,"wguitextured")
	mat:SetTexture("albedo_map",iconLocation)

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
function gui.AssetIcon.IconGenerator:__init(width,height)
	self.m_mdlQueue = {}

	self.m_cbTick = game.add_callback("Tick",function()
		self:ProcessIcon()
	end)

	self.m_modelView = create_model_view(width,height)
end

function gui.AssetIcon.IconGenerator:Clear()
	if(util.is_valid(self.m_modelView)) then self.m_modelView:Remove() end
	if(util.is_valid(self.m_cbTick)) then self.m_cbTick:Remove() end
end

function gui.AssetIcon.IconGenerator:ProcessIcon()
	if(self.m_saveImage ~= true or time.real_time() < self.m_tSaveIcon or util.is_valid(self.m_modelView) == false) then return end
	local data = self.m_mdlQueue[1]
	table.remove(self.m_mdlQueue,1) -- Remove from queue

	self.m_saveImage = false
	save_model_icon(data.model,self.m_modelView,data.iconPath)
	if(data.callback ~= nil) then data.callback() end

	self:GenerateNextIcon()
end

function gui.AssetIcon.IconGenerator:AddModelToQueue(mdl,callback,iconPath,materialOverride)
	table.insert(self.m_mdlQueue,{
		model = mdl,
		callback = callback,
		iconPath = iconPath,
		materialOverride = materialOverride
	})
	if(#self.m_mdlQueue == 1) then self:GenerateNextIcon() end
end

function gui.AssetIcon.IconGenerator:GenerateNextIcon()
	if(#self.m_mdlQueue == 0 or util.is_valid(self.m_modelView) == false) then return end
	self.m_saveImage = true
	self.m_tSaveIcon = time.real_time() +0.1 -- Add a small detail to ensure the model has been set up properly
	local data = self.m_mdlQueue[1]
	print("Generating next icon for model " .. data.model .. "...")
	set_model_view_model(self.m_modelView,data.model,data.materialOverride,data.iconPath)
end

------------

gui.AssetIcon.impl = util.get_class_value(gui.AssetIcon,"impl") or {}
function gui.AssetIcon:__init()
	gui.ImageIcon.__init(self)
end
function gui.AssetIcon:OnInitialize()
	gui.ImageIcon.OnInitialize(self)

	self.m_isDirectory = false
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
			local pBg = gui.create("WIRect",nil,0,0,512,512)
			pBg:SetColor(Color.Black)
			self.m_modelViewerPanel = pBg

			local p = create_model_view(pBg:GetWidth(),pBg:GetHeight(),pBg)
			p:SetSize(pBg:GetWidth(),pBg:GetHeight())
			set_model_view_model(p,self:GetPreviewModel(),self:GetMaterialOverride())

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
					local mdl = p:GetModel()

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
function gui.AssetIcon:IsDirectory() return self.m_isDirectory end
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
function gui.AssetIcon:ReloadFromCache(importAsset)
	self:SetAsset(self.m_assetPath,self.m_assetName,self:IsDirectory(),importAsset)
end
function gui.AssetIcon:SetAsset(path,assetName,isDirectory,importAsset)
	self.m_assetPath = path
	self.m_assetName = assetName

	self:SetText(assetName)
	self:SetTooltip(self:GetAsset())

	self.m_isDirectory = isDirectory

	if(self:IsDirectory()) then self:SetMaterial("gui/pfm/folder",64,64)
	else
		path = util.Path(path)
		local root = path:GetFront()
		path:PopFront()
		path = path +assetName
		if(root == "models") then
			self:SetModelAsset(path:GetString(),importAsset)
		elseif(root == "materials") then
			self:SetMaterialAsset(path:GetString(),importAsset)
		elseif(root == "particles") then
			self:SetParticleAsset(path:GetString(),importAsset)
		else
			-- Unknown asset type
			self:SetMaterial("error",128,128)
		end
	end
end
function gui.AssetIcon:ClearIcon()
	local path = util.Path(self.m_assetPath)
	path:PopFront()
	path = path +self.m_assetName
	path = path:GetString()

	local iconPath = get_icon_location(path)
	file.delete("materials/" .. iconPath .. ".wmi")
	file.delete("materials/" .. iconPath .. ".dds")
end
function gui.AssetIcon:SetMaterialSphere(matSphere)
	self.m_useMaterialSphere = matSphere
	self:Reload()
end
function gui.AssetIcon:GetPreviewModel()
	if(self:GetAssetType() ~= asset.TYPE_MODEL) then return "pfm/texture_sphere" end
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	return path:GetString() .. self:GetAssetName()
end
function gui.AssetIcon:GetIconLocation()
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	path = path +self:GetAssetName()
	return get_icon_location(path:GetString())
end
function gui.AssetIcon:GetMaterialOverride()
	if(self:GetAssetType() == asset.TYPE_MODEL) then return end
	local path = util.Path(self:GetAssetPath())
	path:PopFront()
	return path:GetString() .. self:GetAssetName()
end
function gui.AssetIcon:SetParticleAsset(pt,importAsset)
	self.m_assetType = asset.TYPE_PARTICLE_SYSTEM
	local iconPath = self:GetIconLocation()
	if(file.exists("materials/" .. iconPath .. ".wmi")) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	if(importAsset == true or asset.exists(mdl,asset.TYPE_PARTICLE_SYSTEM)) then
		-- TODO
		--[[gui.AssetIcon.impl.iconGenerator:AddModelToQueue(mdl,function()
			if(self:IsValid() == false) then return end
			self:SetMaterial(iconPath)
		end,iconPath)]]
	else
		self:SetMaterial("third_party/source_engine",100,30)
	end
end
function gui.AssetIcon:SetMaterialAsset(mat,importAsset)
	self.m_assetType = asset.TYPE_MATERIAL
	local iconPath = self:GetIconLocation()
	if(file.exists("materials/" .. iconPath .. ".wmi")) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	if(importAsset == true or asset.exists(mat,asset.TYPE_MATERIAL)) then
		local path = util.Path(mat)
		path:RemoveFileExtension()
		self:SetMaterial(path:GetString())
		if(true) then--self.m_useMaterialSphere) then
			gui.AssetIcon.impl.iconGenerator:AddModelToQueue(self:GetPreviewModel(),function()
				if(self:IsValid() == false) then return end
				self:SetMaterial(iconPath)
			end,iconPath,self:GetMaterialOverride())
		end
	else
		self:SetMaterial("third_party/source_engine",100,30)
		-- TODO: We need a way to determine which game the asset is from!
		-- self:SetMaterial("third_party/gamebryo_logo",100,41)
	end
end
function gui.AssetIcon:SetModelAsset(mdl,importAsset)
	self.m_assetType = asset.TYPE_MODEL
	local iconPath = self:GetIconLocation()
	if(file.exists("materials/" .. iconPath .. ".wmi")) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	if(importAsset == true or asset.exists(mdl,asset.TYPE_MODEL)) then
		gui.AssetIcon.impl.iconGenerator:AddModelToQueue(mdl,function()
			if(self:IsValid() == false) then return end
			self:SetMaterial(iconPath)
		end,iconPath)
	else
		self:SetMaterial("third_party/source_engine",100,30)
	end
end
gui.register("WIAssetIcon",gui.AssetIcon)
