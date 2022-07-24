--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMCuboidBounds",BaseEntityComponent)
Component:RegisterMember("MinBounds",udm.TYPE_VECTOR3,Vector(0,0,0),{
	onChange = function(self)
		self:UpdateDebugBounds()
		local min,max = self:GetBounds()
		self:BroadcastEvent(Component.EVENT_ON_BOUNDS_CHANGED,{min,max})
	end
})
Component:RegisterMember("MaxBounds",udm.TYPE_VECTOR3,Vector(0,0,0),{
	onChange = function(self)
		self:UpdateDebugBounds()
		local min,max = self:GetBounds()
		self:BroadcastEvent(Component.EVENT_ON_BOUNDS_CHANGED,{min,max})
	end
})
Component:RegisterMember("ShowDebugBounds",udm.TYPE_BOOLEAN,false,{
	onChange = function(self)
		self:UpdateDebugBounds()
	end
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnRemove()
	util.remove(self.m_dbgBox)
end
function Component:UpdateDebugBounds()
	util.remove(self.m_dbgBox)
	if(self:GetShowDebugBounds() == false) then return end
	local min,max = self:GetBounds()
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(Color(0,0,255,64))
	drawInfo:SetOutlineColor(Color.Red)
	self.m_dbgBox = debug.draw_box(min,max,drawInfo)
end
function Component:GetBounds()
	local minArea = self:GetMinBounds()
	local maxArea = self:GetMaxBounds()
	vector.to_min_max(minArea,maxArea)
	return minArea,maxArea
end
ents.COMPONENT_PFM_CUBOID_BOUNDS = ents.register_component("pfm_cuboid_bounds",Component)
Component.EVENT_ON_BOUNDS_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_CUBOID_BOUNDS,"on_bounds_changed")
