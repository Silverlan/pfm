--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = ents.PFMVrManager

function Component:InitializeRecordingData()
	local pfmManagerC = self:GetPfmManager()
	if util.is_valid(pfmManagerC) == false then
		return
	end
	pfmManagerC:AddEntityComponent("game_animation_recorder")
end

function Component:GetGameAnimationRecorder()
	local pfmManagerC = self:GetPfmManager()
	if util.is_valid(pfmManagerC) == false then
		return
	end
	return pfmManagerC:GetEntity():GetComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
end

function Component:IsRecording()
	local recorderC = self:GetGameAnimationRecorder()
	if recorderC == nil then
		return false
	end
	return recorderC:IsRecording()
end

function Component:StartRecording()
	self:EndRecording()
	self:LogInfo("Starting VR recording...")

	local hmdC = self:GetEntityComponent("vr_hmd")
	if hmdC == nil then
		self:LogWarn("No vr hmd component found!")
		return
	end

	local pfmManagerC = self:GetPfmManager()
	local recorderC = self:GetGameAnimationRecorder()
	if pfmManagerC == nil or recorderC == nil then
		return
	end

	recorderC:Reset()

	for ent, c in ents.citerator(ents.COMPONENT_VR_POV_CONTROLLER) do
		local ikSolverC = ent:GetComponent(ents.COMPONENT_IK_SOLVER)
		if c:IsActive() and ikSolverC ~= nil then
			local properties = {}
			local propsIk = {}
			properties["ik_solver"] = propsIk

			local mdl = ent:GetModel()
			local skel = (mdl ~= nil) and mdl:GetSkeleton() or nil
			if skel ~= nil then
				local indices = c:GetIkControllerIndices()
				for _, idx in ipairs(indices) do
					local memberInfo = ikSolverC:GetMemberInfo(idx)
					if memberInfo ~= nil then
						local metaInfoPose =
							memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
						if metaInfoPose ~= nil then
							if metaInfoPose.posProperty ~= nil then
								self:LogInfo(
									"Adding property '{}' of actor '{}' to recording list...",
									metaInfoPose.posProperty,
									ent
								)
								table.insert(propsIk, metaInfoPose.posProperty)
							end
							if metaInfoPose.rotProperty ~= nil then
								self:LogInfo(
									"Adding property '{}' of actor '{}' to recording list...",
									metaInfoPose.rotProperty,
									ent
								)
								table.insert(propsIk, metaInfoPose.rotProperty)
							end
						end

						--[[function pfm.util.find_property_pose_meta_info(ent, path)
							local memberInfo = pfm.get_member_info(path, ent)
							if memberInfo == nil then
								return
							end
							local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
							local metaInfoPose = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
							if metaInfoPose ~= nil then
								return metaInfoPose, componentName, memberName:GetString()
							end
							local metaInfo = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE_COMPONENT)
							if metaInfo == nil or componentName == nil then
								return
							end
							local posePath = "ec/" .. componentName .. "/" .. metaInfo.poseProperty
							local memberInfoPose = pfm.get_member_info(posePath, ent)
							metaInfoPose = memberInfoPose:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
							return metaInfoPose, componentName, metaInfo.poseProperty
						end]]

						--[[local boneName = memberInfo.name

						local ctrlNamePos = "control/" .. boneName .. "/position"
						if ctrlNamePos ~= nil then
							self:LogInfo("Adding property '{}' of actor '{}' to recording list...", ctrlNamePos, ent)
							table.insert(propsIk, ctrlNamePos)
						end

						local ctrlNameRot = "control/" .. boneName .. "/rotation"
						if ctrlNameRot ~= nil then
							self:LogInfo("Adding property '{}' of actor '{}' to recording list...", ctrlNameRot, ent)
							table.insert(propsIk, ctrlNameRot)
						end]]
					end
				end
				recorderC:AddEntity(ent, properties)
			end
		end
	end
	--[[local targetActors = {}
	for _, pfmTdC in ipairs(self:GetTrackedDevices()) do
		if pfmTdC:IsValid() then
			local targetActor, ikSolverC, ctrlPropIndices = pfmTdC:GetTargetData()
			if ctrlPropIndices ~= nil and #ctrlPropIndices > 0 then
				local componentType = ikSolverC:GetComponentName()
				targetActors[targetActor] = targetActors[targetActor] or {}
				local properties = targetActors[targetActor]
				properties[componentType] = properties[componentType] or {}
				for _, ctrlPropIdx in ipairs(ctrlPropIndices) do
					local info = ikSolverC:GetMemberInfo(ctrlPropIdx)
					if info ~= nil then
						self:LogInfo(
							"Adding property '" .. ikSolverC:GetMemberUri(ctrlPropIdx) .. "' to recording list..."
						)
						table.insert(properties[componentType], info.name)
					end
				end
				recorderC:AddEntity(targetActor, properties)
			end
		end
	end]]
	pfmManagerC:StartRecording()
end

function Component:EndRecording()
	local pfmManagerC = self:GetPfmManager()
	local recorderC = self:GetGameAnimationRecorder()
	if pfmManagerC == nil or recorderC == nil then
		return 0
	end
	if pfmManagerC:IsRecording() == false then
		return 0
	end
	local n = pfmManagerC:EndRecording()
	self:LogInfo(
		"Ending VR recording. "
			.. recorderC:GetRecordedFrameCount()
			.. " frames have been recorded with "
			.. n
			.. " properties."
	)
	return n
end
