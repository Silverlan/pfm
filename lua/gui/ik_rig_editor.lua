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

	local rootPath = "scripts/ik_rigs"
	local fe = controls:AddFileEntry(locale.get_text("pfm_ik_rig_file"),"ik_rig","",function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			local rig = ents.IkSolverComponent.RigConfig.load(rootPath .. fileName)
			if(rig == nil) then
				pfm.log("Failed to load ik rig '" .. rootPath .. fileName .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
				return
			end

			self:LoadRig(rig)
		end)
		pFileDialog:SetRootPath(rootPath)
		pFileDialog:SetExtensions(ents.IkSolverComponent.RigConfig.get_supported_extensions())
		pFileDialog:Update()
	end)

	local feModel
	feModel = controls:AddFileEntry(locale.get_text("pfm_ik_rig_reference_model"),"reference_model","",function(resultHandler)
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
		self:ReloadBoneList(feModel)
	end)
	self.m_feModel = feModel

	local el,wrapper = controls:AddDropDownMenu(locale.get_text("pfm_show_bones"),"show_bones",{{"0",locale.get_text("disabled")},{"1",locale.get_text("enabled")}},"0",function(el)
		self:UpdateBoneVisibility()
	end)
	self.m_elShowBones = el

	controls:AddButton(locale.get_text("save"),"save",function()
		local rig = self:GetRig()
		if(rig == nil) then return end
		local pFileDialog = gui.create_file_save_dialog(function(pDialoge,fileName)
			if(fileName == nil) then return end
			fileName = file.remove_file_extension(fileName,{"pikr","pikr_b"})
			local res,err = rig:Save("scripts/ik_rigs/" .. fileName .. ".pikr")
			if(res == false) then
				pfm.log("Failed to save ik rig: " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
			end
		end)
		pFileDialog:SetRootPath("scripts/ik_rigs/")
		pFileDialog:Update()
	end)

	controls:ResetControls()
end
function Element:LoadRig(rig)
	self:Clear()
	self:ReloadBoneList(self.m_feModel)

	self.m_ikRig = rig
	for _,c in ipairs(rig:GetConstraints()) do
		local item = self.m_skelTree:GetRoot():GetItemByIdentifier(c.bone1,true)
		if(util.is_valid(item)) then
			if(c.type == ents.IkSolverComponent.RigConfig.Constraint.TYPE_FIXED) then
				self:AddFixedConstraint(item,c.bone1,c)
			elseif(c.type == ents.IkSolverComponent.RigConfig.Constraint.TYPE_HINGE) then
				self:AddHingeConstraint(item,c.bone1,c)
			elseif(c.type == ents.IkSolverComponent.RigConfig.Constraint.TYPE_BALL_SOCKET) then
				self:AddBallSocketConstraint(item,c.bone1,c)
			end
		end
	end
	self:ReloadIkRig()
end
function Element:UpdateMode()
	if(util.is_valid(self.m_modelView) == false or self.m_mdl == nil) then return end
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end

	local vc = self.m_modelView:GetViewerCamera()
	if(util.is_valid(vc)) then
		vc:FitViewToScene()
	end

	self.m_boneControlMenu:SetVisible(true)
	self.m_modelView:Render()

	self:UpdateBoneVisibility()
end
function Element:Clear()
	self.m_skelTree:Clear()
end
function Element:SetModel(impostee)
	if(util.is_valid(self.feModel)) then self.feModel:SetValue(impostee) end
end
function Element:ReloadBoneList(feModel)
	local pathMdl = feModel:GetValue()
	if(#pathMdl == 0) then return end
	local mdl = game.load_model(pathMdl)
	if(mdl == nil) then return end
	self.m_mdl = mdl
	self.m_ikRig = ents.IkSolverComponent.RigConfig()

	self:AddBoneList()
	if(util.is_valid(self.m_mdlView)) then
		self:LinkToModelView(self.m_mdlView)
		self:InitializeModelView()
	end
	self:UpdateMode()

	self.m_modelView:SetAlwaysRender(true)
	if(util.is_valid(self.m_mdlView)) then
		local ent = self.m_mdlView:GetEntity(1)
		if(util.is_valid(ent)) then
			ent:RemoveComponent("click")
			ent:RemoveComponent("bvh")
			ent:RemoveComponent("pfm_skeleton")

			ent:AddComponent("click")
			ent:AddComponent("bvh")
			ent:AddComponent("pfm_skeleton")
		end
	end
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

	util.remove(self.m_rigControls)
	self.m_rigControls = self.m_controls:AddSubMenu()
	self.m_boneControlMenu = self.m_rigControls:AddSubMenu()
	self:InitializeBoneControls(mdl)

	gui.create("WIBase",self.m_rigControls) -- Dummy
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
function Element:UpdateBoneColor(name)
	local item = self.m_skelTree:GetRoot():GetItemByIdentifier(name,true)
	if(util.is_valid(item) == false) then return end
	local te = item:GetTextElement()
	if(self.m_ikRig:HasBone(name) == false) then
		te:SetColor(Color(100,100,100))
		return
	end
	local bone = self.m_ikRig:FindBone(name)
	if(bone.locked) then
		te:SetColor(Color.Red)
		return
	end
	te:SetColor(Color.White)
end
function Element:AddBone(name)
	self.m_ikRig:AddBone(name)
	self:UpdateBoneColor(name)
end
function Element:RemoveBone(name)
	self.m_ikRig:RemoveBone(name)
	self:UpdateBoneColor(name)
end
function Element:InitializeBoneControls(mdl)
	local options = {}
	table.insert(options,{"none","-"})
	table.insert(options,{"hinge",locale.get_text("pfm_constraint_hinge")})
	table.insert(options,{"ballsocket",locale.get_text("pfm_constraint_ball_socket")})

	util.remove(self.m_skelTreeSubMenu)
	local subMenu = self.m_boneControlMenu:AddSubMenu()
	self.m_skelTreeSubMenu = subMenu
	local tree = gui.create("WIPFMTreeView",subMenu,0,0,subMenu:GetWidth(),20)
	self.m_skelTree = tree
	tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	local bones = get_bones_in_hierarchical_order(mdl)
	for _,boneInfo in ipairs(bones) do
		local boneDst = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. boneDst:GetName()

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
					pContext:AddItem(locale.get_text("pfm_add_fixed_constraint"),function()
						self:AddFixedConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem(locale.get_text("pfm_add_hinge_constraint"),function()
						self:AddHingeConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem(locale.get_text("pfm_add_ball_socket_constraint"),function()
						self:AddBallSocketConstraint(item,boneDst:GetName())
					end)
					if(self.m_ikRig:HasBone(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_remove_bone"),function()
							self:RemoveBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem(locale.get_text("pfm_add_bone"),function()
							self:AddBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					end
					if(self.m_ikRig:IsBoneLocked(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_unlock_bone"),function()
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),false)
							self:ReloadIkRig()
							self:UpdateBoneColor(boneDst:GetName())
						end)
					else
						pContext:AddItem(locale.get_text("pfm_lock_bone"),function()
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),true)
							self:ReloadIkRig()
							self:UpdateBoneColor(boneDst:GetName())
						end)
					end
					if(self.m_ikRig:HasControl(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_remove_control"),function()
							self.m_ikRig:RemoveControl(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem(locale.get_text("pfm_add_drag_control"),function()
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_DRAG)
							self:ReloadIkRig()
						end)
						pContext:AddItem(locale.get_text("pfm_add_state_control"),function()
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_STATE)
							self:ReloadIkRig()
						end)
					end
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)
		self:UpdateBoneColor(boneDst:GetName())
	end
	self.m_boneControlMenu:ResetControls()
end
function Element:AddConstraint(item,boneName,type,constraint)
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(boneName)
	local bone = skel:GetBone(boneId)
	local parent = bone:GetParent()
	self:AddBone(boneName)
	self:AddBone(parent:GetName())

	local child = item:AddItem(locale.get_text("pfm_" .. type .. "_constraint"))
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
	local ctrl = gui.create("WIPFMControlsMenu",ctrlsParent,0,0,ctrlsParent:GetWidth(),ctrlsParent:GetHeight())
	ctrl:SetAutoAlignToParent(true,false)
	ctrl:SetAutoFillContentsToHeight(false)

	local singleAxis
	local minLimits,maxLimits
	local useUnidirectionalSpan = false
	local includeUnidirectionalLimit = false
	local twistAxis = math.AXIS_Z
	if(type == "ballSocket") then twistAxis = ents.IkSolverComponent.find_forward_axis(mdl,parent:GetID(),boneId) or twistAxis end
	local function add_rotation_axis_slider(ctrl,id,name,axisId,min,defVal)
		return ctrl:AddSliderControl(locale.get_text(name),id,defVal,-180.0,180.0,function(el,value)
			local animatedC = ent:GetComponent(ents.COMPONENT_ANIMATED)
			if(animatedC ~= nil) then
				local ref = mdl:GetReferencePose()
				local pose = ref:GetBonePose(parent:GetID()):GetInverse() *ref:GetBonePose(boneId)
				local rot = pose:GetRotation()
				local tAxisId = singleAxis or axisId
				local localRot = EulerAngles()
				localRot:Set(tAxisId,value)
				if(useUnidirectionalSpan) then
					if(includeUnidirectionalLimit) then
						if(min) then localRot = minLimits
						else localRot = maxLimits end
					else
						localRot = (minLimits +maxLimits) *0.5
					end
				end

				if(twistAxis == math.AXIS_X) then
					localRot = EulerAngles(localRot.y,localRot.r,localRot.p)
				elseif(twistAxis == math.AXIS_Y) then
					localRot = EulerAngles(localRot.r,localRot.p,localRot.y)
				elseif(twistAxis == math.AXIS_Z) then
					
				end
				localRot = localRot:ToQuaternion()

				rot = rot *localRot
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
			end
		end,1.0)
	end

	if(constraint == nil) then
		pfm.log("Adding " .. type .. " constraint from bone '" .. parent:GetName() .. "' to '" .. bone:GetName() .. "' of actor with model '" .. mdl:GetName() .. "'...",pfm.LOG_CATEGORY_PFM)
		if(type == "fixed") then constraint = self.m_ikRig:AddFixedConstraint(parent:GetName(),bone:GetName())
		elseif(type == "hinge") then constraint = self.m_ikRig:AddHingeConstraint(parent:GetName(),bone:GetName(),-90.0,90.0,Quaternion())
		elseif(type == "ballSocket") then
			local limits = EulerAngles(90,90,90)
			-- Set the rotation around the twist axis to -0.5/0.5
			if(twistAxis == math.AXIS_X) then
				limits.y = 0.5
			elseif(twistAxis == math.AXIS_Y) then
				limits.p = 0.5
			else
				limits.r = 0.5
			end
			constraint = self.m_ikRig:AddBallSocketConstraint(parent:GetName(),bone:GetName(),-limits,limits)
		end
	end
	minLimits = constraint.minLimits
	maxLimits = constraint.maxLimits

	local function add_rotation_axis(ctrl,name,axisId,defMin,defMax)
		local minSlider = add_rotation_axis_slider(ctrl,"pfm_ik_rot_" .. name .. "_min",name .. " min",axisId,true,defMin)
		local maxSlider = add_rotation_axis_slider(ctrl,"pfm_ik_rot_" .. name .. "_max",name .. " max",axisId,false,defMax)
		return minSlider,maxSlider
	end
	if(type == "ballSocket") then
		local axes
		local function update_axes()
			if(twistAxis == math.AXIS_X) then
				axes = {math.AXIS_X,math.AXIS_Z,math.AXIS_Y}
			elseif(twistAxis == math.AXIS_Y) then
				axes = {math.AXIS_Z,math.AXIS_Y,math.AXIS_X}
			else
				axes = {math.AXIS_X,math.AXIS_Y,math.AXIS_Z}
			end
		end
		update_axes()

		ctrl:AddDropDownMenu(locale.get_text("pfm_ik_twist_axis"),"twist_axis",{
			{tostring(math.AXIS_X),"X"},
			{tostring(math.AXIS_Y),"Y"},
			{tostring(math.AXIS_Z),"Z"}
		},twistAxis,function(el,option)
			local axis = el:GetOptionValue(el:GetSelectedOption())
			twistAxis = tonumber(axis)
			constraint.axis = twistAxis
			update_axes()
		end)

		local subSeparate
		--[[local subUnidirectional
		local unidirectionalSwingSpan = ((math.abs(maxLimits:Get(axes[1]) -minLimits:Get(axes[1])) -math.abs(maxLimits:Get(axes[2]) -minLimits:Get(axes[2]))) < 0.01)
		ctrl:AddToggleControl(locale.get_text("pfm_ik_unidirectional_span_limit"),"unidirectional_span_limit",unidirectionalSwingSpan,function(el,checked)
			subSeparate:SetVisible(not checked)
			subUnidirectional:SetVisible(checked)
			ctrl:Update()
			ctrl:SizeToContents()

			useUnidirectionalSpan = checked
		end)]]
		subSeparate = ctrl:AddSubMenu()
		--subUnidirectional = ctrl:AddSubMenu()

		local minP,maxP = add_rotation_axis(subSeparate,"pitch",0,minLimits.p,maxLimits.p)
		local minY,maxY = add_rotation_axis(subSeparate,"yaw",1,minLimits.y,maxLimits.y)
		local minR,maxR = add_rotation_axis(subSeparate,"roll",2,minLimits.r,maxLimits.r)
		local pairs = {
			{minP,maxP},
			{minY,maxY},
			{minR,maxR}
		}
		for _,p in ipairs(pairs) do
			p[1]:AddCallback("OnLeftValueChanged",function()
				if(input.is_shift_key_down()) then
					p[2]:SetValue(-p[1]:GetValue())
				end
			end)
			p[2]:AddCallback("OnLeftValueChanged",function()
				if(input.is_shift_key_down()) then
					p[1]:SetValue(-p[2]:GetValue())
				end
			end)
		end

		--[[local function get_min_slider(axis)
			if(axis == math.AXIS_X) then return minP end
			if(axis == math.AXIS_Y) then return minY end
			if(axis == math.AXIS_Z) then return minR end
		end
		local function get_max_slider(axis)
			if(axis == math.AXIS_X) then return maxP end
			if(axis == math.AXIS_Y) then return maxY end
			if(axis == math.AXIS_Z) then return maxR end
		end

		local xOffset,yOffset,spanLimit,twistLimit

		local function update_x_span(includeUniLimit)
			if(includeUniLimit == nil) then includeUniLimit = false end
			local xOffsetVal = xOffset:GetValue()
			local spanLimitVal = spanLimit:GetValue()
			local min = xOffsetVal -spanLimitVal *0.5
			local max = xOffsetVal +spanLimitVal *0.5
			includeUnidirectionalLimit = includeUniLimit
			get_min_slider(axes[1]):SetValue(min)
			includeUnidirectionalLimit = includeUniLimit
			get_max_slider(axes[1]):SetValue(max)
		end
		local function update_y_span(includeUniLimit)
			if(includeUniLimit == nil) then includeUniLimit = false end
			local yOffsetVal = yOffset:GetValue()
			local spanLimitVal = spanLimit:GetValue()
			local min = yOffsetVal -spanLimitVal *0.5
			local max = yOffsetVal +spanLimitVal *0.5
			includeUnidirectionalLimit = includeUniLimit
			get_min_slider(axes[2]):SetValue(min)
			includeUnidirectionalLimit = includeUniLimit
			get_max_slider(axes[2]):SetValue(max)
		end
		local function update_twist_span()
			get_min_slider(axes[3]):SetValue(-twistLimit:GetValue())
			get_max_slider(axes[3]):SetValue(twistLimit:GetValue())
		end

		xOffset = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_x_offset"),"rot_x_offset",0,-180.0,180.0,function(el,value)
			update_x_span()
		end)
		yOffset = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_y_offset"),"rot_y_offset",0,-180.0,180.0,function(el,value)
			update_y_span()
		end)
		twistLimit = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_twist_limit"),"rot_twist_limit",0.5,-90.0,90.0,function(el,value)
			update_twist_span()
		end)
		spanLimit = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_span_limit"),"rot_span_limit",90,0.0,90.0,function(el,value)
			update_x_span(true)
			update_y_span(true)
		end)

		subUnidirectional:Update()
		subUnidirectional:SizeToContents()]]
		subSeparate:Update()
		subSeparate:SizeToContents()
	elseif(type == "hinge") then
		singleAxis = 0
		ctrl:AddDropDownMenu(locale.get_text("pfm_ik_axis"),"axis",{
			{"x",locale.get_text("x")},
			{"y",locale.get_text("y")},
			{"z",locale.get_text("z")}
		},0,function(el,option)
			singleAxis = el:GetSelectedOption()
			constraint.axis = singleAxis
		end)
		add_rotation_axis(ctrl,"angle",nil,minLimits.p,maxLimits.p)
	end
	ctrl:ResetControls()
	ctrl:Update()
	ctrl:SizeToContents()

	self:ReloadIkRig()
	return constraint
end
function Element:AddBallSocketConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"ballSocket",c)
end
function Element:AddHingeConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"hinge",c)
end
function Element:AddFixedConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"fixed",c)
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

		local useLocalSpace = true

		local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
		local memberPath = "control/" .. boneName .. "/position"
		local pos = ikSolverC:GetMemberValue(memberPath)
		local rot = Quaternion()
		if(useLocalSpace) then
			local animC = entActor:GetComponent(ents.COMPONENT_ANIMATED)
			if(animC ~= nil) then
				local idx = animC:GetMemberIndex("bone/" .. boneName .. "/rotation")
				if(idx ~= nil) then
					rot = animC:GetTransformMemberRot(idx,math.COORDINATE_SPACE_OBJECT) or rot
				end
			end
		end

		local localPose = math.Transform(pos,rot)
		local pose = entActor:GetPose()
		entTransform:SetPose(pose *localPose)

		if(useLocalSpace) then
			trC:SetSpace(ents.UtilTransformComponent.SPACE_LOCAL)
			trC:SetReferenceEntity(ent)
		end

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
function Element:GetRig() return self.m_ikRig end
gui.register("WIIkRigEditor",Element)
