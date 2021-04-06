--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("pfm/controls_menu.lua")
include_component("retarget_rig")

local function get_bones_in_hierarchical_order(mdl)
	local bones = {}
	local function add_bones(bone,depth)
		depth = depth or 0
		table.insert(bones,{bone,depth})
		for boneId,child in pairs(bone:GetChildren()) do
			add_bones(child,depth +1)
		end
	end
	for boneId,bone in pairs(mdl:GetSkeleton():GetRootBones()) do
		add_bones(bone)
	end
	return bones
end

util.register_class("gui.BoneRetargeting",gui.Base)

include("bone_retargeting_flex.lua")

function gui.BoneRetargeting:__init()
	gui.Base.__init(self)
end
function gui.BoneRetargeting:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)
	self:UpdateModelView()

	local scrollContainer = gui.create("WIScrollContainer",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	scrollContainer:SetContentsWidthFixed(true)

	local controls = gui.create("WIPFMControlsMenu",scrollContainer,0,0,scrollContainer:GetWidth(),scrollContainer:GetHeight())
	controls:SetAutoFillContentsToHeight(false)
	controls:SetFixedHeight(false)
	self:SetThinkingEnabled(true)
	self.m_controls = controls

	local feImpostee
	local feImposter
	feImpostee = controls:AddFileEntry(locale.get_text("pfm_impostee_model"),"impostee_model","",function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(el:GetFilePath(true))
		end)
		pFileDialog:SetRootPath("models")
		pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MODEL))
		pFileDialog:Update()
	end)
	feImpostee:AddCallback("OnValueChanged",function(...)
		self:UpdateImpostorTargets(feImpostee,feImposter)
	end)
	feImposter = controls:AddFileEntry(locale.get_text("pfm_imposter_model"),"imposter_model","",function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(el:GetFilePath(true))
		end)
		pFileDialog:SetRootPath("models")
		pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MODEL))
		pFileDialog:Update()
	end)
	feImposter:AddCallback("OnValueChanged",function(...)
		self:UpdateImpostorTargets(feImpostee,feImposter)
	end)
	self.m_feImpostee = feImpostee
	self.m_feImposter = feImposter

	self.m_boneControls = {}
	self.m_flexControls = {}
end
function gui.BoneRetargeting:SetImpostee(impostee)
	if(util.is_valid(self.m_feImpostee)) then self.m_feImpostee:SetValue(impostee) end
end
function gui.BoneRetargeting:SetImposter(imposter)
	if(util.is_valid(self.m_feImposter)) then self.m_feImposter:SetValue(imposter) end
end
function gui.BoneRetargeting:UpdateImpostorTargets(feImpostee,feImposter)
	local pathImpostee = feImpostee:GetValue()
	local pathImposter = feImposter:GetValue()
	if(#pathImpostee == 0 or #pathImposter == 0) then return end
	self:SetModelTargets(pathImpostee,pathImposter)
end
function gui.BoneRetargeting:SetModelTargets(mdlSrc,mdlDst)
	local mdlSrcPath = mdlSrc
	mdlSrc = game.load_model(mdlSrc)
	mdlDst = game.load_model(mdlDst)
	if(mdlSrc == nil or mdlDst == nil) then return end
	local rig = ents.RetargetRig.Rig.load(mdlSrc,mdlDst)
	if(rig == false) then
		rig = ents.RetargetRig.Rig(mdlSrc,mdlDst)

		-- local boneRemapper = ents.RetargetRig.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		-- local translationTable = boneRemapper:AutoRemap()
		-- rig:SetTranslationTable(translationTable)
		rig:SetDstToSrcTranslationTable({})
	end
	self:SetRig(rig)

	-- TODO: This doesn't really belong here!
	local pfm = tool.get_filmmaker()
	if(util.is_valid(pfm) == false) then return end
	pfm:OpenModelView(mdlSrcPath)
	if(util.is_valid(pfm.m_mdlView)) then
		self:LinkToModelView(pfm.m_mdlView)
		self:InitializeModelView()
		local entSrc = pfm.m_mdlView:GetEntity(1)
		local entDst = pfm.m_mdlView:GetEntity(2)
		if(util.is_valid(entSrc) and util.is_valid(entDst)) then
			local retargetC = entDst:AddComponent("retarget_rig")
			local animSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
			if(retargetC ~= nil and animSrc ~= nil) then retargetC:SetRig(rig,animSrc) end

			local retargetMorphC = entDst:AddComponent("retarget_morph")
			local flexC = entSrc:GetComponent(ents.COMPONENT_FLEX)
			if(retargetMorphC ~= nil and flexC ~= nil) then retargetMorphC:SetRig(rig,flexC) end
		end
	end
end
function gui.BoneRetargeting:OnRemove()
	self:UnlinkFromModelView()
end
function gui.BoneRetargeting:OnSizeChanged(w,h)
	if(util.is_valid(self.m_controls)) then self.m_controls:SetWidth(w) end
end
function gui.BoneRetargeting:GetSourceModel() return self.m_srcMdl end
function gui.BoneRetargeting:GetDestinationModel() return self.m_dstMdl end
function gui.BoneRetargeting:GetBoneControl(i) return self.m_boneControls[i] end
function gui.BoneRetargeting:LinkToModelView(mv) self.m_modelView = mv end
function gui.BoneRetargeting:UnlinkFromModelView()
	if(util.is_valid(self.m_modelView) == false) then return end
	local mdlView = self.m_modelView
	mdlView:RemoveActor(2)
	local ent = mdlView:GetEntity(1)
	if(util.is_valid(ent)) then ent:SetPos(Vector()) end
	self.m_modelView = nil
end
function gui.BoneRetargeting:InitializeModelView()
	if(util.is_valid(self.m_modelView) == false) then return end
	local ent0 = self.m_modelView:GetEntity(1)
	local ent1 = self.m_modelView:GetEntity(2)
	if(util.is_valid(ent1) == false) then ent1 = self.m_modelView:AddActor() end
	if(util.is_valid(ent0) == false or util.is_valid(ent1) == false) then return end
	self.m_modelView:SetModel(self.m_srcMdl)
	self.m_modelView:SetModel(self.m_dstMdl,2)

	local mdl0 = ent0:GetModel()
	local mdl1 = ent1:GetModel()
	if(mdl0 == nil or mdl1 == nil) then return end

	local min0,max0 = mdl0:GetRenderBounds()
	ent0:SetPos(Vector(-(max0.x -min0.x) *0.5,0,0))

	local min1,max1 = mdl1:GetRenderBounds()
	ent1:SetPos(Vector((max1.x -min1.x) *0.5,0,0))
	return ent
end
function gui.BoneRetargeting:SetRig(rig)
	util.remove(self.m_rigControls)
	local mdlSrc = rig:GetSourceModel()
	local mdlDst = rig:GetDestinationModel()
	if(mdlSrc == nil or mdlDst == nil) then return end
	self.m_rig = rig
	self.m_srcMdl = mdlSrc
	self.m_dstMdl = mdlDst

	self.m_rigControls = self.m_controls:AddSubMenu()
	self:InitializeBoneControls(mdlSrc,mdlDst)
	self:InitializeFlexControls(mdlSrc,mdlDst)

	self.m_rigControls:AddButton(locale.get_text("save"),"save",function()
		local rig = self:GetRig()
		rig:Save()
	end)
	gui.create("WIBase",self.m_rigControls) -- Dummy
	-- TODO: Flex controllers, attachments, etc?
	self:SetSelectedOptions(rig:GetDstToSrcTranslationTable())

	local flexControllerTranslationTable = rig:GetFlexControllerTranslationTable()
	for flexCId0,mappings in pairs(flexControllerTranslationTable) do
		for flexCId1,data in pairs(mappings) do
			self:MapFlexController(flexCId0,flexCId1,data.min_source,data.max_source,data.min_target,data.max_target)
		end
	end

	-- self:ApplyRig()
end
function gui.BoneRetargeting:ResetBoneControls()
	self.m_skipCallbacks = true
	for boneId,el in pairs(self.m_boneControls) do
		if(el:IsValid()) then el:SelectOption(0) end
	end
	self.m_skipCallbacks = nil
end
function gui.BoneRetargeting:MapBone(boneSrc,boneDst)
	if(type(boneSrc) == "string") then boneSrc = self.m_srcMdl:GetSkeleton():LookupBone(boneSrc) end
	if(type(boneDst) == "string") then boneDst = self.m_dstMdl:GetSkeleton():LookupBone(boneDst) end

	self.m_skipCallbacks = true
	local ctrl = self.m_boneControls[boneDst]
	if(util.is_valid(ctrl)) then
		ctrl:SelectOption(tostring(boneSrc))
	end
	self.m_skipCallbacks = nil
end
function gui.BoneRetargeting:InitializeBoneControls(mdlSrc,mdlDst)
	local options = {}
	local bonesSrc = get_bones_in_hierarchical_order(mdlSrc)
	for _,boneInfo in ipairs(bonesSrc) do
		local bone = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. bone:GetName()
		table.insert(options,{tostring(bone:GetID()),name})
	end
	table.insert(options,1,{"-1","-"})

	local bones = get_bones_in_hierarchical_order(mdlDst)
	for _,boneInfo in ipairs(bones) do
		local boneDst = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. boneDst:GetName()
		local el,wrapper = self.m_rigControls:AddDropDownMenu(name,boneDst:GetID(),options,0,function(el)
			if(self.m_skipCallbacks) then return end
			self.m_lastSelectedBoneOption = el:GetSelectedOption()
			self:ApplyBoneTranslation(el,boneDst)
		end)
		el:AddCallback("OnMenuOpened",function(el)
			if(self.m_lastSelectedBoneOption ~= nil) then el:ScrollToOption(self.m_lastSelectedBoneOption) end
		end)
		wrapper:AddCallback("TranslateValueText",function(wrapper,text)
			return util.EVENT_REPLY_HANDLED,string.remove_whitespace(text)
		end)
		wrapper:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				wrapper:StartEditMode(false)
				self.m_rig:SetBoneTranslation(nil,boneDst:GetID())
				el:SelectOption(0)
				el:CloseMenu()
				self:UpdateModelView()
				return util.EVENT_REPLY_HANDLED
			end
		end)
		wrapper:SetCenterText(false)
		for i=0,el:GetOptionCount() -1 do
			el:GetOptionElement(i):AddCallback("OnSelectionChanged",function(pItem,selected)
				if(selected) then
					local boneIdSrc = tonumber(el:GetOptionValue(i))
					if(boneIdSrc ~= nil) then
						self.m_rig:SetBoneTranslation(boneIdSrc,boneDst:GetID())
					end
				end
				self:UpdateModelView()
			end)
		end
		wrapper:SetUseAltMode(true)
		self.m_boneControls[boneDst:GetID()] = el
	end
end
function gui.BoneRetargeting:UpdateModelView()
	self.m_tUpdateModelView = time.real_time()
end
function gui.BoneRetargeting:OnThink()
	if(time.real_time() -self.m_tUpdateModelView < 0.25) then
		if(util.is_valid(self.m_modelView)) then self.m_modelView:Render() end
	end
	self:UpdateFlexControllers()
end
function gui.BoneRetargeting:ApplyBoneTranslation(el,bone)
	if(self.m_rig == nil) then return end
	local boneId = tonumber(el:GetOptionValue(el:GetSelectedOption()))
	self.m_rig:SetBoneTranslation(boneId,bone and bone:GetID() or nil)
	self:UpdateModelView()
end
function gui.BoneRetargeting:GetRig() return self.m_rig end
--[[function gui.BoneRetargeting:ApplyRig()
	local entSrc = self.m_modelView:GetEntity(1)
	local entDst = self.m_modelView:GetEntity(2)
	if(util.is_valid(entSrc) == false or util.is_valid(entDst) == false) then return end
	local animCSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
	if(animCSrc == nil) then return end
	local retargetRigC = entDst:AddComponent("retarget_rig")
	if(retargetRigC == nil) then return end
	local rig = ents.RetargetRig.Rig(self.m_srcMdl,self.m_dstMdl)
	rig:SetDstToSrcTranslationTable(self:GetTranslationTable())

	retargetRigC:SetRig(rig,animCSrc)
	self.m_rig = rig
end]]
function gui.BoneRetargeting:GetTranslationTable()
	local translationTable = {}
	local skeleton = self.m_dstMdl:GetSkeleton()
	for _,bone in ipairs(skeleton:GetBones()) do
		local ctrl = self:GetBoneControl(bone:GetID())
		if(util.is_valid(ctrl)) then
			local boneIdSrc = tonumber(ctrl:GetOptionValue(ctrl:GetSelectedOption()))
			if(boneIdSrc ~= -1) then translationTable[bone:GetID()] = boneIdSrc end -- TODO: Flip
		end
	end
	return translationTable
end
function gui.BoneRetargeting:GetBoneNames(mdl)
	local boneNames = {}
	local skeleton = mdl:GetSkeleton()
	for _,bone in ipairs(skeleton:GetBones()) do
		table.insert(boneNames,bone:GetName())
	end
	return boneNames
end
function gui.BoneRetargeting:SetSelectedOptions(options)
	self:ResetBoneControls()
	for boneIdDst,boneSrcData in pairs(options) do self:MapBone(boneSrcData[1],boneIdDst) end
end
gui.register("WIBoneRetargeting",gui.BoneRetargeting)
