--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMCursorTarget",BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:GetLastRayInfo() return self.m_lastRayInfo end
function Component:OnTick(dt)
	local startPos,dir,vpData = ents.ClickComponent.get_ray_data()
	if(startPos == nil) then self:SetNextTick(time.cur_time() +0.2) return end
	local t = time.time_since_epoch()
	local actor,hitPos,pos,hitData = pfm.raycast(startPos,dir,maxDist)
	local dt = time.time_since_epoch() -t
	local prevActor = (self.m_lastRayInfo ~= nil) and self.m_lastRayInfo.actor or nil
	self.m_lastRayInfo = {
		actor = actor,
		hitPos = hitPos,
		startPos = pos,
		hitData = hitData
	}
	self:SetNextTick(time.cur_time() +0.05)

	if(util.is_valid(prevActor) and actor ~= prevActor) then
		self:InvokeEventCallbacks(Component.EVENT_ON_TARGET_CHANGED,{self.m_lastRayInfo,prevActor})
	end
end
ents.COMPONENT_PFM_CURSOR_TARGET = ents.register_component("pfm_cursor_target",Component)
Component.EVENT_ON_TARGET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_CURSOR_TARGET,"on_target_changed")
