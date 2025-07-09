-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.DebugBvhMesh", BaseEntityComponent)
local Component = ents.DebugBvhMesh

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnEntitySpawn()
	local bvhC = self:GetEntity():GetComponent(ents.COMPONENT_BVH)
	if bvhC == nil then
		bvhC = self:GetEntity():GetComponent(ents.COMPONENT_STATIC_BVH_CACHE)
	end
	if bvhC == nil then
		return
	end
	local numTris = bvhC:GetTriangleCount()
	local pose = self:GetEntity():GetPose()
	local dbgVerts = {}
	for i = 1, numTris * 3 do
		local v = bvhC:GetVertex(i - 1)
		v = pose * v
		table.insert(dbgVerts, v)
		if #dbgVerts == 1872457 then
			break
		end
	end
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(Color(255, 0, 0, 64))
	drawInfo:SetOutlineColor(Color.White)
	self.m_dbgMesh = debug.draw_mesh(dbgVerts, drawInfo)
end

function Component:OnRemove()
	util.remove(self.m_dbgMesh)
end
ents.register_component("debug_bvh_mesh", Component, "debug")
