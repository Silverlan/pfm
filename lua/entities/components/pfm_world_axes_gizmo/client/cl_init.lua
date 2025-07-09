-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMWorldAxesGizmo", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_TOGGLE)
	self:AddEntityComponent("pfm_overlay_object")

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "UpdateGizmo")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "UpdateGizmo")

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnRemove()
	util.remove(self.m_debugObject)
	util.remove(self.m_cbUpdate)
end
function Component:UpdateGizmo()
	if self:GetEntity():IsEnabled() == false then
		util.remove(self.m_debugObject)
		util.remove(self.m_cbUpdate)
		return
	end
	if util.is_valid(self.m_debugObject) then
		return
	end
	local l = 1
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(Color.Red)
	local o0 = debug.draw_line(Vector(0, 0, 0), Vector(l, 0, 0), drawInfo)
	drawInfo:SetColor(Color.Green)
	local o1 = debug.draw_line(Vector(0, 0, 0), Vector(0, l, 0), drawInfo)
	drawInfo:SetColor(Color.Blue)
	local o2 = debug.draw_line(Vector(0, 0, 0), Vector(0, 0, l), drawInfo)
	self.m_debugObject = debug.create_collection({ o0, o1, o2 })
	self.m_cbUpdate = game.add_callback("PreRenderScenes", function()
		self:UpdatePos()
	end)
end
function Component:UpdatePos()
	if util.is_valid(self.m_debugObject) == false then
		return
	end
	local pm = tool.get_filmmaker()
	local vp = util.is_valid(pm) and pm:GetViewport() or nil
	vp = util.is_valid(vp) and vp:GetViewport() or nil
	local scene = util.is_valid(vp) and vp:GetScene() or nil
	local cam = util.is_valid(scene) and scene:GetActiveCamera() or nil
	if util.is_valid(cam) == false then
		return
	end
	local np = cam:GetNearPlanePoint(Vector2(1, 0))
	local npL = cam:GetNearPlanePoint(Vector2(0, 0))
	local npB = cam:GetNearPlanePoint(Vector2(1, 1))
	local fp = cam:GetFarPlanePoint(Vector2(1, 0))
	local dir = (fp - np):GetNormal()

	local pos = np + dir * 20 + (np - npL):GetNormal() * -2.5 + (npB - np):GetNormal() * 2.5
	self:GetEntity():SetPos(pos)
	self.m_debugObject:SetPos(self:GetEntity():GetPos())
end
function Component:OnEntitySpawn()
	self:UpdateGizmo()
end
ents.register_component("pfm_world_axes_gizmo", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
