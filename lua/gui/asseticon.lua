--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiviewport.lua")
include("/gui/wimodelview.lua")

util.register_class("gui.AssetIcon",gui.Base)

local function get_icon_location(mdl)
	if(type(mdl) ~= "string") then mdl = mdl:GetName() end
	return "model_icons/" .. string.format("%18.0f",util.get_string_hash(mdl))
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
	local img = self.m_modelView:GetRenderTarget():GetTexture():GetImage()

	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R8G8B8A8_UINT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_DXT1
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	util.save_image(img,"materials/" .. iconLocation,texInfo)

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
	print("Generating next icon...")
	local data = self.m_mdlQueue[1]
	self.m_modelView:SetModel(data.model)
	self.m_saveImage = true
	self.m_tSaveIcon = time.real_time() +0.1 -- Add a small detail to ensure the model has been set up properly
end

------------

gui.AssetIcon.impl = {}
function gui.AssetIcon:__init()
	gui.Base.__init(self)
end
function gui.AssetIcon:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128,128)

	local el = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	el:SetMaterial("error")
	self.m_texture = el

	local textBg = gui.create("WIRect",self,0,self:GetHeight() -18,self:GetWidth(),18,0,1,1,1)
	textBg:SetColor(Color(16,16,16,240))

	local elText = gui.create("WIText",self)
	elText:SetColor(Color.White)
	elText:SetFont("pfm_small")
	self.m_text = elText

	local outline = gui.create("WIOutlinedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	outline:SetColor(Color.Red)
	self.m_outline = outline

	gui.AssetIcon.impl.count = gui.AssetIcon.impl.count and (gui.AssetIcon.impl.count +1) or 1
end
function gui.AssetIcon:OnRemove()
	gui.AssetIcon.impl.count = gui.AssetIcon.impl.count and (gui.AssetIcon.impl.count -1) or 0
	if(gui.AssetIcon.impl.count == 0 and gui.AssetIcon.impl.iconGenerator ~= nil) then
		gui.AssetIcon.impl.iconGenerator:Clear()
		gui.AssetIcon.impl.iconGenerator = nil
	end
end
function gui.AssetIcon:SetSelected(selected)
	self.m_selected = selected
	self.m_outline:SetColor(selected and Color.White or Color.Red)
end
function gui.AssetIcon:IsSelected() return self.m_selected or false end
function gui.AssetIcon:SetAsset(path)
	self.m_text:SetText(path)
	self.m_text:SizeToContents()
	self.m_text:CenterToParentX()
	self.m_text:SetY(self:GetHeight() -self.m_text:GetHeight() -4)
	if(file.is_directory(path)) then

		return
	end
end
function gui.AssetIcon:SetModel(mdl)

	--[[local iconPath = get_icon_location(mdl)
	if(file.exists("materials/" .. iconPath .. ".wmi")) then
		self.m_texture:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	gui.AssetIcon.impl.iconGenerator:AddModelToQueue(mdl,function()
		if(self:IsValid() == false) then return end
		self.m_texture:SetMaterial(iconPath)
	end)]]
end
gui.register("WIAssetIcon",gui.AssetIcon)
