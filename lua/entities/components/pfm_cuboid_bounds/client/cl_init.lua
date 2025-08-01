-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMCuboidBounds", BaseEntityComponent)
Component:RegisterMember("MinBounds", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = function(self)
		self:UpdateDebugBounds()
		local min, max = self:GetBounds()
		self:BroadcastEvent(Component.EVENT_ON_BOUNDS_CHANGED, { min, max })
	end,
})
Component:RegisterMember("MaxBounds", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = function(self)
		self:UpdateDebugBounds()
		local min, max = self:GetBounds()
		self:BroadcastEvent(Component.EVENT_ON_BOUNDS_CHANGED, { min, max })
	end,
})
Component:RegisterMember("ShowDebugBounds", udm.TYPE_BOOLEAN, false, {
	onChange = function(self)
		self:UpdateDebugBounds()
	end,
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnRemove()
	util.remove(self.m_dbgBox)
end
function Component:UpdateDebugBounds()
	util.remove(self.m_dbgBox)
	if self:GetShowDebugBounds() == false then
		return
	end
	local min, max = self:GetBounds()
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(Color(0, 0, 255, 64))
	drawInfo:SetOutlineColor(Color.Red)
	self.m_dbgBox = debug.draw_box(min, max, drawInfo)
end
function Component:GetBounds()
	local minArea = self:GetMinBounds()
	local maxArea = self:GetMaxBounds()
	minArea, maxArea = vector.to_min_max(minArea, maxArea)
	return minArea, maxArea
end
ents.register_component("pfm_cuboid_bounds", Component, "pfm")
Component.EVENT_ON_BOUNDS_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_CUBOID_BOUNDS, "on_bounds_changed")
