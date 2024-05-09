--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = ents.PFMVrManager

function Component:InitializeRecordingData()
	self:AddEntityComponent("game_animation_recorder")
end

function Component:IsRecording()
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		return false
	end
	return recorderC:IsRecording()
end

function Component:StartRecording()
	self:EndRecording(false)
	pfm.log("Starting VR recording...", pfm.LOG_CATEGORY_PFM_VR)

	local hmdC = self:GetEntityComponent("vr_hmd")
	if hmdC == nil then
		pfm.log("No vr hmd component found!", pfm.LOG_CATEGORY_PFM_VR, pfm.LOG_SEVERITY_WARNING)
		return
	end

	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		return
	end

	recorderC:Reset()
	local targetActors = {}
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
						pfm.log(
							"Adding property '" .. ikSolverC:GetMemberUri(ctrlPropIdx) .. "' to recording list...",
							pfm.LOG_CATEGORY_PFM_VR
						)
						table.insert(properties[componentType], info.name)
					end
				end
				recorderC:AddEntity(targetActor, properties)
			end
		end
	end

	-- TODO: Play PFM animation, sync with timeframe

	recorderC:StartRecording()
end

function Component:EndRecording(syncAnims)
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		return 0
	end
	if recorderC:IsRecording() == false then
		return 0
	end
	local n = recorderC:EndRecording()
	pfm.log(
		"Ending VR recording. "
			.. recorderC:GetRecordedFrameCount()
			.. " frames have been recorded with "
			.. n
			.. " properties.",
		pfm.LOG_CATEGORY_PFM_VR
	)
	if syncAnims == nil then
		syncAnims = true
	end
	if syncAnims then
		self:SyncAnimations()
	end
	return n
end

function Component:SyncAnimations()
	pfm.log("Syncing recorded animation with PFM...", pfm.LOG_CATEGORY_PFM_VR)
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		pfm.log("No game animation recorder component found!", pfm.LOG_CATEGORY_PFM_VR, pfm.LOG_SEVERITY_WARNING)
		return
	end

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		pfm.log("Filmmaker is not running!", pfm.LOG_CATEGORY_PFM_VR, pfm.LOG_SEVERITY_WARNING)
		return
	end
	local numProps = 0
	local animManager = pm:GetAnimationManager()
	for uuid, animData in pairs(recorderC:GetAnimations()) do
		if animData.entity:IsValid() then
			local actorC = animData.entity:GetComponent(ents.COMPONENT_PFM_ACTOR)
			local actorData = (actorC ~= nil) and actorC:GetActorData() or nil
			if actorData ~= nil then
				for componentType, componentAnimData in pairs(animData.channels) do
					for propName, propAnimData in pairs(componentAnimData) do
						if propAnimData.component:IsValid() then
							local path = "ec/" .. componentType .. "/" .. propName
							local channel = propAnimData.channel
							local times = channel:GetTimes()
							local values = channel:GetValues()
							local valueType = channel:GetValueType()
							animManager:SetRawAnimationData(actorData, path, times, values, valueType)
							numProps = numProps + 1
						end
					end
				end
			end
		end
	end
	pfm.log(numProps .. " properties have been synchronized!", pfm.LOG_CATEGORY_PFM_VR)
end
