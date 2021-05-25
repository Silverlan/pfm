--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("pfm/controls_menu.lua")
include("/util/rig.lua")
include_component("retarget_rig")

locale.load("pfm_retarget.txt")

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

	self.m_ctrlMode = controls:AddDropDownMenu(locale.get_text("mode"),"mode",{{"skeleton",locale.get_text("skeleton")},{"flex_controller",locale.get_text("flex_controllers")}},0,function(el,option)
		self:UpdateMode()
	end)
	controls:AddButton(locale.get_text("pfm_retarget_auto"),"retarget_auto",function()
		local mode = self.m_ctrlMode:GetOptionValue(self.m_ctrlMode:GetSelectedOption())
		self:AutoRetarget(mode == "skeleton",mode == "flex_controller")
	end)
	controls:AddButton(locale.get_text("clear"),"clear",function()
		local mode = self.m_ctrlMode:GetOptionValue(self.m_ctrlMode:GetSelectedOption())
		self:Clear(mode == "skeleton",mode == "flex_controller")
	end)
	controls:ResetControls()

	self.m_boneControls = {}
	self.m_flexControls = {}
end
function gui.BoneRetargeting:UpdateMode()
	if(util.is_valid(self.m_modelView) == false or self.m_srcMdl == nil or self.m_dstMdl == nil) then return end
	local ent0 = self.m_modelView:GetEntity(1)
	local ent1 = self.m_modelView:GetEntity(2)
	if(util.is_valid(ent0) == false or util.is_valid(ent1) == false) then return end
	local mdl0 = ent0:GetModel()
	local mdl1 = ent1:GetModel()
	if(mdl0 == nil or mdl1 == nil) then return end
	local option = self.m_ctrlMode:GetOptionValue(self.m_ctrlMode:GetSelectedOption())
	if(option == "skeleton") then
		local min0,max0 = mdl0:GetRenderBounds()
		ent0:SetPos(Vector(-(max0.x -min0.x) *0.5,0,0))

		local min1,max1 = mdl1:GetRenderBounds()
		ent1:SetPos(Vector((max1.x -min1.x) *0.5,0,0))

		local vc = self.m_modelView:GetViewerCamera()
		if(util.is_valid(vc)) then
			vc:FitViewToScene()
		end
	else
		self.m_modelView:PlayAnimation("reference",1)
		self.m_modelView:PlayAnimation("reference",2)
		local function get_bounds(mdl)
			local head = rig.determine_head_bones(mdl)
			if(head == nil) then return Vector(),mdl:GetRenderBounds() end
			local ref = mdl:GetReferencePose()
			local pose = ref:GetBonePose(head.headBoneId)
			return pose:GetOrigin(),head.headBounds[1],head.headBounds[2]
		end
		local relPos0,min0,max0 = get_bounds(mdl0)
		local relPos1,min1,max1 = get_bounds(mdl1)
		local pos0 = ent0:GetPos() +relPos0
		local pos1 = ent1:GetPos() +relPos1
		local offset = pos1 -pos0 -Vector(max0.x -min1.x,0,0)
		ent1:SetPos(ent1:GetPos() -offset)
		local vc = self.m_modelView:GetViewerCamera()
		if(util.is_valid(vc)) then
			local absMin0 = ent0:GetPos() +relPos0 +min0
			local absMax0 = ent0:GetPos() +relPos0 +max0
			local absMin1 = ent1:GetPos() +relPos1 +min1
			local absMax1 = ent1:GetPos() +relPos1 +max1
			local absMin = Vector(math.min(absMin0.x,absMin1.x),math.min(absMin0.y,absMin1.y),math.min(absMin0.z,absMin1.z))
			local absMax = Vector(math.max(absMax0.x,absMax1.x),math.max(absMax0.y,absMax1.y),math.max(absMax0.z,absMax1.z))
			vc:FitViewToScene(absMin,absMax)
		end
	end
	if(util.is_valid(self.m_boneControlMenu)) then self.m_boneControlMenu:SetVisible(option == "skeleton") end
	if(util.is_valid(self.m_flexControlMenu)) then self.m_flexControlMenu:SetVisible(option == "flex_controller") end
	self.m_modelView:Render()

	self:UpdateBoneVisibility()
end
function gui.BoneRetargeting:Clear(clearSkeleton,clearFlex)
	if(self.m_dstMdl == nil) then return end
	if(clearSkeleton == nil) then clearSkeleton = true end
	if(clearFlex == nil) then clearFlex = true end
	if(clearSkeleton) then
		local skeleton = self.m_dstMdl:GetSkeleton()
		local numBones = skeleton:GetBoneCount()
		for boneId,el in pairs(self.m_boneControls) do
			if(el:IsValid()) then
				el:ClearSelectedOption()
			end
		end
	end
	if(clearFlex) then self:ResetFlexControllerControls() end
end
function gui.BoneRetargeting:AutoRetarget(autoSkel,autoFlex)
	if(self.m_srcMdl == nil or self.m_dstMdl == nil) then return end
	if(autoSkel == nil) then autoSkel = true end
	if(autoFlex == nil) then autoFlex = true end

	if(autoSkel) then
		local boneMatches = {}
		local translationTable = {}
		local skeletonSrc = self.m_srcMdl:GetSkeleton()
		local skeletonDst = self.m_dstMdl:GetSkeleton()
		local map = ents.RetargetRig.autoretarget_skeleton(skeletonSrc,skeletonDst)
		for nameSrc,nameDst in pairs(map) do
			local idSrc = skeletonSrc:LookupBone(nameSrc)
			local idDst = skeletonDst:LookupBone(nameDst)
			if(idSrc ~= -1 and idDst ~= -1) then
				self:MapBone(idSrc,idDst)
			end
		end
	end

	if(autoFlex) then
		local flexControllerNamesSrc = {}
		for i,fc in ipairs(self.m_srcMdl:GetFlexControllers()) do
			table.insert(flexControllerNamesSrc,fc.name)
		end

		local flexControllerNamesDst = {}
		for i,fc in ipairs(self.m_dstMdl:GetFlexControllers()) do
			table.insert(flexControllerNamesDst,fc.name)
		end
		map = ents.RetargetRig.autoretarget(flexControllerNamesSrc,flexControllerNamesDst)
		for nameSrc,nameDst in pairs(map) do
			local idSrc = self.m_srcMdl:LookupFlexController(nameSrc)
			local idDst = self.m_dstMdl:LookupFlexController(nameDst)
			if(idSrc ~= -1 and idDst ~= -1) then
				self:MapFlexController(idSrc,idDst,0,1,0,1)
			end
		end
	end
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
		self:UpdateRetargetComponent()
	end
	self:SetRig(rig)
	if(util.is_valid(self.m_mdlView)) then
		self:LinkToModelView(self.m_mdlView)
		self:InitializeModelView()
		local entSrc = self.m_mdlView:GetEntity(1)
		local entDst = self.m_mdlView:GetEntity(2)
		if(util.is_valid(entSrc) and util.is_valid(entDst)) then
			local retargetC = entDst:AddComponent("retarget_rig")
			local animSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
			if(retargetC ~= nil and animSrc ~= nil) then retargetC:SetRig(rig,animSrc) end

			local retargetMorphC = entDst:AddComponent("retarget_morph")
			local flexC = entSrc:GetComponent(ents.COMPONENT_FLEX)
			if(retargetMorphC ~= nil and flexC ~= nil) then retargetMorphC:SetRig(rig,flexC) end
		end
	end
	self:UpdateMode()
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
function gui.BoneRetargeting:UpdateBoneVisibility()
	local enabled = toboolean(self.m_elShowBones:GetOptionValue(self.m_elShowBones:GetSelectedOption()))
	local option = self.m_ctrlMode:GetOptionValue(self.m_ctrlMode:GetSelectedOption())
	if(option ~= "skeleton") then enabled = false end
	if(util.is_valid(self.m_mdlView) == false) then return end
	local tEnts = {}

	local ent0 = self.m_mdlView:GetEntity(1)
	if(util.is_valid(ent0)) then table.insert(tEnts,ent0) end
	
	local ent1 = self.m_mdlView:GetEntity(2)
	if(util.is_valid(ent1)) then table.insert(tEnts,ent1) end

	for i,ent in ipairs(tEnts) do
		if(enabled) then
			local debugC = ent:AddComponent("debug_skeleton_draw")
			if(debugC ~= nil) then
				if(i == 1) then debugC:SetColor(Color.Orange)
				else debugC:SetColor(Color.Aqua) end
			end
		else ent:RemoveComponent("debug_skeleton_draw") end
	end
	self.m_mdlView:Render()
end
function gui.BoneRetargeting:InitializeModelView()
	if(util.is_valid(self.m_modelView) == false) then return end
	local ent0 = self.m_modelView:GetEntity(1)
	local ent1 = self.m_modelView:GetEntity(2)
	if(util.is_valid(ent1) == false) then ent1 = self.m_modelView:AddActor() end
	if(util.is_valid(ent0) == false or util.is_valid(ent1) == false) then return end
	self.m_modelView:SetModel(self.m_srcMdl)
	self.m_modelView:SetModel(self.m_dstMdl,2)
	self.m_modelView:PlayAnimation("reference",1)
	self.m_modelView:PlayAnimation("reference",2)
	self:UpdateMode()
	return ent
end
function gui.BoneRetargeting:SetRig(rig)
	util.remove(self.m_rigControls)
	util.remove(self.m_boneControlMenu)
	util.remove(self.m_flexControlMenu)
	local mdlSrc = rig:GetSourceModel()
	local mdlDst = rig:GetDestinationModel()
	if(mdlSrc == nil or mdlDst == nil) then return end
	self.m_rig = rig
	self.m_srcMdl = mdlSrc
	self.m_dstMdl = mdlDst

	self.m_rigControls = self.m_controls:AddSubMenu()
	self.m_boneControlMenu = self.m_rigControls:AddSubMenu()
	self.m_flexControlMenu = self.m_rigControls:AddSubMenu()
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
function gui.BoneRetargeting:MapBone(boneSrc,boneDst,skipCallbacks)
	if(type(boneSrc) == "string") then boneSrc = self.m_srcMdl:GetSkeleton():LookupBone(boneSrc) end
	if(type(boneDst) == "string") then boneDst = self.m_dstMdl:GetSkeleton():LookupBone(boneDst) end

	if(skipCallbacks) then self.m_skipCallbacks = true end
	local ctrl = self.m_boneControls[boneDst]
	if(util.is_valid(ctrl)) then
		ctrl:SelectOption(tostring(boneSrc))
	end
	if(skipCallbacks) then self.m_skipCallbacks = nil end
end
function gui.BoneRetargeting:SetBoneTranslation(boneIdSrc,boneIdDst)
	self.m_rig:SetBoneTranslation(boneIdSrc,boneIdDst)
	self:UpdateRetargetComponent()
end
function gui.BoneRetargeting:SetBoneColor(actorId,boneId,col)
	if(boneId == nil) then
		if(self.m_origBoneColor == nil or self.m_origBoneColor[actorId] == nil) then return end
		for boneId,_ in pairs(self.m_origBoneColor) do
			self:SetBoneColor(actorId,boneId,col)
		end
		return
	end

	local ent = util.is_valid(self.m_mdlView) and self.m_mdlView:GetEntity(actorId) or nil
	local debugC = util.is_valid(ent) and ent:AddComponent("debug_skeleton_draw") or nil
	if(debugC == nil) then return end
	local entBone = debugC:GetBoneEntity(boneId)
	if(util.is_valid(entBone) == false) then return end
	if(col == nil) then
		if(self.m_origBoneColor == nil or self.m_origBoneColor[actorId] == nil or self.m_origBoneColor[actorId][boneId] == nil) then return end
		col = self.m_origBoneColor[actorId][boneId]
		self.m_origBoneColor[actorId][boneId] = nil
	else
		self.m_origBoneColor = self.m_origBoneColor or {}
		self.m_origBoneColor[actorId] = self.m_origBoneColor[actorId] or {}
		self.m_origBoneColor[actorId][boneId] = self.m_origBoneColor[actorId][boneId] or entBone:GetColor()
	end
	entBone:SetColor(col)
	self.m_mdlView:Render()
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

	local el,wrapper = self.m_boneControlMenu:AddDropDownMenu(locale.get_text("pfm_show_bones"),"show_bones",{{"0",locale.get_text("disabled")},{"1",locale.get_text("enabled")}},"0",function(el)
		self:UpdateBoneVisibility()
	end)
	self.m_elShowBones = el
	self.m_boneControlMenu:ResetControls()

	local bones = get_bones_in_hierarchical_order(mdlDst)
	for _,boneInfo in ipairs(bones) do
		local boneDst = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. boneDst:GetName()
		local el,wrapper = self.m_boneControlMenu:AddDropDownMenu(name,boneDst:GetID(),options,0,function(el)
			if(self.m_skipCallbacks) then return end
			self.m_lastSelectedBoneOption = el:GetSelectedOption()
			self:ApplyBoneTranslation(el,boneDst)
		end)
		el:AddCallback("OnMenuOpened",function(el)
			if(self.m_lastSelectedBoneOption ~= nil) then el:ScrollToOption(self.m_lastSelectedBoneOption) end
			self:SetBoneColor(2,boneDst:GetID(),Color.Red)
		end)
		el:AddCallback("OnMenuClosed",function(el)
			self:SetBoneColor(2,boneDst:GetID())
			self:SetBoneColor(1)
		end)
		wrapper:AddCallback("TranslateValueText",function(wrapper,text)
			return util.EVENT_REPLY_HANDLED,string.remove_whitespace(text)
		end)
		wrapper:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				wrapper:StartEditMode(false)
				self:SetBoneTranslation(nil,boneDst:GetID())
				el:SelectOption(0)
				el:CloseMenu()
				self:UpdateModelView()
				return util.EVENT_REPLY_HANDLED
			end
		end)
		wrapper:SetCenterText(false)
		for i=0,el:GetOptionCount() -1 do
			el:GetOptionElement(i):AddCallback("OnSelectionChanged",function(pItem,selected)
				local boneIdSrc = tonumber(el:GetOptionValue(i))
				if(boneIdSrc ~= nil) then
					if(selected) then
						self:SetBoneTranslation(boneIdSrc,boneDst:GetID())
						self:SetBoneColor(1,boneIdSrc,Color.Red)
					else self:SetBoneColor(1,boneIdSrc) end
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
function gui.BoneRetargeting:SetModelView(mdlView) self.m_mdlView = mdlView end
function gui.BoneRetargeting:UpdateRetargetComponent()
	if(util.is_valid(self.m_mdlView) == false) then return end
	local entDst = self.m_mdlView:GetEntity(2)
	local retargetC = util.is_valid(entDst) and entDst:AddComponent("retarget_rig") or nil
	if(retargetC == nil) then return end
	retargetC:InitializeRemapTables()
end
function gui.BoneRetargeting:ApplyBoneTranslation(el,bone)
	if(self.m_rig == nil) then return end
	local boneId = tonumber(el:GetOptionValue(el:GetSelectedOption()))
	self:SetBoneTranslation(boneId,bone and bone:GetID() or nil)
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
	for boneIdDst,boneSrcData in pairs(options) do self:MapBone(boneSrcData[1],boneIdDst,true) end
end
gui.register("WIBoneRetargeting",gui.BoneRetargeting)
