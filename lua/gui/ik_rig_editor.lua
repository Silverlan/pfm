--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("pfm/controls_menu.lua")

local Element = util.register_class("gui.IkRigEditor",gui.Base)

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

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)
	self.m_ikRig = ents.IkSolverComponent.RigConfig()
	self:UpdateModelView()

	local scrollContainer = gui.create("WIScrollContainer",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	scrollContainer:SetContentsWidthFixed(true)

	local controls = gui.create("WIPFMControlsMenu",scrollContainer,0,0,scrollContainer:GetWidth(),scrollContainer:GetHeight())
	controls:SetAutoFillContentsToHeight(false)
	controls:SetFixedHeight(false)
	self:SetThinkingEnabled(true)
	self.m_controls = controls

	local feModel
	feModel = controls:AddFileEntry(locale.get_text("pfm_impostee_model"),"impostee_model","",function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(el:GetFilePath(true))
		end)
		pFileDialog:SetRootPath("models")
		pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MODEL))
		pFileDialog:Update()
	end)
	feModel:AddCallback("OnValueChanged",function(...)
		if(self.m_skipButtonCallbacks) then return end
		self:UpdateImpostorTargets(feModel)
	end)
	self.m_feModel = feModel

	--[[controls:AddButton(locale.get_text("pfm_retarget_auto"),"retarget_auto",function()
		local mode = self.m_ctrlMode:GetOptionValue(self.m_ctrlMode:GetSelectedOption())
		self:AutoRetarget(mode == "skeleton",mode == "flex_controller")
	end)]]
	controls:ResetControls()

	self.m_boneControls = {}
end
function Element:UpdateMode()
	if(util.is_valid(self.m_modelView) == false or self.m_mdl == nil) then return end
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	if(self.m_lastSkeletalAnim ~= nil) then
		ent0:PlayAnimation(self.m_lastSkeletalAnim)
		self.m_lastSkeletalAnim = nil
	end
	local min,max = mdl:GetRenderBounds()
	ent:SetPos(Vector(-(max.x -min.x) *0.5,0,0))

	local vc = self.m_modelView:GetViewerCamera()
	if(util.is_valid(vc)) then
		vc:FitViewToScene()
	end

	self.m_boneControlMenu:SetVisible(true)
	self.m_modelView:Render()

	self:UpdateBoneVisibility()
end
function Element:Clear(clearSkeleton,clearFlex)
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
function Element:SetModel(impostee)
	if(util.is_valid(self.feModel)) then self.feModel:SetValue(impostee) end
end
function Element:UpdateImpostorTargets(feModel)
	local pathMdl = feModel:GetValue()
	if(#pathMdl == 0) then return end
	local mdl = game.load_model(pathMdl)
	if(mdl == nil) then return end
	self.m_mdl = mdl

	self:AddBoneList()
	if(util.is_valid(self.m_mdlView)) then
		self:LinkToModelView(self.m_mdlView)
		self:InitializeModelView()
	end
	self:UpdateMode()

	self.m_ikRig = ents.IkSolverComponent.RigConfig()
end
function Element:OnRemove()
	self:UnlinkFromModelView()
	util.remove(self.m_entTransformGizmo)
	util.remove(self.m_trOnGizmoControlAdded)
	util.remove(self.m_cbOnAnimsUpdated)
end
function Element:OnSizeChanged(w,h)
	if(util.is_valid(self.m_controls)) then self.m_controls:SetWidth(w) end
end
function Element:GetSourceModel() return self.m_mdl end
function Element:GetBoneControl(i) return self.m_boneControls[i] end
function Element:LinkToModelView(mv) self.m_modelView = mv end
function Element:UnlinkFromModelView()
	if(util.is_valid(self.m_modelView) == false) then return end
	local mdlView = self.m_modelView
	mdlView:RemoveActor(2)
	local ent = mdlView:GetEntity(1)
	if(util.is_valid(ent)) then ent:SetPos(Vector()) end
	self.m_modelView = nil
end
function Element:UpdateBoneVisibility()
	local enabled = toboolean(self.m_elShowBones:GetOptionValue(self.m_elShowBones:GetSelectedOption()))
	if(util.is_valid(self.m_mdlView) == false) then return end
	local tEnts = {}

	local ent = self.m_mdlView:GetEntity(1)
	if(util.is_valid(ent)) then table.insert(tEnts,ent) end

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
function Element:InitializeModelView()
	if(util.is_valid(self.m_modelView) == false) then return end
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	self.m_modelView:SetModel(self.m_mdl)
	self.m_modelView:PlayAnimation("reference",1)
	self:UpdateMode()
	return ent
end
function Element:AddBoneList()
	local mdl = self.m_mdl
	if(mdl == nil) then return end

	self.m_rigControls = self.m_controls:AddSubMenu()
	self.m_boneControlMenu = self.m_rigControls:AddSubMenu()
	self:InitializeBoneControls(mdl)

	self.m_rigControls:AddButton(locale.get_text("save"),"save",function()
		local rig = self:GetRig()
		if(rig:Save()) then self:CallCallbacks("OnRigSaved",rig) end
	end)
	gui.create("WIBase",self.m_rigControls) -- Dummy
end
function Element:ResetBoneControls()
	self.m_skipCallbacks = true
	for boneId,el in pairs(self.m_boneControls) do
		if(el:IsValid()) then el:SelectOption(0) end
	end
	self.m_skipCallbacks = nil
end
function Element:MapBone(boneSrc,boneDst,skipCallbacks)
	if(type(boneSrc) == "string") then boneSrc = self.m_srcMdl:GetSkeleton():LookupBone(boneSrc) end
	if(type(boneDst) == "string") then boneDst = self.m_dstMdl:GetSkeleton():LookupBone(boneDst) end

	if(skipCallbacks) then self.m_skipCallbacks = true end
	local ctrl = self.m_boneControls[boneDst]
	if(util.is_valid(ctrl)) then
		ctrl:SelectOption(tostring(boneSrc))
	end
	if(skipCallbacks) then self.m_skipCallbacks = nil end
end
function Element:SetBoneColor(actorId,boneId,col)
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
function Element:InitializeBoneControls(mdl)
	local options = {}
	--[[local bonesSrc = get_bones_in_hierarchical_order(mdl)
	for _,boneInfo in ipairs(bonesSrc) do
		local bone = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. bone:GetName()
		table.insert(options,{tostring(bone:GetID()),name})
	end
	table.insert(options,1,{"-1","-"})]]

	table.insert(options,{"none","-"})
	table.insert(options,{"hinge","Hinge"})
	table.insert(options,{"ballsocket","BallSocket"})

	local subMenu = self.m_boneControlMenu:AddSubMenu()
	local tree = gui.create("WIPFMTreeView",subMenu,0,0,subMenu:GetWidth(),20)
	self.m_skelTree = tree
	tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	local el,wrapper = self.m_boneControlMenu:AddDropDownMenu(locale.get_text("pfm_show_bones"),"show_bones",{{"0",locale.get_text("disabled")},{"1",locale.get_text("enabled")}},"0",function(el)
		self:UpdateBoneVisibility()
	end)
	self.m_elShowBones = el

	local bones = get_bones_in_hierarchical_order(mdl)
	for _,boneInfo in ipairs(bones) do
		local boneDst = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. boneDst:GetName()
		--[[local el,wrapper = self.m_boneControlMenu:AddDropDownMenu(name,boneDst:GetID(),options,0,function(el)
			if(self.m_skipCallbacks) then return end
			self.m_lastSelectedBoneOption = el:GetSelectedOption()
			self:ApplyBoneTranslation(el,boneDst)
		end)
]]

		local item = tree:AddItem(name)
		item:SetIdentifier(boneDst:GetName())
		item:AddCallback("OnSelectionChanged",function(pItem,selected)
			util.remove(self.m_cbOnAnimsUpdated)
			self:ReloadIkRig()
			self:CreateTransformGizmo()
		end)
		item:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext)) then
					pContext:SetPos(input.get_cursor_pos())
					pContext:AddItem("Add Fixed Constraint",function()
						self:AddFixedConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem("Add Hinge Constraint",function()
						self:AddHingeConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem("Add Ball Socket Constraint",function()
						self:AddBallSocketConstraint(item,boneDst:GetName())
					end)
					if(self.m_ikRig:HasBone(boneDst:GetName())) then
						pContext:AddItem("Remove Bone",function()
							self.m_ikRig:RemoveBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem("Add Bone",function()
							self.m_ikRig:AddBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					end
					if(self.m_ikRig:IsBoneLocked(boneDst:GetName())) then
						pContext:AddItem("Unlock Bone",function()
							--self:MapFlexController(i -1,-1)
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),false)
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem("Lock Bone",function()
							--self:MapFlexController(i -1,-1)
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),true)
							self:ReloadIkRig()
						end)
					end
					if(self.m_ikRig:HasControl(boneDst:GetName())) then
						pContext:AddItem("Remove Control",function()
							--self:MapFlexController(i -1,-1)
							self.m_ikRig:RemoveControl(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem("Add Drag Control",function()
							--self:MapFlexController(i -1,-1)
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_DRAG)
							self:ReloadIkRig()
						end)
						pContext:AddItem("Add State Control",function()
							--self:MapFlexController(i -1,-1)
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_STATE)
							self:ReloadIkRig()
						end)
					end

					--[[for i,flexC in ipairs(flexControllersSrc) do
						pContext:AddItem(flexC.name,function()
							-- self:ShowInElementViewer(filmClip)
						end)
					end]]
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)


		--[[el:AddCallback("OnMenuOpened",function(el)
			if(self.m_lastSelectedBoneOption ~= nil) then el:ScrollToOption(self.m_lastSelectedBoneOption) end
			self:SetBoneColor(2,boneDst:GetID(),Color.Red)
		end)
		el:AddCallback("OnMenuClosed",function(el)
			self:SetBoneColor(2,boneDst:GetID())
			self:SetBoneColor(1)

			self.m_lastSelectedBoneOption = el:GetSelectedOption()
			self:ApplyBoneTranslation(el,boneDst)
		end)

		wrapper:AddCallback("TranslateValueText",function(wrapper,text)
			return util.EVENT_REPLY_HANDLED,string.remove_whitespace(text)
		end)
		wrapper:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				wrapper:StartEditMode(false)

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
						self:SetBoneColor(1,boneIdSrc,Color.Red)
					else self:SetBoneColor(1,boneIdSrc) end
				end
				self:UpdateModelView()
			end)
		end]]
		--wrapper:SetUseAltMode(true)
		--self.m_boneControls[boneDst:GetID()] = el
	end
	self.m_boneControlMenu:ResetControls()
end
function Element:AddConstraint(item,boneName,type)
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(boneName)
	local bone = skel:GetBone(boneId)
	local parent = bone:GetParent()
	self.m_ikRig:AddBone(boneName)
	self.m_ikRig:AddBone(parent:GetName())

	local constraint
	local child = item:AddItem(type .. " Constraint")
	child:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext)) then
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem("Remove",function()
					self.m_ikRig:RemoveConstraint(constraint)
					child:RemoveSafely()
					item:ScheduleUpdate()
					self:ReloadIkRig()
				end)
				pContext:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)

	local ctrlsParent = child:AddItem("")
	local crtl = gui.create("WIPFMControlsMenu",ctrlsParent,0,0,ctrlsParent:GetWidth(),ctrlsParent:GetHeight())
	crtl:SetAutoAlignToParent(true,false)
	crtl:SetAutoFillContentsToHeight(false)

	local singleAxis
	local minLimits,maxLimits
	local function add_rotation_axis_slider(name,axisId,min,defVal)
		crtl:AddSliderControl("Rot " .. name,"rot_" .. name,defVal,-180.0,180.0,function(el,value)
			local animatedC = ent:GetComponent(ents.COMPONENT_ANIMATED)
			if(animatedC ~= nil) then
				local ref = mdl:GetReferencePose()
				local pose = ref:GetBonePose(parent:GetID()):GetInverse() *ref:GetBonePose(boneId)
				local rot = pose:GetRotation():ToEulerAngles()
				local tAxisId = singleAxis or axisId
				rot:Set(tAxisId,rot:Get(tAxisId) +value)
				pose:SetRotation(rot)
				ent:RemoveComponent(ents.COMPONENT_IK_SOLVER)
				ent:RemoveComponent(ents.COMPONENT_PFM_FBIK)

				util.remove(self.m_cbOnAnimsUpdated)
				self.m_cbOnAnimsUpdated = ent:GetComponent(ents.COMPONENT_ANIMATED):AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()

					animatedC:SetBonePose(boneId,pose)
				end)

				self.m_mdlView:Render()

				if(min) then minLimits:Set(singleAxis and 0 or tAxisId,value)
				else maxLimits:Set(singleAxis and 0 or tAxisId,value) end
				constraint.minLimits = minLimits
				constraint.maxLimits = maxLimits
				--self:ReloadIkRig()
			end
		end,0.01)
	end

	if(type == "fixed") then constraint = self.m_ikRig:AddFixedConstraint(parent:GetName(),bone:GetName())
	elseif(type == "hinge") then constraint = self.m_ikRig:AddHingeConstraint(parent:GetName(),bone:GetName(),-90.0,90.0)
	elseif(type == "ballSocket") then constraint = self.m_ikRig:AddBallSocketConstraint(parent:GetName(),bone:GetName(),EulerAngles(-90,-90,-0.5),EulerAngles(90,90,0.5)) end
	pfm.log("Adding " .. type .. " constraint from bone '" .. parent:GetName() .. "' to '" .. bone:GetName() .. "' of actor with model '" .. mdl:GetName() .. "'...",pfm.LOG_CATEGORY_PFM)

	local function add_rotation_axis(name,axisId,defMin,defMax)
		add_rotation_axis_slider(name .. " min",axisId,true,defMin)
		add_rotation_axis_slider(name .. " max",axisId,false,defMax)
	end
	if(type == "ballSocket") then
		minLimits = EulerAngles()
		maxLimits = EulerAngles()
		add_rotation_axis("pitch",0,-90,90)
		add_rotation_axis("yaw",1,-90,90)
		add_rotation_axis("roll",2,-0.5,0.5)
	elseif(type == "hinge") then
		singleAxis = 0
		minLimits = EulerAngles()
		maxLimits = EulerAngles()
		crtl:AddDropDownMenu("axis","axis",{
			{"x",locale.get_text("x")},
			{"y",locale.get_text("y")},
			{"z",locale.get_text("z")}
		},0,function(el,option)
			singleAxis = el:GetSelectedOption()
		end)
		add_rotation_axis("angle",nil,-90,90)
	end
	crtl:ResetControls()
	crtl:Update()
	crtl:SizeToContents()
	--crtl:AddFileEntry(locale.get_text("pfm_impostee_model"),"impostee_model","",function(resultHandler) end)
	--[[local ctrlsParent = child:AddItem("")
	local crtl = gui.create("WIPFMControlsMenu",ctrlsParent,0,0,ctrlsParent:GetWidth(),ctrlsParent:GetHeight())
	crtl:SetAutoAlignToParent(true,false)
	crtl:AddSliderControl(locale.get_text("roughness"),"roughness",0.0,0.0,1.0,function(el,value) end,0.01)
	--crtl:AddFileEntry(locale.get_text("pfm_impostee_model"),"impostee_model","",function(resultHandler) end)
]]




	--[[local menu = gui.create("WIDropDownMenu",child)
	for _,option in pairs(self.m_dstFlexControllerOptions) do menu:AddOption(option[2],option[1]) end -- TODO: Don't add option that is already taken!
	local wrapper = menu:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text("controller"))
	wrapper:SetSize(child:GetWidth(),20)
	wrapper:SetAnchor(0,0,1,0)
	wrapper:SetUseAltMode(true)]]

	self:ReloadIkRig()
	return constraint
end
function Element:AddBallSocketConstraint(item,boneName)
	return self:AddConstraint(item,boneName,"ballSocket")
end
function Element:AddHingeConstraint(item,boneName)
	return self:AddConstraint(item,boneName,"hinge")
end
function Element:AddFixedConstraint(item,boneName)
	return self:AddConstraint(item,boneName,"fixed")
end
function Element:ReloadIkRig()
	local entActor = self.m_mdlView:GetEntity(1)
	local pfmFbIkC = entActor:AddComponent("pfm_fbik")
	local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if(ikSolverC == nil) then return end
	ikSolverC:ResetIkRig() -- Clear Rig
	ikSolverC:AddIkSolverByRig(self.m_ikRig)
end
function Element:CreateTransformGizmo()
	local selectedElements = self.m_skelTree:GetSelectedElements()
	local selectedItem = pairs(selectedElements)(selectedElements)
	util.remove(self.m_entTransformGizmo)
	if(util.is_valid(selectedItem) == false) then return end
	local boneName = selectedItem:GetIdentifier()
	if(self.m_ikRig:HasControl(boneName) == false) then return end
	local entTransform = ents.create("util_transform")
	self.m_entTransformGizmo = entTransform
	entTransform:Spawn()

	local entActor = self.m_mdlView:GetEntity(1)
	if(util.is_valid(entActor)) then entTransform:SetPos(entActor:GetPos()) end
	local trC = entTransform:GetComponent("util_transform")
	util.remove(self.m_trOnGizmoControlAdded)
	self.m_trOnGizmoControlAdded = trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_GIZMO_CONTROL_ADDED,function(ent)
		ent:RemoveFromScene(game.get_scene())
		ent:AddToScene(self.m_mdlView:GetScene())
	end)
	if(trC ~= nil) then
		trC:SetTranslationEnabled(true)
		trC:SetRotationEnabled(false)
		trC:SetScaleEnabled(false)

		local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
		local memberPath = "control/" .. boneName .. "/position"
		local pos = ikSolverC:GetMemberValue(memberPath)
		local localPose = math.Transform(pos)
		local pose = entActor:GetPose()
		entTransform:SetPose(pose *localPose)
		self.m_mdlView:Render()
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,function(pos)
			self.m_mdlView:Render()
			local absPose = math.Transform(pos)
			local localPose = entActor:GetPose():GetInverse() *absPose
			ikSolverC:SetMemberValue(memberPath,localPose:GetOrigin())
		end)
		--[[utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function(rot)
			local localRot = rot:Copy()
			if(animC ~= nil) then
				local pose = animC:GetGlobalBonePose(boneId)
				pose:SetRotation(rot)
				animC:SetGlobalBonePose(boneId,pose)

				localRot = animC:GetBoneRot(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED,{boneId,rot,localRot})
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED,function(scale)
			if(animC ~= nil) then
				local pose = animC:GetGlobalBonePose(boneId)
				pose:SetScale(scale)
				animC:SetGlobalBonePose(boneId,pose)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED,{boneId,scale,scale})
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END,function()
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_TRANSFORM_END)
		end)]]
	end

	entTransform:RemoveFromScene(game.get_scene())
	entTransform:AddToScene(self.m_mdlView:GetScene())
	trC:SetCamera(self.m_mdlView:GetCamera())
end
function Element:UpdateModelView()
	self.m_tUpdateModelView = time.real_time()
end
function Element:OnThink()
	if(time.real_time() -self.m_tUpdateModelView < 0.25) then
		if(util.is_valid(self.m_modelView)) then self.m_modelView:Render() end
	end
end
function Element:SetModelView(mdlView) self.m_mdlView = mdlView end
function Element:UpdateRetargetComponent()
	if(util.is_valid(self.m_mdlView) == false) then return end
	local entDst = self.m_mdlView:GetEntity(2)
	local retargetC = util.is_valid(entDst) and entDst:AddComponent("retarget_rig") or nil
	if(retargetC == nil) then return end
	retargetC:InitializeRemapTables()
	retargetC:UpdatePoseData()
	retargetC.m_cppCacheData = nil
end
function Element:ApplyBoneTranslation(el,bone)
	if(self.m_rig == nil) then return end
	local boneId = tonumber(el:GetOptionValue(el:GetSelectedOption()))
	self:SetBoneTranslation((boneId ~= -1) and boneId or nil,bone and bone:GetID() or nil)
	self:UpdateModelView()

	self:UpdateRetargetComponent()
end
function Element:GetRig() return self.m_rig end
--[[function Element:ApplyRig()
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
function Element:GetTranslationTable()
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
function Element:GetBoneNames(mdl)
	local boneNames = {}
	local skeleton = mdl:GetSkeleton()
	for _,bone in ipairs(skeleton:GetBones()) do
		table.insert(boneNames,bone:GetName())
	end
	return boneNames
end
function Element:SetSelectedOptions(options)
	self:ResetBoneControls()
	for boneIdDst,boneSrcData in pairs(options) do self:MapBone(boneSrcData[1],boneIdDst,true) end
end
gui.register("WIIkRigEditor",Element)
