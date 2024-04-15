--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_selection_wireframe")
include_component("pfm_skeleton")
include("/gui/hover_text.lua")

local Component = util.register_class("ents.PFMManager", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_curSelectedBones = {}
	local cursorTargetC = self:AddEntityComponent("pfm_cursor_target")
	cursorTargetC:AddEventCallback(ents.PFMCursorTarget.EVENT_ON_TARGET_CHANGED, function(...)
		self:OnCursorTargetChanged(...)
	end)
	cursorTargetC:AddEventCallback(ents.PFMCursorTarget.EVENT_ON_TARGET_ACTOR_CHANGED, function(...)
		self:OnCursorTargetActorChanged(...)
	end)
	cursorTargetC:SetRaycastFilter(function(ent)
		return ent:HasComponent(ents.COMPONENT_PFM_EDITOR_ACTOR)
	end)
end
function Component:GetHoverTextElement()
	if util.is_valid(self.m_elTextHover) == false then
		self.m_elTextHover = gui.create("WIHoverText")
	end
	return self.m_elTextHover
end
function Component:SetHoverText(text)
	self:GetHoverTextElement():SetText(text)
end
function Component:SetHoverTextVisible(visible)
	self:GetHoverTextElement():SetVisible(visible)
end
function Component:OnRemove()
	util.remove(self.m_elTextHover)
end
function Component:AddOutline(ent)
	debug.start_profiling_task("pfm_selection_outline")
	ent:AddComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
	debug.stop_profiling_task()
end
function Component:RemoveOutline(ent)
	ent:RemoveComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
end
function Component:DeselectBone(ent)
	local boneC = ent:GetComponent(ents.COMPONENT_PFM_BONE)
	if boneC ~= nil and boneC:IsPersistent() == false then
		boneC:SetSelected(false)
	end
end
function Component:GetSelectedBones()
	local bones = {}
	for ent, _ in pairs(self.m_curSelectedBones) do
		if ent:IsValid() then
			table.insert(bones, ent)
		end
	end
	return bones
end
function Component:SetHoverBone(rayInfo, actor, boneId, curSelected)
	local mdl = actor:GetModel()
	local skel = (mdl ~= nil) and mdl:GetSkeleton() or nil
	local bone = (skel ~= nil) and skel:GetBone(boneId) or nil

	local c = actor:GetComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
	if c == nil then
		return false
	end
	local showHoverText = false
	if bone ~= nil and util.is_valid(rayInfo.vpData.viewport) then
		local animC = actor:GetComponent(ents.COMPONENT_ANIMATED)
		local pos = (animC ~= nil) and animC:GetBonePose(boneId, math.COORDINATE_SPACE_WORLD):GetOrigin() or nil
		if pos ~= nil then
			local elHoverText = self:GetHoverTextElement()
			elHoverText:SetParent(rayInfo.vpData.viewport)
			elHoverText:SetText(bone:GetName())
			elHoverText:SetWorldSpacePosition(pos)
			showHoverText = true
		end
	end

	local tEnts = c:GetBoneEntities(boneId) or {}
	for dstBoneId, ent in pairs(tEnts) do
		if ent:IsValid() then
			local boneC = ent:GetComponent(ents.COMPONENT_PFM_BONE)
			if boneC ~= nil then
				boneC:SetSelected(true)
				curSelected[ent] = nil
				self.m_curSelectedBones[ent] = true
			end
		end
	end
	return showHoverText
end
function Component:OnCursorTargetChanged(rayInfo)
	local curSelected = self.m_curSelectedBones
	self.m_curSelectedBones = {}
	local showHoverText = false
	local elHoverText = self:GetHoverTextElement()
	if rayInfo.hitData ~= nil then
		if rayInfo.hitData.mesh ~= nil then
			local boneId = pfm.get_bone_index_from_hit_data(rayInfo.hitData)
			if boneId ~= -1 then
				showHoverText = self:SetHoverBone(rayInfo, rayInfo.actor, boneId, curSelected)
			end
		end
		if showHoverText == false then
			local ikControlC = rayInfo.hitData.entity:GetComponent(ents.COMPONENT_PFM_IK_CONTROL)
			if ikControlC ~= nil then
				local boneId = ikControlC:GetBoneId()
				local ikC = ikControlC:GetIkComponent()
				if util.is_valid(ikC) then
					showHoverText = self:SetHoverBone(rayInfo, ikC:GetEntity(), boneId, curSelected)
				end
			end
		end
	end

	elHoverText:SetVisible(showHoverText)
	for ent, _ in pairs(curSelected) do
		if ent:IsValid() then
			self:DeselectBone(ent)
		end
	end
	pfm.tag_render_scene_as_dirty()
end
function Component:OnCursorTargetActorChanged(hitData)
	if util.is_valid(self.m_prevActor) then
		local selC = self.m_prevActor:GetComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
		if selC ~= nil and selC:IsPersistent() == false then
			self:RemoveOutline(self.m_prevActor)
		end
	end
	if util.is_valid(hitData.actor) then
		self.m_prevActor = hitData.actor
		self:AddOutline(hitData.actor)
	end
	pfm.tag_render_scene_as_dirty()
end
function Component:SetProjectManager(pm)
	self.m_projectManager = pm
end
function Component:GetProjectManager()
	return self.m_projectManager
end
function Component:IsRecording()
	return self:GetEntity():HasComponent(ents.COMPONENT_PFM_ANIMATION_RECORDER)
end
function Component:StartRecording()
	self:EndRecording()

	local ent = self:GetEntity()
	local pm = self.m_projectManager
	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) == false then
		return
	end

	local actorProperties = {}
	local props = actorEditor:GetSelectedProperties()
	local hasSelectedProperties = false
	for _, propData in ipairs(props) do
		local path = propData.controlData.path
		local actor = propData.actorData.actor
		local entActor = (actor ~= nil) and actor:FindEntity() or nil
		if util.is_valid(entActor) then
			local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
			if componentName ~= nil then
				actorProperties[entActor] = actorProperties[entActor] or {}
				local actorProps = actorProperties[entActor]
				actorProps[componentName] = actorProps[componentName] or {}
				table.insert(actorProps[componentName], pathName:GetString())
				hasSelectedProperties = true
			end
		end
	end

	if hasSelectedProperties == false then
		pfm.log(
			"Failed to start recording: No animatable properties selected!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	local pfmRecorderC = ent:AddComponent("pfm_animation_recorder")
	if pfmRecorderC ~= nil then
		pfmRecorderC:SetProjectManager(pm)
	end

	self:BroadcastEvent(Component.EVENT_ON_START_RECORDING)

	local recorderC = ent:GetComponent(ents.COMPONENT_PFM_ANIMATION_RECORDER)
	if recorderC ~= nil then
		for actor, props in pairs(actorProperties) do
			pfm.log("Recording properties of actor " .. tostring(actor:GetUuid()) .. "...", pfm.LOG_CATEGORY_PFM)
			recorderC:AddEntity(actor, props)
		end
		recorderC:StartRecording()

		local playbackState = pm:GetPlaybackState()
		playbackState:Play()
	end
end
function Component:EndRecording()
	if self:IsRecording() == false then
		return
	end
	local recorderC = self:GetEntity():GetComponent(ents.COMPONENT_PFM_ANIMATION_RECORDER)
	if recorderC ~= nil then
		recorderC:EndRecording()

		local playbackState = self.m_projectManager:GetPlaybackState()
		playbackState:Pause()
	end

	self:GetEntity():RemoveComponent(ents.COMPONENT_PFM_ANIMATION_RECORDER)
	self:BroadcastEvent(Component.EVENT_ON_END_RECORDING)
end
ents.COMPONENT_PFM_MANAGER = ents.register_component("pfm_manager", Component)
Component.EVENT_ON_START_RECORDING = ents.register_component_event(ents.COMPONENT_PFM_MANAGER, "on_start_recording")
Component.EVENT_ON_END_RECORDING = ents.register_component_event(ents.COMPONENT_PFM_MANAGER, "on_end_recording")
