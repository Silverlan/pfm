--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

gui.PFMViewport.MANIPULATOR_MODE_SELECT = 0
gui.PFMViewport.MANIPULATOR_MODE_MOVE = 1
gui.PFMViewport.MANIPULATOR_MODE_ROTATE = 2
gui.PFMViewport.MANIPULATOR_MODE_SCALE = 3

function gui.PFMViewport:IsMoveManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_MOVE
end
function gui.PFMViewport:IsRotationManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE
end
function gui.PFMViewport:IsScaleManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_SCALE
end
function gui.PFMViewport:GetTransformEntity()
	local c = self:GetTransformWidgetComponent()
	if util.is_valid(c) == false then
		return
	end
	return c:GetEntity()
end
function gui.PFMViewport:GetManipulatorMode()
	return self.m_manipulatorMode
end
function gui.PFMViewport:SetManipulatorMode(manipulatorMode)
	util.remove(self.m_entTransform)
	self.m_manipulatorMode = manipulatorMode
	self.m_btSelect:SetActivated(manipulatorMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT)
	self.m_btMove:SetActivated(self:IsMoveManipulatorMode(manipulatorMode))
	self.m_btRotate:SetActivated(self:IsRotationManipulatorMode(manipulatorMode))
	self.m_btScreen:SetActivated(self:IsScaleManipulatorMode(manipulatorMode))

	if self:UpdateMultiActorSelection() == false then
		local pfm = tool.get_filmmaker()
		local selectionManager = pfm:GetSelectionManager()
		local selectedActors = selectionManager:GetSelectedActors()
		local selectedActorList = {}
		local num = 0
		for ent, b in pairs(selectedActors) do
			table.insert(selectedActorList, ent)
			num = num + 1
		end

		for _, ent in ipairs(selectedActorList) do
			if ent:IsValid() then
				ent:RemoveComponent("util_bone_transform")
				if num == 1 then
					self:UpdateActorManipulation(ent, true)
				end
			end
		end
	end
	self:UpdateManipulationMode()
end
function gui.PFMViewport:GetTransformSpace()
	local transformSpace = self.m_ctrlTransformSpace:GetOptionValue(self.m_ctrlTransformSpace:GetSelectedOption())
	if transformSpace == "global" then
		return ents.UtilTransformComponent.SPACE_WORLD
	elseif transformSpace == "local" then
		return ents.UtilTransformComponent.SPACE_LOCAL
	elseif transformSpace == "view" then
		return ents.UtilTransformComponent.SPACE_VIEW
	end
end
function gui.PFMViewport:GetSnapToGridSpacing()
	return self.m_ctrlSnapToGridSpacing:GetOptionValue(self.m_ctrlSnapToGridSpacing:GetSelectedOption())
end
function gui.PFMViewport:SetSnapToGridSpacing(spacing)
	if spacing == self:GetSnapToGridSpacing() then
		return
	end
	self.m_ctrlSnapToGridSpacing:SelectOption(tostring(spacing))
	pfm.set_snap_to_grid_spacing(spacing)
end
function gui.PFMViewport:GetAngularSpacing()
	return self.m_ctrlAngularSpacing:GetOptionValue(self.m_ctrlAngularSpacing:GetSelectedOption())
end
function gui.PFMViewport:SetAngularSpacing(spacing)
	if spacing == self:GetAngularSpacing() then
		return
	end
	self.m_ctrlAngularSpacing:SelectOption(tostring(spacing))
	pfm.set_angular_spacing(spacing)
end
function gui.PFMViewport:SetTransformSpace(transformSpace)
	if transformSpace == ents.UtilTransformComponent.SPACE_WORLD then
		self.m_ctrlTransformSpace:SelectOption("global")
	elseif transformSpace == ents.UtilTransformComponent.SPACE_LOCAL then
		self.m_ctrlTransformSpace:SelectOption("local")
	elseif transformSpace == ents.UtilTransformComponent.SPACE_VIEW then
		self.m_ctrlTransformSpace:SelectOption("view")
	end
	self:ReloadManipulatorMode()
end
function gui.PFMViewport:ReloadManipulatorMode()
	self:SetManipulatorMode(self:GetManipulatorMode())
end
function gui.PFMViewport:InitializeTransformWidget(tc, ent, applySpace)
	if applySpace == nil then
		applySpace = true
	end
	local manipMode = self:GetManipulatorMode()
	if selected == false or manipMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT then
		-- ent:RemoveComponent("util_transform")
	elseif tc ~= nil then
		if self:IsMoveManipulatorMode(manipMode) then
			tc:SetTranslationEnabled(true)
			tc:SetRotationEnabled(false)
			tc:SetScaleEnabled(false)
		elseif self:IsRotationManipulatorMode(manipMode) then
			tc:SetTranslationEnabled(false)
			tc:SetRotationEnabled(true)
			tc:SetScaleEnabled(false)
		elseif self:IsScaleManipulatorMode(manipMode) then
			tc:SetTranslationEnabled(false)
			tc:SetRotationEnabled(false)
			tc:SetScaleEnabled(true)
		end
	end

	if util.is_valid(tc) and applySpace then
		local transformSpace = self:GetTransformSpace()
		if self:IsScaleManipulatorMode(manipMode) then
			transformSpace = ents.UtilTransformComponent.SPACE_LOCAL
		end
		tc:SetSpace(transformSpace)

		if transformSpace == ents.UtilTransformComponent.SPACE_WORLD then
			tc:SetReferenceEntity()
		elseif transformSpace == ents.UtilTransformComponent.SPACE_LOCAL then
			tc:SetReferenceEntity(ent)
		elseif transformSpace == ents.UtilTransformComponent.SPACE_VIEW then
			local camC = self:GetActiveCamera()
			if util.is_valid(camC) then
				tc:SetReferenceEntity(camC:GetEntity())
			end
		end
	end
	tc:UpdateAxes()
end
function gui.PFMViewport:UpdateManipulationMode()
	local manipMode = self:GetManipulatorMode()
	if
		self:IsMoveManipulatorMode(manipMode) == false
		and self:IsRotationManipulatorMode(manipMode) == false
		and self:IsScaleManipulatorMode(manipMode) == false
	then
		return
	end
	local pm = tool.get_filmmaker()
	local selectionManager = pm:GetSelectionManager()
	local selectedActors = selectionManager:GetSelectedActors()
	local selectedActorList = {}
	for ent, b in pairs(selectedActors) do
		table.insert(selectedActorList, ent)
	end
	if #selectedActorList ~= 1 or util.is_valid(selectedActorList[1]) == false then
		return
	end

	local boneName
	-- Check if a bone is selected
	local actorEditor = pm:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end
	local actor = selectedActorList[1]
	local actorC = util.is_valid(actor) and actor:GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
	local actorData = util.is_valid(actorC) and actorC:GetActorData() or nil
	if actorData ~= nil then
		local itemSkeleton = actorEditor:GetActorComponentItem(actorData, "animated")
		if itemSkeleton ~= nil then
			for _, item in ipairs(itemSkeleton:GetItems()) do
				if item:IsValid() and item:GetIdentifier() == "bone" then
					for _, boneItem in ipairs(item:GetItems()) do
						if boneItem:IsValid() then
							for _, boneSubItem in ipairs(boneItem:GetItems()) do
								if boneSubItem:IsValid() and boneSubItem:IsSelected() then
									local itemIdent = boneSubItem:GetIdentifier()
									if itemIdent ~= nil then
										local identifier = panima.Channel.Path(itemIdent)
										local cname, path =
											ents.PanimaComponent.parse_component_channel_path(identifier)
										if cname ~= nil then
											local c0, offset = path:GetComponent(0)
											if c0 == "bone" then
												local name = path:GetComponent(offset)
												if #name > 0 then
													boneName = name
												end
												break
											end
										end
									end
								end
							end
							if boneName ~= nil then
								break
							end
						end
					end
					break
				end
			end
		end
	end

	if boneName == nil then
		return
	end
	local ent = selectedActorList[1]
	local boneId = boneName
	if type(boneId) == "string" then
		local mdl = ent:GetModel()
		if mdl == nil then
			return
		end
		boneId = mdl:LookupBone(boneId)
		if boneId == -1 then
			return
		end
	end
	ent:RemoveComponent("util_transform")
	util.remove(self.m_entTransform)
	local trBone = ent:AddComponent("util_bone_transform")
	if trBone == nil then
		return
	end
	local trC = trBone:SetTransformEnabled(boneId)
	if trC == nil then
		return
	end
	self:InitializeTransformWidget(trC, ent)

	local function update_channel_value(boneId, value, channelName)
		local channel = actorC:GetBoneChannel(boneId, channelName)
		local log = (channel ~= nil) and channel:GetLog() or nil
		local layer = (log ~= nil) and log:GetLayers():GetTable()[1] or nil
		if layer ~= nil then
			local channelClip = channel:FindParentElement(function(el)
				return el:GetType() == fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP
			end)
			if channelClip ~= nil then
				local projectManager = pm
				-- TODO: Do we have to take the film clip offset into account?
				local timeFrame = channelClip:GetTimeFrame()
				local t = timeFrame:LocalizeOffset(projectManager:GetTimeOffset())
				local i = layer:InsertValue(t, value)

				-- Mark frames as dirty
				local times = layer:GetTimes():GetTable()
				local tPrev = timeFrame:GlobalizeOffset((i > 0) and times:At(i - 1) or t)
				local tNext = timeFrame:GlobalizeOffset((i < (#times - 1)) and times:At(i + 1) or t)
				local minFrame = math.floor(projectManager:TimeOffsetToFrameOffset(tPrev))
				local maxFrame = math.ceil(projectManager:TimeOffsetToFrameOffset(tNext))
				local animCache = projectManager:GetAnimationCache()
				local fc = projectManager:GetActiveGameViewFilmClip()
				for frameIdx = minFrame, maxFrame do
					animCache:MarkFrameAsDirty(frameIdx)
				end
			end
		end
	end
	local newPos
	local newRot
	local newScale
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED, function(boneId, pos, localPos)
		newPos = localPos
		--update_channel_value(boneId,localPos,"position")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED, function(boneId, rot, localRot)
		newRot = localRot
		--update_channel_value(boneId,localRot,"rotation")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED, function(boneId, scale, localScale)
		newScale = localScale
		--update_channel_value(boneId,localScale,"scale")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_TRANSFORM_END, function(scale)
		local animC = actorData:FindComponent("animated")
		local curPose = {
			position = animC ~= nil and (newPos ~= nil) and animC:GetMemberValue("bone/" .. boneName .. "/position")
				or nil,
			rotation = animC ~= nil and (newRot ~= nil) and animC:GetMemberValue("bone/" .. boneName .. "/rotation")
				or nil,
			scale = animC ~= nil and (newScale ~= nil) and animC:GetMemberValue("bone/" .. boneName .. "/scale") or nil,
		}
		local newPose = {
			position = newPos,
			rotation = newRot,
			scale = newScale,
		}
		local function apply_pose(pose)
			if pose.position ~= nil then
				self:SetBoneTransformProperty(ent, boneId, "position", pose.position, udm.TYPE_VECTOR3)
			end
			if pose.rotation ~= nil then
				self:SetBoneTransformProperty(ent, boneId, "rotation", pose.rotation, udm.TYPE_QUATERNION)
			end
			if pose.scale ~= nil then
				self:SetBoneTransformProperty(ent, boneId, "scale", pose.scale, udm.TYPE_VECTOR3)
			end
		end
		-- TODO
		--[[pfm.undoredo.push("bone_transform", function()
			apply_pose(newPose)
		end, function()
			apply_pose(curPose)
		end)()]]
	end)
	self.m_transformComponent = trC
end
function gui.PFMViewport:SetBoneTransformProperty(ent, boneId, propName, value, type)
	if util.is_valid(ent) == false then
		return
	end
	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local bone = skeleton:GetBone(boneId)
	if bone == nil then
		return
	end
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		tool.get_filmmaker():SetActorBoneTransformProperty(actorC, bone:GetName() .. "/" .. propName, value, type)
	end
end
function gui.PFMViewport:GetTransformWidgetComponent()
	return self.m_transformComponent
end
function gui.PFMViewport:OnActorTransformChanged(ent)
	local decalC = ent:GetComponent(ents.COMPONENT_DECAL)
	if decalC ~= nil then
		decalC:ApplyDecal()
	end
	self:MarkActorAsDirty(ent)
end
function gui.PFMViewport:CreateMultiActorTransformWidget()
	local pm = tool.get_filmmaker()
	pm:TagRenderSceneAsDirty()

	util.remove(self.m_entTransform)
	local manipMode = self:GetManipulatorMode()
	if manipMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT or manipMode == gui.PFMViewport.MANIPULATOR_MODE_SCALE then
		return
	end

	local actors = pm:GetSelectionManager():GetSelectedActors()

	local posAvg = Vector()
	local initialActorPoses = {}
	local count = 0
	for actor, _ in pairs(actors) do
		if actor:IsValid() then
			self:RemoveActorTransformWidget(actor)
			posAvg = posAvg + actor:GetPos()
			count = count + 1

			initialActorPoses[actor] = actor:GetPose()
		end
	end
	if count > 0 then
		posAvg = posAvg / count
	end

	local entTransform = ents.create("util_transform")
	entTransform:AddComponent("pfm_transform_gizmo")
	entTransform:Spawn()
	entTransform:SetPos(posAvg)
	self.m_entTransform = entTransform

	local initialTransformPose = entTransform:GetPose()

	local trC = entTransform:GetComponent("util_transform")
	local newPos = {}
	local newRot = {}
	local keyframeCmds = {}
	local function apply_property_value(ent, propName, type, value)
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		local actor = (actorC ~= nil) and actorC:GetActorData() or nil
		if actor == nil then
			return
		end
		local keyframeCmd = pm:ChangeActorPropertyValue(actor, "ec/pfm_actor/" .. propName, type, nil, value)
		if keyframeCmd ~= nil then
			local uuid = tostring(actor:GetUniqueId())
			keyframeCmds[uuid] = keyframeCmds[uuid] or {}
			keyframeCmds[uuid][propName] = keyframeCmd
		end
	end
	trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED, function(pos)
		local dtPos = pos - initialTransformPose:GetOrigin()
		for ent, origPose in pairs(initialActorPoses) do
			if ent:IsValid() then
				local pos = origPose:GetOrigin() + dtPos
				newPos[ent] = pos

				apply_property_value(ent, "position", udm.TYPE_VECTOR3, pos)
			end
		end
	end)
	trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED, function(rot)
		local dtRot = initialTransformPose:GetRotation():GetInverse() * rot
		for ent, origPose in pairs(initialActorPoses) do
			if ent:IsValid() then
				local pose = origPose:Copy()
				local origin = pose:GetOrigin()
				origin:RotateAround(initialTransformPose:GetOrigin(), dtRot)
				pose:SetOrigin(origin)
				pose:SetRotation(dtRot * pose:GetRotation())

				newPos[ent] = pose:GetOrigin()
				newRot[ent] = pose:GetRotation()

				apply_property_value(ent, "position", udm.TYPE_VECTOR3, newPos[ent])
				apply_property_value(ent, "rotation", udm.TYPE_QUATERNION, newRot[ent])
			end
		end
	end)
	trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END, function()
		local cmd = pfm.create_command("composition")
		for ent, origPose in pairs(initialActorPoses) do
			if ent:IsValid() then
				local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
				local actor = actorC:GetActorData()

				local keyframeCmds = keyframeCmds[tostring(actor:GetUniqueId())]

				local pos = newPos[ent]
				if pos ~= nil then
					pm:ChangeActorPropertyValue(
						actor,
						"ec/pfm_actor/position",
						udm.TYPE_VECTOR3,
						origPose:GetOrigin(),
						pos,
						nil,
						true,
						cmd,
						(keyframeCmds ~= nil) and keyframeCmds.position or nil
					)
				end

				local rot = newRot[ent]
				if rot ~= nil then
					pm:ChangeActorPropertyValue(
						actor,
						"ec/pfm_actor/rotation",
						udm.TYPE_QUATERNION,
						origPose:GetRotation(),
						rot,
						nil,
						true,
						cmd,
						(keyframeCmds ~= nil) and keyframeCmds.rotation or nil
					)
				end
			end
		end
		pfm.undoredo.push("move_actors", cmd)()
	end)
	self:InitializeTransformWidget(trC, nil, self:GetTransformSpace() == ents.UtilTransformComponent.SPACE_VIEW)
	self.m_transformComponent = trC
end
function gui.PFMViewport:ScaleSelectedActors(scale)
	local actors = tool.get_filmmaker():GetSelectionManager():GetSelectedActors()
	local center = Vector()
	local numActors = 0
	for actor, _ in pairs(actors) do
		if actor:IsValid() then
			center = center + actor:GetPos()
			numActors = numActors + 1
		end
	end
	center = center / numActors
	for actor, _ in pairs(actors) do
		if actor:IsValid() then
			local pos = actor:GetPos()
			pos = pos - center
			pos = pos * scale
			pos = pos + center
			tool.get_filmmaker()
				:SetActorTransformProperty(actor:GetComponent(ents.COMPONENT_PFM_ACTOR), "position", pos)
			tool.get_filmmaker()
				:SetActorTransformProperty(
					actor:GetComponent(ents.COMPONENT_PFM_ACTOR),
					"scale",
					actor:GetScale() * scale
				)
			self:OnActorTransformChanged(actor)
		end
	end
end
function gui.PFMViewport:RemoveActorTransformWidget(ent)
	ent:RemoveComponent("util_bone_transform")
	ent:RemoveComponent("util_transform")
	util.remove(self.m_entTransform)
end
function gui.PFMViewport:OnStartTransform(ent)
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC == nil then
		return
	end
	actorC:OnStartTransform()
end
function gui.PFMViewport:OnEndTransform(ent)
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC == nil then
		return
	end
	actorC:OnEndTransform()
end
function gui.PFMViewport:CreateActorTransformWidget(ent, manipMode, enabled)
	if enabled == nil then
		enabled = true
	end
	self:RemoveActorTransformWidget(ent)

	if manipMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT then
		tool.get_filmmaker():TagRenderSceneAsDirty()
		return
	end

	local function add_transform_component()
		local trC = ent:GetComponent("util_transform")
		if trC ~= nil then
			return trC
		end
		trC = ent:AddComponent("util_transform")
		if trC == nil then
			return trC
		end
		ent:AddComponent("pfm_transform_gizmo")
		local newPos
		local newRot
		local newScale
		local origPose
		local pfmActorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		local actorData = (pfmActorC ~= nil) and pfmActorC:GetActorData() or nil
		local actorC = (actorData ~= nil) and actorData:FindComponent("pfm_actor") or nil
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED, function(pos)
			newPos = pos:Copy()
			self:MarkActorAsDirty(ent)
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED, function(rot)
			newRot = rot:Copy()
			self:MarkActorAsDirty(ent)
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED, function(scale)
			newScale = scale:Copy()
			self:MarkActorAsDirty(ent)
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_START, function()
			origPose = ent:GetPose()
			self:OnStartTransform(ent)
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END, function(scale)
			local newPose = {
				position = newPos,
				rotation = newRot,
				scale = newScale,
			}
			for k, v in pairs(newPose) do
				newPose[k] = v:Copy()
			end

			if
				toboolean(
					self.m_ctrlTransformKeyframes:GetOptionValue(self.m_ctrlTransformKeyframes:GetSelectedOption())
				)
			then
				self:ApplyPoseToKeyframeAnimation(actorData, origPose, newPose)
			else
				local propInfo = {
					{
						path = "ec/pfm_actor/position",
						type = udm.TYPE_VECTOR3,
						oldValue = origPose:GetOrigin(),
						newValue = newPos,
					},
					{
						path = "ec/pfm_actor/rotation",
						type = udm.TYPE_QUATERNION,
						oldValue = origPose:GetRotation(),
						newValue = newRot,
					},
					{
						path = "ec/pfm_actor/scale",
						type = udm.TYPE_VECTOR3,
						oldValue = origPose:GetScale(),
						newValue = newScale,
					},
				}
				for _, info in ipairs(propInfo) do
					if info.newValue ~= nil then
						tool.get_filmmaker():GetActorEditor():UpdateAnimationChannelValue(
							actorData,
							info.path,
							info.type,
							info.oldValue,
							info.newValue,
							nil,
							true
						)
					end
				end
			end
			self:OnEndTransform(ent)
		end)
		return trC
	end
	local manipMode = manipMode or self.m_manipulatorMode
	if enabled then
		local pm = tool.get_filmmaker()
		local actorEditor = pm:GetActorEditor()
		local activeControls = actorEditor:GetActiveControls()
		local uuid = tostring(ent:GetUuid())
		if activeControls[uuid] ~= nil then
			local targetPath
			local i = 0

			local poseMembers = {}
			for path, data in pairs(activeControls[uuid]) do
				local memberInfo, c = ent:FindMemberInfo(path)
				if memberInfo ~= nil then
					if self:IsMoveManipulatorMode(manipMode) then
						if memberInfo.type == udm.TYPE_VECTOR3 then
							i = i + 1
							targetPath = path
						end
					elseif self:IsRotationManipulatorMode(manipMode) then
						if memberInfo.type == udm.TYPE_QUATERNION then
							i = i + 1
							targetPath = path
						end
					elseif self:IsScaleManipulatorMode(manipMode) then
						if memberInfo.type == udm.TYPE_VECTOR3 then
							i = i + 1
							targetPath = path
						end
					end
					local metaInfo =
						memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE_COMPONENT)
					if metaInfo ~= nil then
						table.insert(poseMembers, { c, metaInfo.poseProperty })
					end
					if i == 2 then
						-- If multiple properties of the same type are selected (e.g. multiple position properties),
						-- we'll fall back to the actor position/rotation
						targetPath = nil
						break
					end
				end
			end

			if targetPath == nil and #poseMembers == 1 then
				-- No property is selected that would correspond to the manipulator mode, but we
				-- may still be able to select an appropriate property through association.
				local c = poseMembers[1][1]
				local idx = c:GetMemberIndex(poseMembers[1][2])
				local memberInfo = (idx ~= nil) and poseMembers[1][1]:GetMemberInfo(idx) or nil
				if memberInfo ~= nil then
					local metaInfo = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
					if metaInfo ~= nil then
						if self:IsMoveManipulatorMode(manipMode) then
							if #metaInfo.posProperty > 0 then
								targetPath = "ec/" .. c:GetComponentName() .. "/" .. metaInfo.posProperty
							end
						elseif self:IsRotationManipulatorMode(manipMode) then
							if #metaInfo.rotProperty > 0 then
								targetPath = "ec/" .. c:GetComponentName() .. "/" .. metaInfo.rotProperty
							end
						elseif self:IsScaleManipulatorMode(manipMode) then
							if #metaInfo.scaleProperty > 0 then
								targetPath = "ec/" .. c:GetComponentName() .. "/" .. metaInfo.scaleProperty
							end
						end
					end
				end
			end

			if
				targetPath ~= nil
				--and targetPath ~= "ec/pfm_actor/position"
				--and targetPath ~= "ec/pfm_actor/rotation"
			then -- Actor translation and rotation are handled differently (see bottom of this function)
				local memberInfo = ent:FindMemberInfo(targetPath)
				if memberInfo ~= nil then
					if
						(memberInfo.type == udm.TYPE_VECTOR3 and self:IsMoveManipulatorMode(manipMode))
						or (memberInfo.type == udm.TYPE_QUATERNION and self:IsRotationManipulatorMode(manipMode))
						or (memberInfo.type == udm.TYPE_VECTOR3 and self:IsScaleManipulatorMode(manipMode))
					then
						local componentName, pathName =
							ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
						local c = (componentName ~= nil) and ent:GetComponent(componentName) or nil
						local idx = (c ~= nil) and c:GetMemberIndex(pathName:GetString()) or nil
						local pose = (idx ~= nil) and c:GetTransformMemberPose(idx, math.COORDINATE_SPACE_WORLD) or nil
						if pose ~= nil then
							local entTransform = ents.create("util_transform")
							entTransform:AddComponent("pfm_transform_gizmo")
							entTransform:Spawn()

							entTransform:SetPose(pose)
							self.m_entTransform = entTransform

							--[[if(objectSpace) then
								entTransform:GetComponent("util_transform"):SetParent(ent,true)
								entTransform:SetPose(pose)
							end]]

							local actor = pfm.dereference(uuid)
							local component = actor:FindComponent(componentName)

							local origDataPose
							if
								memberInfo.type == ents.MEMBER_TYPE_TRANSFORM
								or memberInfo.type == ents.MEMBER_TYPE_SCALED_TRANSFORM
							then
								origDataPose = component:GetEffectiveMemberValue(pathName:GetString(), memberInfo.type)
								origDataPose = c:ConvertTransformMemberPoseToTargetSpace(
									idx,
									math.COORDINATE_SPACE_WORLD,
									origDataPose
								)
							elseif
								memberInfo.type == ents.MEMBER_TYPE_QUATERNION
								or memberInfo.type == ents.MEMBER_TYPE_EULER_ANGLES
							then
								origDataPose = math.ScaledTransform()
								local rot = component:GetEffectiveMemberValue(pathName:GetString(), memberInfo.type)
								rot = c:ConvertTransformMemberRotToTargetSpace(idx, math.COORDINATE_SPACE_WORLD, rot)
								origDataPose:SetRotation(rot)
							else
								origDataPose = math.ScaledTransform()
								local pos = component:GetEffectiveMemberValue(pathName:GetString(), memberInfo.type)
								pos = c:ConvertTransformMemberPosToTargetSpace(idx, math.COORDINATE_SPACE_WORLD, pos)
								origDataPose:SetOrigin(pos)
							end

							local restoreAnimChannel
							local tmpAnimChannel
							local panimaC = ent:GetComponent(ents.COMPONENT_PANIMA)
							local animManager = (panimaC ~= nil) and panimaC:GetAnimationManager("pfm") or nil
							local player = (animManager ~= nil) and animManager:GetPlayer() or nil
							local anim = (player ~= nil) and player:GetAnimation() or nil
							local function init_animation_channel_substitute()
								if restoreAnimChannel ~= nil then
									return
								end
								local channel = (anim ~= nil) and anim:FindChannel(targetPath) or nil
								if channel ~= nil then
									-- The property is animated. In this case, we'll have to replace the animation channel with
									-- a temporary one containing only one animation value as long as the object is being transformed.
									-- This is because, while the object is being moved, we want to update it continuously, but we
									-- don't want to do a full update of the property value yet, because that would be too
									-- expensive. We can perform a cheap update by replacing the animation value in the channel, and
									-- then we'll do the full update once the transformation has stopped.
									local val = panimaC:GetRawPropertyValue(animManager, targetPath, memberInfo.type)
									local cpy = panima.Channel(channel)
									cpy:ClearAnimationData()
									cpy:InsertValue(0.0, val)
									anim:RemoveChannel(channel)
									anim:AddChannel(cpy)
									panimaC:UpdateAnimationChannelSubmitters()
									restoreAnimChannel = channel
									tmpAnimChannel = cpy
								end
							end

							local function restore_animation_channel()
								if restoreAnimChannel == nil then
									return
								end
								anim:RemoveChannel(tmpAnimChannel)
								anim:AddChannel(restoreAnimChannel)
								panimaC:UpdateAnimationChannelSubmitters()
								restoreAnimChannel = nil
								tmpAnimChannel = nil
							end

							local trC = entTransform:GetComponent("util_transform")
							local function calc_new_data_pose()
								local oldPose = pose:Copy()
								local newPose = trC:GetEntity():GetPose()
								local dtPos = newPose:GetOrigin() - oldPose:GetOrigin()
								local dtRot = oldPose:GetRotation():GetInverse() * newPose:GetRotation()
								local dtScale = newPose:GetScale() - oldPose:GetScale()
								return math.ScaledTransform(
									origDataPose:GetOrigin() + dtPos,
									origDataPose:GetRotation() * dtRot,
									origDataPose:GetScale() + dtScale
								)
							end
							trC:SetScaleEnabled(false)
							if memberInfo.type == udm.TYPE_VECTOR3 then
								if self:IsMoveManipulatorMode(manipMode) then
									local dbgLineC
									local onPosChanged
									if componentName == "ik_solver" then
										if pathName:GetFront() == "control" then
											-- Ik control, we'll add a dotted line from the control position
											-- to the bone position
											dbgLineC = entTransform:AddComponent("debug_dotted_line")
											if dbgLineC ~= nil then
												dbgLineC:SetStartPosition(Vector(0, 0, 0))
												dbgLineC:SetEndPosition(Vector(20, 20, 20))

												onPosChanged = function(pos)
													if util.is_valid(dbgLineC) then
														local skelBoneId = c:GetControlBoneId(pathName:GetString())
														local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
														dbgLineC:SetEndPosition(pos)
														local bonePose = (animC ~= nil and skelBoneId ~= nil)
																and animC:GetGlobalBonePose(skelBoneId)
															or nil
														if bonePose ~= nil then
															dbgLineC:SetStartPosition(bonePose:GetOrigin())
														end
													end
												end
											end
										end
									end
									trC:AddEventCallback(
										ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,
										function(posTr)
											if c:IsValid() then
												local pos = calc_new_data_pose():GetOrigin()
												if tmpAnimChannel ~= nil then
													tmpAnimChannel:InsertValue(0.0, pos)
												else
													c:SetTransformMemberPos(idx, math.COORDINATE_SPACE_WORLD, pos)
												end
												if onPosChanged ~= nil then
													onPosChanged(pos)
												end
											end
										end
									)
								else
									trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED, function()
										if c:IsValid() then
											local scale = calc_new_data_pose():GetScale()
											if tmpAnimChannel ~= nil then
												tmpAnimChannel:InsertValue(0.0, scale)
											else
												c:SetTransformMemberScale(idx, math.COORDINATE_SPACE_LOCAL, scale)
											end
										end
									end)
								end
							elseif memberInfo.type == udm.TYPE_QUATERNION then
								trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED, function()
									if c:IsValid() then
										local rot = calc_new_data_pose():GetRotation()
										if tmpAnimChannel ~= nil then
											tmpAnimChannel:InsertValue(0.0, rot)
										else
											c:SetTransformMemberRot(idx, math.COORDINATE_SPACE_WORLD, rot)
										end
									end
								end)
							end
							trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_START, function(scale)
								init_animation_channel_substitute()
								self:OnStartTransform(ent)
							end)
							trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END, function(scale)
								restore_animation_channel()

								local get_pose_value
								if memberInfo.type == udm.TYPE_VECTOR3 then
									get_pose_value = function(pose)
										local pos = pose:GetOrigin()
										pos = c:ConvertPosToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, pos)
										return pos
									end
								else
									get_pose_value = function(pose)
										local rot = pose:GetRotation()
										rot = c:ConvertRotToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, rot)
										return rot
									end
								end

								local pm = tool.get_filmmaker()
								local newDataPose = calc_new_data_pose()
								local oldVal = get_pose_value(origDataPose)
								local newVal = get_pose_value(newDataPose)

								if oldVal ~= nil and newVal ~= nil then
									pm:ChangeActorPropertyValue(
										pfm.dereference(uuid),
										targetPath,
										memberInfo.type,
										oldVal,
										newVal,
										nil,
										true
									)
								end
								self:OnEndTransform(ent)
							end)
							self:InitializeTransformWidget(trC, ent)
						end
					end
				end
			end
		end

		if util.is_valid(self.m_entTransform) == false then
			local tc = add_transform_component()
			self.m_transformComponent = tc
			self:InitializeTransformWidget(tc, ent)
		end
	end
	tool.get_filmmaker():TagRenderSceneAsDirty()
end
function gui.PFMViewport:UpdateActorManipulation(ent, selected)
	self:CreateActorTransformWidget(ent, self.m_manipulatorMode, selected)
end
function gui.PFMViewport:CycleTransformSpace()
	local transformSpace = self:GetTransformSpace()
	if transformSpace == ents.UtilTransformComponent.SPACE_WORLD then
		self:SetTransformSpace(ents.UtilTransformComponent.SPACE_LOCAL)
	elseif transformSpace == ents.UtilTransformComponent.SPACE_LOCAL then
		self:SetTransformSpace(ents.UtilTransformComponent.SPACE_VIEW)
	elseif transformSpace == ents.UtilTransformComponent.SPACE_VIEW then
		self:SetTransformSpace(ents.UtilTransformComponent.SPACE_WORLD)
	end
end
function gui.PFMViewport:SetTranslationManipulatorMode()
	if self:GetManipulatorMode() == gui.PFMViewport.MANIPULATOR_MODE_MOVE then
		self:CycleTransformSpace()
	end
	self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_MOVE)
end
function gui.PFMViewport:SetRotationManipulatorMode()
	if self:GetManipulatorMode() == gui.PFMViewport.MANIPULATOR_MODE_ROTATE then
		self:CycleTransformSpace()
	end
	self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_ROTATE)
end
function gui.PFMViewport:SetScaleManipulatorMode()
	self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SCALE)
end
function gui.PFMViewport:InitializeManipulatorControls()
	local controls = gui.create("WIHBox", self.m_controls)
	controls:SetName("manip_controls")

	self.m_btSelect = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_manipulator_select",
		"gui/pfm/icon_manipulator_select_activated",
		function()
			self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SELECT)
			return true
		end
	)
	self.m_btSelect:SetTooltip(
		locale.get_text("pfm_viewport_tool_select") .. " (" .. pfm.get_key_binding("pfm_action transform select") .. ")"
	)
	self.m_btSelect:SetName("manip_select")

	self.m_btMove = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_manipulator_move",
		"gui/pfm/icon_manipulator_move_activated",
		function()
			self:SetTranslationManipulatorMode()
			return true
		end
	)
	self.m_btMove:SetTooltip(
		locale.get_text("pfm_viewport_tool_move")
			.. " ("
			.. pfm.get_key_binding("pfm_action transform translate")
			.. ")"
	)
	self.m_btMove:AddCallback("OnMouseEvent", function(pFilmClip, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("pfm_set_position"), function()
				local tePos
				local p = pfm.open_entry_edit_window(locale.get_text("pfm_set_position"), function(ok)
					if ok then
						if self:GetManipulatorMode() ~= gui.PFMViewport.MANIPULATOR_MODE_MOVE then
							self:SetTranslationManipulatorMode()
						end
						local v = Vector(tePos:GetText())
						if v ~= nil then
							local trC = self:GetTransformWidgetComponent()
							if util.is_valid(trC) then
								local c = trC:GetTransformUtility(
									ents.UtilTransformArrowComponent.TYPE_TRANSLATION,
									ents.UtilTransformArrowComponent.AXIS_X,
									"translation"
								)
								if c ~= nil then
									local pose = trC:GetBasePose()
									pose:TranslateLocal(v)
									trC:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_START)
									trC:BroadcastEvent(
										ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,
										{ pose:GetOrigin() }
									)
									trC:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END)
								end
							end
						end
					else
						return
					end
				end)

				tePos = p:AddNumericEntryField(locale.get_text("position") .. ":", "0 0 0")
				p:SetWindowSize(Vector2i(202, 100))
				p:Update()
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	self.m_btMove:SetName("manip_move")

	self.m_btRotate = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_manipulator_rotate",
		"gui/pfm/icon_manipulator_rotate_activated",
		function()
			self:SetRotationManipulatorMode()
			return true
		end
	)
	self.m_btRotate:SetTooltip(
		locale.get_text("pfm_viewport_tool_rotate") .. " (" .. pfm.get_key_binding("pfm_action transform rotate") .. ")"
	)
	self.m_btRotate:AddCallback("OnMouseEvent", function(pFilmClip, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("pfm_set_rotation"), function()
				local teRot
				local p = pfm.open_entry_edit_window(locale.get_text("pfm_set_rotation"), function(ok)
					if ok then
						if self:GetManipulatorMode() ~= gui.PFMViewport.MANIPULATOR_MODE_ROTATE then
							self:SetRotationManipulatorMode()
						end
						local str = teRot:GetText()
						local c = string.split(str, " ")
						local rot
						if #c == 4 then
							rot = Quaternion(
								tonumber(c[1]) or 1.0,
								tonumber(c[2]) or 0.0,
								tonumber(c[3]) or 0.0,
								tonumber(c[4]) or 0.0
							)
						else
							rot = EulerAngles(str)
							rot = (rot ~= nil) and rot:ToQuaternion() or nil
						end
						if rot ~= nil then
							local trC = self:GetTransformWidgetComponent()
							if util.is_valid(trC) then
								local ent = trC:GetTransformUtility(
									ents.UtilTransformArrowComponent.TYPE_ROTATION,
									ents.UtilTransformArrowComponent.AXIS_X,
									"rotation"
								)
								if ent ~= nil then
									local c = ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
									if c ~= nil then
										local targetSpaceRotation = c:GetTargetSpaceRotation()
										local baseRot = targetSpaceRotation:GetInverse() * trC:GetEntity():GetRotation()
										rot = baseRot * rot
										trC:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_START)
										trC:BroadcastEvent(
											ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,
											{ rot }
										)
										trC:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END)
									end
								end
							end
						end
					else
						return
					end
				end)

				teRot = p:AddNumericEntryField(locale.get_text("rotation") .. ":", "0 0 0")
				p:SetWindowSize(Vector2i(202, 100))
				p:Update()
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	self.m_btRotate:SetName("manip_rotate")

	self.m_btScreen = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_manipulator_screen",
		"gui/pfm/icon_manipulator_screen_activated",
		function()
			self:SetScaleManipulatorMode()
			return true
		end
	)
	self.m_btScreen:SetTooltip(
		locale.get_text("pfm_viewport_tool_scale") .. " (" .. pfm.get_key_binding("pfm_action transform scale") .. ")"
	)
	self.m_btScreen:SetName("manip_screen")

	controls:SetHeight(self.m_btSelect:GetHeight())
	controls:Update()
	controls:SetX(3)
	controls:SetAnchor(0, 1, 0, 1)
	self.manipulatorControls = controls
end

local g_snapToGridSpacing = 0
function pfm.set_snap_to_grid_spacing(spacing)
	g_snapToGridSpacing = spacing
end
function pfm.get_snap_to_grid_spacing()
	return g_snapToGridSpacing
end

local g_angularSpacing = 0
function pfm.set_angular_spacing(spacing)
	g_angularSpacing = spacing
end
function pfm.get_angular_spacing()
	return g_angularSpacing
end
