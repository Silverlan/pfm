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

util.register_class("gui.AssetIcon.IconGenerator")
function gui.AssetIcon.IconGenerator:__init(width,height)
	self.m_mdlQueue = {}

	self.m_cbTick = game.add_callback("Tick",function()
		self:ProcessIcon()
	end)

	local el = gui.create("WIModelView")
	self.m_modelView = el
	el:InitializeViewport(width,height)
	-- el:SetSize(512,512)
	local entLight = el:GetLightSource()
	if(util.is_valid(entLight)) then
		local lightC = entLight:GetComponent(ents.COMPONENT_LIGHT)
		if(lightC ~= nil) then
			lightC:SetLightIntensity(20)
		end
		local radiusC = entLight:GetComponent(ents.COMPONENT_RADIUS)
		if(radiusC ~= nil) then
			radiusC:SetRadius(2000)
		end
		local colorC = entLight:GetComponent(ents.COMPONENT_COLOR)
		if(colorC ~= nil) then
			colorC:SetColor(Color.White)
		end
		--el:UpdateLightPose(Vector(0,1,0))
	end
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

	local iconLocation = get_icon_location(data.model)
	print("Saving icon as " .. iconLocation)
	local img = self.m_modelView:GetPresentationTexture():GetImage()

	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R8G8B8A8_UINT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_DXT1
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	util.save_image(img,"materials/" .. iconLocation,texInfo)
	game.load_texture(iconLocation,bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_RELOAD))

	local mat = game.create_material(iconLocation,"wguitextured")
	mat:SetTexture("albedo_map",iconLocation)
	mat:Save(iconLocation)
	if(data.callback ~= nil) then data.callback() end

	self:GenerateNextIcon()
end

function gui.AssetIcon.IconGenerator:AddModelToQueue(mdl,callback)
	table.insert(self.m_mdlQueue,{
		model = mdl,
		callback = callback
	})
	if(#self.m_mdlQueue == 1) then self:GenerateNextIcon() end
end

function gui.AssetIcon.IconGenerator:GenerateNextIcon()
	if(#self.m_mdlQueue == 0 or util.is_valid(self.m_modelView) == false) then return end
	self.m_saveImage = true
	self.m_tSaveIcon = time.real_time() +0.1 -- Add a small detail to ensure the model has been set up properly
	local data = self.m_mdlQueue[1]
	print("Generating next icon for model " .. data.model .. "...")
	self.m_modelView:SetModel(data.model)
	local mdl = self.m_modelView:GetModel()
	if(mdl ~= nil) then
		local anim = mdl:SelectWeightedAnimation(game.Model.Animation.ACT_IDLE)
		if(anim == -1) then anim = mdl:LookupAnimation("idle") end
		if(anim == -1) then
			local r = string.find_similar_elements("idle",mdl:GetAnimationNames(),1)
			anim = r[1] or -1
		end
		if(anim == -1) then anim = mdl:LookupAnimation("ragdoll") end
		if(anim ~= -1) then
			self.m_modelView:PlayAnimation(anim)
		end
	end
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
	gui.AssetIcon.impl.count = gui.AssetIcon.impl.count and (gui.AssetIcon.impl.count -1) or 0
	if(gui.AssetIcon.impl.count == 0 and gui.AssetIcon.impl.iconGenerator ~= nil) then
		gui.AssetIcon.impl.iconGenerator:Clear()
		gui.AssetIcon.impl.iconGenerator = nil
	end
end
function gui.AssetIcon:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS and self:IsDirectory() == false) then
		local pContext = gui.open_context_menu()
		if(util.is_valid(pContext)) then
			pContext:SetPos(input.get_cursor_pos())

			pContext:AddItem(locale.get_text("pfm_asset_icon_reload"),function()
				self:ClearIcon()
				self:SetAsset(self.m_assetPath,self.m_assetName,self:IsDirectory())
			end)
			self:CallCallbacks("PopulateContextMenu",pContext)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.AssetIcon:IsDirectory() return self.m_isDirectory end
function gui.AssetIcon:GetAsset() return self.m_assetPath .. self.m_assetName end
function gui.AssetIcon:SetAsset(path,assetName,isDirectory)
	self.m_assetPath = path
	self.m_assetName = assetName

	self:SetText(assetName)

	self.m_isDirectory = isDirectory

	if(self:IsDirectory()) then self:SetMaterial("gui/pfm/folder",64,64)
	else
		path = util.Path(path)
		if(path:GetFront() == "models") then
			path:PopFront()
			path = path +assetName
			self:SetModel(path:GetString())
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
function gui.AssetIcon:SetModel(mdl)
	local iconPath = get_icon_location(mdl)
	if(file.exists("materials/" .. iconPath .. ".wmi")) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	gui.AssetIcon.impl.iconGenerator:AddModelToQueue(mdl,function()
		if(self:IsValid() == false) then return end
		self:SetMaterial(iconPath)
	end)
end
gui.register("WIAssetIcon",gui.AssetIcon)
