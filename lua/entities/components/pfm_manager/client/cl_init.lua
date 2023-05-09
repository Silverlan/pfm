--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_selection_wireframe")
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
function Component:OnCursorTargetChanged(rayInfo)
	local curSelected = self.m_curSelectedBones
	self.m_curSelectedBones = {}
	local showHoverText = false
	local elHoverText = self:GetHoverTextElement()
	if rayInfo.hitData ~= nil and rayInfo.hitData.mesh ~= nil then
		local boneId = pfm.get_bone_index_from_hit_data(rayInfo.hitData)
		if boneId ~= -1 then
			local mdl = rayInfo.actor:GetModel()
			local skel = (mdl ~= nil) and mdl:GetSkeleton() or nil
			local bone = (skel ~= nil) and skel:GetBone(boneId) or nil

			local c = rayInfo.actor:GetComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
			if c ~= nil then
				if bone ~= nil and util.is_valid(rayInfo.vpData.viewport) then
					local animC = rayInfo.actor:GetComponent(ents.COMPONENT_ANIMATED)
					local pos = (animC ~= nil) and animC:GetGlobalBonePose(boneId):GetOrigin() or nil
					if pos ~= nil then
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
ents.COMPONENT_PFM_MANAGER = ents.register_component("pfm_manager", Component)
