--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../textureslot.lua")

util.register_class("gui.RMAComposerDialog",gui.Base)
function gui.RMAComposerDialog:__init()
	gui.Base.__init(self)
end
function gui.RMAComposerDialog:Compose()
	local shaderRMA = shader.get("compose_rma")
	if(shaderRMA == nil) then return end
	local workflow = self.m_workflow:GetOptionValue(self.m_workflow:GetSelectedOption())
	local flags = shader.ComposeRMA.FLAG_NONE
	if(workflow == "specular") then flags = bit.bor(flags,shader.ComposeRMA.FLAG_USE_SPECULAR_WORKFLOW_BIT) end

	local aoMap = self.m_slotAo:GetTextureObject()
	local roughnessMap = self.m_slotRoughness:GetTextureObject()
	local metalnessMap = self.m_slotMetalness:GetTextureObject()
	local rmaMap = shaderRMA:ComposeRMA(roughnessMap,metalnessMap,aoMap,flags)
	return rmaMap
end
function gui.RMAComposerDialog:OnRemove()
	if(self.m_aoJob ~= nil) then
		self.m_aoJob:Cancel()
		self.m_aoJob = nil
	end
end
function gui.RMAComposerDialog:OnThink()
	if(self.m_aoJob == nil) then
		self:DisableThinking()
		return
	end
	if(self.m_aoJob:IsComplete() == false) then return end
	if(self.m_aoJob:GetStatus() == util.ParallelJob.JOB_STATUS_SUCCESSFUL) then
		local result = self.m_aoJob:GetResult()
		local img = prosper.create_image(result)
		local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),prosper.SamplerCreateInfo())
		tex:SetDebugName("rma_composer_dialog_tex")
		self.m_slotAo:SetTexture(tex)
	end
end
function gui.RMAComposerDialog:GetRMAMap() return self.m_rmaMap end
function gui.RMAComposerDialog:SetRMAMap(rmaMap)
	self.m_slotAo:SetTexture(rmaMap)
	self.m_slotRoughness:SetTexture(rmaMap)
	self.m_slotMetalness:SetTexture(rmaMap)
end
function gui.RMAComposerDialog:SetModel(mdl,matIdx)
	self.m_model = mdl
	self.m_materialIndex = matIdx
end
function gui.RMAComposerDialog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(700,370)

	local el = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)

	local function add_slot(parent,tex,defaultChannel)
		local vbox = gui.create("WIVBox",parent,0,0,200,200)
		vbox:SetAutoFillContentsToWidth(true)
		local texSlot = gui.create("WIPFMTextureSlot",vbox)
		texSlot:SetSize(200,200)
		texSlot:SetTexture(tex)
		texSlot:SetClearTexture(tex)

		local elLabel = gui.create("WIEditableEntry",vbox)
		elLabel:SetEmpty()

		local channel = gui.create("WIDropDownMenu",vbox)
		channel:AddOption(locale.get_text("red"),tostring(gui.TexturedShape.CHANNEL_RED))
		channel:AddOption(locale.get_text("green"),tostring(gui.TexturedShape.CHANNEL_GREEN))
		channel:AddOption(locale.get_text("blue"),tostring(gui.TexturedShape.CHANNEL_BLUE))
		channel:AddOption(locale.get_text("alpha"),tostring(gui.TexturedShape.CHANNEL_ALPHA))
		channel:Wrap("WIEditableEntry"):SetText(locale.get_text("channel"))
		channel:AddCallback("OnOptionSelected",function(el,option)
			texSlot:SetGreyscaleChannel(tonumber(channel:GetOptionValue(option)))
		end)
		channel:SelectOption(defaultChannel)

		return elLabel,texSlot
	end

	local contents = gui.create("WIVBox",el)
	gui.create("WIBase",contents,0,0,1,30) -- Spacing
	local hbox = gui.create("WIHBox",contents)
	local slotR,texSlotAo = add_slot(hbox,"white",gui.TexturedShape.CHANNEL_RED)
	local slotG,texSlotRoughness = add_slot(hbox,"white",gui.TexturedShape.CHANNEL_GREEN)
	local slotB,texSlotMetalness = add_slot(hbox,"white",gui.TexturedShape.CHANNEL_BLUE)

	texSlotAo:AddCallback("PopulateContextMenu",function(texSlotAo,pContext)
		if(util.is_valid(self.m_model) and self.m_materialIndex ~= nil) then
			pContext:AddItem(locale.get_text("pfm_generate_ambient_occlusion"),function()
				if(util.is_valid(self.m_model) == false or pfm.load_cycles() == false) then return end

				local width = 512
				local height = 512
				local mat = self.m_model:GetMaterial(self.m_materialIndex)
				if(mat ~= nil) then
					local texInfo = mat:GetTextureInfo("albedo_map")
					if(texInfo ~= nil) then
						width = math.min(texInfo:GetWidth(),1024)
						height = math.min(texInfo:GetHeight(),1024)
					end
				end

				local samples = 20
				self.m_aoJob = unirender.bake_ambient_occlusion(self.m_model,self.m_materialIndex,width,height,samples)
				if(self.m_aoJob == nil) then return end
				self.m_aoJob:Start()
				self:EnableThinking()
			end)
		end
	end)

	self.m_slotAo = texSlotAo
	self.m_slotRoughness = texSlotRoughness
	self.m_slotMetalness = texSlotMetalness

	slotR:SetText(locale.get_text("ambient_occlusion"))

	local function set_workflow(workflow)
		if(workflow == "metallic") then
			slotG:SetText(locale.get_text("roughness"))
			slotB:SetText(locale.get_text("metalness"))
		else
			slotG:SetText(locale.get_text("specular"))
			slotB:SetText(locale.get_text("glossiness"))
		end
	end
	set_workflow("metallic")

	local workflow = gui.create("WIDropDownMenu",contents)
	workflow:AddOption(locale.get_text("metallic"),"metallic")
	workflow:AddOption(locale.get_text("specular"),"specular")
	workflow:SelectOption(0)
	workflow:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_mated_workflow"))
	workflow:AddCallback("OnOptionSelected",function(el,option)
		set_workflow(el:GetOptionValue(option))
	end)
	self.m_workflow = workflow

	hbox:Update()
	contents:SetAutoFillContentsToWidth(true)

	gui.create("WIBase",contents,0,0,1,20) -- Spacing

	local pButtonOpen = gui.create("WIButton",self)
	pButtonOpen:SetWidth(140)
	pButtonOpen:SetPos(self:GetWidth() -pButtonOpen:GetWidth() -20,self:GetHeight() -pButtonOpen:GetHeight() -20)
	pButtonOpen:SetAnchor(1,1,1,1)
	pButtonOpen:SetText(locale.get_text("pfm_mated_compose_rma"))
	pButtonOpen:AddCallback("OnPressed",function(pButton)
		self.m_rmaMap = self:Compose()
		if(self.m_rmaMap ~= nil) then self:CallCallbacks("OnRMAComposed",self.m_rmaMap) end
		gui.close_dialog()
	end)

	local pButtonCancel = gui.create("WIButton",self)
	pButtonCancel:SetPos(pButtonOpen:GetLeft() -pButtonCancel:GetWidth() -10,pButtonOpen:GetTop())
	pButtonCancel:SetAnchor(1,1,1,1)
	pButtonCancel:SetText(locale.get_text("cancel"))
	pButtonCancel:AddCallback("OnPressed",function(pButton)
		gui.close_dialog()
	end)

	contents:CenterToParentX()
	contents:SetAnchor(0.5,0,0.5,0)
end
gui.register("WIRMAComposerDialog",gui.RMAComposerDialog)
