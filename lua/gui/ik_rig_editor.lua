-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("pfm/controls_menu/controls_menu.lua")

locale.load("pfm_ik_rig_editor.txt")

include_component("pfm_fbik")

local Element = util.register_class("gui.IkRigEditor", gui.Base)

include("pfm/ik_rig_editor")

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)
	self.m_ikRig = util.IkRigConfig()
	self.m_constraintVisualizers = {}
	self:UpdateModelView()

	local scrollContainer = gui.create("WIScrollContainer", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	scrollContainer:SetContentsWidthFixed(true)

	local controls =
		gui.create("WIPFMControlsMenu", scrollContainer, 0, 0, scrollContainer:GetWidth(), scrollContainer:GetHeight())
	controls:SetAutoFillContentsToHeight(false)
	controls:SetFixedHeight(false)
	self:SetThinkingEnabled(true)
	self.m_controls = controls

	local rootPath = "scripts/ik_rigs/"
	local fe = controls:AddFileEntry(locale.get_text("pfm_ik_rig_file"), "ik_rig", "", function(resultHandler)
		local path = tool.get_filmmaker():GetFileDialogPath("ik_rig_path")
		local pFileDialog
		pFileDialog = pfm.create_file_open_dialog(function(el, fileName)
			if fileName == nil then
				return
			end
			local rigPath = rootPath .. fileName
			local rig = util.IkRigConfig.load(rigPath)
			if rig == nil then
				self:LogErr("Failed to load ik rig '" .. rigPath .. "'!")
				return
			end

			self:LoadRig(rig)
			tool.get_filmmaker()
				:SetFileDialogPath("ik_rig_path", file.get_file_path(pFileDialog:MakePathRelative(rigPath)))
		end)
		pFileDialog:SetRootPath(rootPath)
		pFileDialog:SetExtensions(util.IkRigConfig.get_supported_extensions())
		if path ~= nil then
			pFileDialog:SetPath(path)
		end
		pFileDialog:Update()
	end)

	local feModel
	feModel = controls:AddFileEntry(
		locale.get_text("pfm_ik_rig_reference_model"),
		"reference_model",
		"",
		function(resultHandler)
			local pFileDialog = pfm.create_file_open_dialog(function(el, fileName)
				if fileName == nil then
					return
				end
				resultHandler(el:GetFilePath(true))
			end)
			pFileDialog:SetRootPath("models")
			pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MODEL))
			pFileDialog:Update()
		end
	)
	feModel:AddCallback("OnValueChanged", function(...)
		if self.m_skipButtonCallbacks then
			return
		end
		self:ReloadBoneList(feModel)
	end)
	self.m_feModel = feModel

	local pOptionMirrored = controls:AddToggleControl(
		locale.get_text("mirrored"),
		"mirrored",
		true,
		function(el, checked)
			self:SetMirrored(checked)
		end
	)
	self.m_mirrored = true

	local el, wrapper = controls:AddDropDownMenu(
		locale.get_text("pfm_show_bones"),
		"show_bones",
		{ { "0", locale.get_text("disabled") }, { "1", locale.get_text("enabled") } },
		"0",
		function(el)
			self:UpdateBoneVisibility()
		end
	)
	self.m_elShowBones = el
	wrapper:SetVisible(false)

	controls:AddButton(locale.get_text("save"), "save", function()
		local rig = self:GetRig()
		if rig == nil then
			return
		end
		local path = tool.get_filmmaker():GetFileDialogPath("ik_rig_path")
		local pFileDialog
		pFileDialog = pfm.create_file_save_dialog(function(pDialoge, fileName)
			if fileName == nil then
				return
			end
			fileName = file.remove_file_extension(fileName, { "pikr", "pikr_b" })
			local ikRigPath = "scripts/ik_rigs/" .. fileName .. ".pikr"
			local res, err = rig:Save(ikRigPath)
			if res == false then
				self:LogErr("Failed to save ik rig: " .. err)
			end
			tool.get_filmmaker()
				:SetFileDialogPath("ik_rig_path", file.get_file_path(pFileDialog:MakePathRelative(ikRigPath)))
		end)
		pFileDialog:SetRootPath("scripts/ik_rigs/")
		if path ~= nil then
			pFileDialog:SetPath(path)
		end
		pFileDialog:Update()
	end)

	controls:ResetControls()
end
function Element:SetReferenceModel(mdl)
	self.m_feModel:SetValue(mdl)
end
function Element:SetMirrored(mirrored)
	self.m_mirrored = mirrored
end
function Element:IsMirrored()
	return self.m_mirrored
end
function Element:FindBoneItem(boneName)
	return self.m_skelTree:GetRoot():GetItemByIdentifier(boneName, true)
end
function Element:DetermineMirroredBoneSibling(name)
	local mdl = self:GetModel()
	if mdl == nil then
		return
	end
	local skeleton = mdl:GetSkeleton()
	local lnameToActualName = {}
	for _, bone in ipairs(skeleton:GetBones()) do
		lnameToActualName[bone:GetName():lower()] = bone:GetName()
	end

	local lname = name:lower()
	local function check_candidate(identifier, identifierOther)
		local pos = lname:find(identifier)
		if pos ~= nil then
			local otherName = lname:sub(0, pos - 1) .. identifierOther .. lname:sub(pos + #identifier)
			if lnameToActualName[otherName] ~= nil then
				return lnameToActualName[otherName]
			end
		end
	end
	local candidate = check_candidate("left", "right")
	candidate = candidate or check_candidate("right", "left")
	candidate = candidate or check_candidate("_l_", "_r_")
	candidate = candidate or check_candidate("_r_", "_l_")
	candidate = candidate or check_candidate("_l", "_r")
	candidate = candidate or check_candidate("r_", "l_")
	return candidate
end
function Element:LoadRig(rig)
	local isMirrored = self:IsMirrored()
	self:SetMirrored(false)
	self:Clear()
	self:ReloadBoneList(self.m_feModel)

	-- We don't actually use the loaded rig, we just use it to re-create it
	self.m_ikRig = util.IkRigConfig()
	for _, c in ipairs(rig:GetConstraints()) do
		local item = self:FindBoneItem(c.bone1)
		if util.is_valid(item) then
			if c.type == util.IkRigConfig.Constraint.TYPE_FIXED then
				local constraint, ctrl = self:AddFixedConstraint(item, c.bone1, c)
			elseif c.type == util.IkRigConfig.Constraint.TYPE_HINGE then
				local constraint, ctrl = self:AddHingeConstraint(item, c.bone1, c)
				ctrl:GetControl("axis"):SelectOption(c.axis)
				ctrl:GetControl("angle_min"):SetValue(c.minLimits.p)
				ctrl:GetControl("angle_max"):SetValue(c.maxLimits.p)
			elseif c.type == util.IkRigConfig.Constraint.TYPE_BALL_SOCKET then
				local constraint, ctrl = self:AddBallSocketConstraint(item, c.bone1, c)
				ctrl:GetControl("twist_axis"):SelectOption(c.axis)
				ctrl:GetControl("rotation_axes"):GetControl("pitch_min"):SetValue(c.minLimits.p)
				ctrl:GetControl("rotation_axes"):GetControl("yaw_min"):SetValue(c.minLimits.y)
				ctrl:GetControl("rotation_axes"):GetControl("roll_min"):SetValue(c.minLimits.r)

				ctrl:GetControl("rotation_axes"):GetControl("pitch_max"):SetValue(c.maxLimits.p)
				ctrl:GetControl("rotation_axes"):GetControl("yaw_max"):SetValue(c.maxLimits.y)
				ctrl:GetControl("rotation_axes"):GetControl("roll_max"):SetValue(c.maxLimits.r)
			end
		end
	end
	for _, c in ipairs(rig:GetControls()) do
		local item = self:FindBoneItem(c.bone)
		if util.is_valid(item) then
			local control, ctrl = self:AddControl(item, c.bone, c.type)
			ctrl:GetControl("rigidity"):SetValue(c.rigidity)
		end
	end
	for _, bone in ipairs(rig:GetBones()) do
		self:SetBoneLocked(bone.name, bone.locked)
	end
	self:ScheduleReloadIkRig()
	self:SetMirrored(isMirrored)
end
function Element:GetModel()
	if util.is_valid(self.m_modelView) == false or self.m_mdl == nil then
		return
	end
	local ent = self.m_modelView:GetEntity(1)
	if util.is_valid(ent) == false then
		return
	end
	return ent:GetModel()
end
function Element:UpdateMode()
	if util.is_valid(self.m_modelView) == false or self.m_mdl == nil then
		return
	end
	local ent = self.m_modelView:GetEntity(1)
	if util.is_valid(ent) == false then
		return
	end
	local mdl = ent:GetModel()
	if mdl == nil then
		return
	end

	local vc = self.m_modelView:GetViewerCamera()
	if util.is_valid(vc) then
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
	if util.is_valid(self.feModel) then
		self.feModel:SetValue(impostee)
	end
end
function Element:OnRemove()
	self:UnlinkFromModelView()
	util.remove(self.m_entTransformGizmo)
	util.remove(self.m_trOnGizmoControlAdded)
	util.remove(self.m_cbOnAnimsUpdated)
	util.remove(self.m_constraintVisualizers)
	util.remove(self.m_entDebugVisualizer)
	util.remove(self.m_cbPopulateContextMenu)
end
function Element:OnSizeChanged(w, h)
	if util.is_valid(self.m_controls) then
		self.m_controls:SetWidth(w)
	end
end
function Element:LinkToModelView(mv)
	self.m_modelView = mv
end
function Element:UnlinkFromModelView()
	if util.is_valid(self.m_modelView) == false then
		return
	end
	local mdlView = self.m_modelView
	mdlView:RemoveActor(2)
	local ent = mdlView:GetEntity(1)
	if util.is_valid(ent) then
		ent:SetPos(Vector())
	end
	self.m_modelView = nil
end
function Element:InitializeModelView()
	if util.is_valid(self.m_modelView) == false then
		return
	end
	local ent = self.m_modelView:GetEntity(1)
	if util.is_valid(ent) == false then
		return
	end
	self.m_modelView:SetModel(self.m_mdl)
	self.m_modelView:PlayAnimation("reference", 1)
	util.remove(self.m_cbPopulateContextMenu)
	self.m_cbPopulateContextMenu = self.m_modelView:AddCallback("PopulateContextMenu", function(p, pContext)
		if self:IsValid() == false then
			return
		end
		local ent, c = ents.citerator(ents.COMPONENT_PFM_MANAGER)()
		if c ~= nil then
			local bones = c:GetSelectedBones()
			if #bones == 1 then
				local boneC = bones[1]:GetComponent(ents.COMPONENT_PFM_BONE)
				local mdl = self:GetModel()
				if boneC ~= nil and mdl ~= nil then
					local boneId = boneC:GetBoneId()
					local skeleton = mdl:GetSkeleton()
					local bone = skeleton:GetBone(boneId)
					if bone ~= nil then
						boneC:SetPersistent(true)
						self:PopulateBoneContextMenu(pContext, bone:GetName())

						pContext:AddCallback("OnRemove", function()
							if boneC:IsValid() then
								boneC:SetPersistent(false)
								boneC:SetSelected(false)
							end
							if self:IsValid() then
								self:UpdateBoneEntityStates()
							end
						end)
					end
				end
			end
		end
	end)
	ent:SetColor(Color(255, 255, 255, 200))
	self:UpdateMode()
	return ent
end
function Element:AddBone(name)
	self.m_ikRig:AddBone(name)
	self:UpdateBoneColor(name)
end
function Element:RemoveBone(name)
	self.m_ikRig:RemoveBone(name)
	self:UpdateBoneColor(name)
end
function Element:FindSolverJoint(solver, boneName, type)
	local numJoints = solver:GetJointCount()

	local jointType
	if type == util.IkRigConfig.Constraint.TYPE_BALL_SOCKET then
		jointType = ik.Joint.TYPE_BALL_SOCKET_JOINT
	elseif type == util.IkRigConfig.Constraint.TYPE_HINGE then
		jointType = ik.Joint.TYPE_REVOLUTE_JOINT
	elseif type == util.IkRigConfig.Constraint.TYPE_FIXED then
		jointType = ik.Joint.TYPE_ANGULAR_JOINT
	end

	local bsJoint, bsJointIndex
	for i = 0, numJoints - 1 do
		local joint = solver:GetJoint(i)
		local type = joint:GetType()

		local jointBoneName = joint:GetConnectionB():GetName()
		if jointBoneName == boneName then
			if type == ik.Joint.TYPE_BALL_SOCKET_JOINT then
				bsJoint = joint
				bsJointIndex = i
			end
			return bsJoint, bsJointIndex
		end
	end
end
function Element:GetIkSolver()
	local entActor = self.m_mdlView:GetEntity(1)
	local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	return ikSolverC:GetIkSolver()
end
function Element:ReloadIkRig()
	local entActor = self.m_mdlView:GetEntity(1)
	local pfmFbIkC = entActor:AddComponent("pfm_fbik")
	local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	pfmFbIkC:SetEnabled(true)
	ikSolverC:ResetIkRig() -- Clear Rig
	ikSolverC:SetResetSolver(false)
	ikSolverC:AddIkSolverByRig(self.m_ikRig)

	util.remove(self.m_entDebugVisualizer)
	local entDebugVis = ents.create("entity")
	self.m_entDebugVisualizer = entDebugVis
	local c = entDebugVis:AddComponent("debug_ik_visualizer")
	entDebugVis:Spawn()
	c:SetSolver(ikSolverC:GetIkSolver())
end
function Element:CreateTransformGizmo()
	util.remove(self.m_entTransformGizmo)

	local selectedElements = self.m_skelTree:GetSelectedElements()
	local selectedControlItem
	for selectedItem, _ in pairs(selectedElements) do
		if selectedItem:IsValid() then
			local boneName = selectedItem:GetIdentifier()
			if boneName ~= nil and self.m_ikRig:HasControl(boneName) then
				if selectedControlItem ~= nil then
					return
				end
				selectedControlItem = selectedItem
			end
		end
	end

	if util.is_valid(selectedControlItem) == false then
		return
	end
	local boneName = selectedControlItem:GetIdentifier()
	if self.m_ikRig:HasControl(boneName) == false then
		return
	end
	local entTransform = ents.create("util_transform")
	self.m_entTransformGizmo = entTransform
	local trC = entTransform:GetComponent("util_transform")
	trC:SetAxisGuidesEnabled(false)
	entTransform:Spawn()

	local entActor = self.m_mdlView:GetEntity(1)
	if util.is_valid(entActor) then
		entTransform:SetPos(entActor:GetPos())
	end
	util.remove(self.m_trOnGizmoControlAdded)
	self.m_trOnGizmoControlAdded = trC:AddEventCallback(
		ents.UtilTransformComponent.EVENT_ON_GIZMO_CONTROL_ADDED,
		function(ent)
			ent:RemoveFromScene(game.get_scene())
			ent:AddToScene(self.m_mdlView:GetScene())
		end
	)
	if trC ~= nil then
		trC:SetTranslationEnabled(true)
		trC:SetRotationEnabled(false)
		trC:SetScaleEnabled(false)

		local useLocalSpace = true

		local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
		local memberPath = "control/" .. boneName .. "/position"
		local pos = ikSolverC:GetMemberValue(memberPath)
		local rot = Quaternion()
		if useLocalSpace then
			local animC = entActor:GetComponent(ents.COMPONENT_ANIMATED)
			if animC ~= nil then
				local idx = animC:GetMemberIndex("bone/" .. boneName .. "/rotation")
				if idx ~= nil then
					rot = animC:GetTransformMemberRot(idx, math.COORDINATE_SPACE_OBJECT) or rot
				end
			end
		end

		local localPose = math.Transform(pos, rot)
		local pose = entActor:GetPose()
		entTransform:SetPose(pose * localPose)

		if useLocalSpace then
			trC:SetSpace(ents.TransformController.SPACE_LOCAL)
			trC:SetReferenceEntity(ent)
		end

		self.m_mdlView:Render()
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED, function(pos)
			self.m_mdlView:Render()
			local absPose = math.Transform(pos)
			local localPose = entActor:GetPose():GetInverse() * absPose
			ikSolverC:SetMemberValue(memberPath, localPose:GetOrigin())
		end)
		--[[utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function(rot)
			local localRot = rot:Copy()
			if(animC ~= nil) then
				local pose = animC:GetBonePose(boneId,math.COORDINATE_SPACE_WORLD)
				pose:SetRotation(rot)
				animC:SetBonePose(boneId,posemath.COORDINATE_SPACE_WORLD)

				localRot = animC:GetBoneRot(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED,{boneId,rot,localRot})
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED,function(scale)
			if(animC ~= nil) then
				local pose = animC:GetBonePose(boneId,math.COORDINATE_SPACE_WORLD)
				pose:SetScale(scale)
				animC:SetBonePose(boneId,posemath.COORDINATE_SPACE_WORLD)
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
function Element:ScheduleReloadIkRig()
	self.m_ikRigReloadScheduled = true
	self:ScheduleUpdateDebugVisualization()
end
function Element:ScheduleUpdateDebugVisualization()
	self.m_ikRigReloadScheduled = true
	self.m_updateDebugVisScheduled = true
end
function Element:OnThink()
	if time.real_time() - self.m_tUpdateModelView < 0.25 then
		if util.is_valid(self.m_modelView) then
			self.m_modelView:Render()
		end
	end
	if self.m_ikRigReloadScheduled then
		self.m_ikRigReloadScheduled = nil
		self:ReloadIkRig()
		self:UpdateBoneEntityStates()
	end
	if self.m_updateDebugVisScheduled then
		self.m_updateDebugVisScheduled = nil
		self:UpdateDebugVisualization()
	end
end
function Element:SetModelView(mdlView)
	self.m_mdlView = mdlView
end
function Element:GetRig()
	return self.m_ikRig
end
gui.register("WIIkRigEditor", Element)
