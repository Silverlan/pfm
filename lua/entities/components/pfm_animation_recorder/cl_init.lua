--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMAnimationRecorder", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("game_animation_recorder")
end

function Component:SetProjectManager(pm)
	self.m_projectManager = pm
end

function Component:GetProjectManager()
	return self.m_projectManager
end

function Component:AddEntity(actor, props)
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		return
	end
	recorderC:AddEntity(actor, props)
end

function Component:StartRecording()
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil or recorderC:IsRecording() then
		return
	end
	pfm.log("Starting recording...", pfm.LOG_CATEGORY_PFM)
	recorderC:StartRecording()
end

function Component:EndRecording()
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil or recorderC:IsRecording() == false then
		return
	end
	pfm.log("Ending recording...", pfm.LOG_CATEGORY_PFM)
	recorderC:EndRecording()
	self:SyncAnimations()
	recorderC:Reset()
end

function Component:SyncAnimations()
	pfm.log("Syncing recorded animation with PFM...", pfm.LOG_CATEGORY_PFM)
	local recorderC = self:GetEntityComponent(ents.COMPONENT_GAME_ANIMATION_RECORDER)
	if recorderC == nil then
		pfm.log("No game animation recorder component found!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return
	end

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		pfm.log("Filmmaker is not running!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return
	end
	local applyCurveFitting = true
	local numProps = 0
	local animManager = pm:GetAnimationManager()
	--local cmd = pfm.create_command("composition")
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
							local addAsAnimationValue = true
							if actorData:FindEditorChannel(path) == nil and #values == 2 then
								local n = udm.get_numeric_component_count(valueType)
								if n > 0 then
									if udm.compare_numeric_values(values[1], values[2], valueType) then
										-- There is only one value and no animation channel exists for this property,
										-- so we can just set the value directly.
										actorData:SetMemberValue(path, valueType, values[1])
										addAsAnimationValue = false
									end
								end
							end
							if addAsAnimationValue then
								--local res, subCmd = cmd:AddSubCommand("add_editor_channel", actorData, path, valueType)
								local cmd = pfm.create_command("add_editor_channel", actorData, path, valueType)
								if cmd ~= nil then
									cmd:Execute()
								end

								local anim, actorChannel, animClip =
									animManager:SetRawAnimationData(actorData, path, times, values, valueType)

								if applyCurveFitting then
									local channel = animClip:FindChannel(path)
									if channel ~= nil then
										local typeComponentIndex = 0
										channel:ApplyCurveFittingToRange(
											actorData,
											path,
											typeComponentIndex,
											times[1],
											times[#times],
											cmd
										)

										local editorData = animClip:GetEditorData()
										local editorChannel = editorData:FindChannel(path)
										if editorChannel ~= nil then
											local graphCurve = editorChannel:GetGraphCurve()
											graphCurve:RebuildDirtyGraphCurveSegments()
										end
									end
								end
							end
							numProps = numProps + 1
						end
					end
				end
			end
		end
	end
	--pfm.undoredo.push("init_animation_channels", cmd)()
	pfm.log(numProps .. " properties have been synchronized!", pfm.LOG_CATEGORY_PFM)
end

function Component:OnRemove() end

function Component:OnEntitySpawn() end
ents.COMPONENT_PFM_ANIMATION_RECORDER = ents.register_component("pfm_animation_recorder", Component)