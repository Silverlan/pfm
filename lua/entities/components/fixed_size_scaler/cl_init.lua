-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.FixedSizeScalerComponent", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:SetCamera(cam)
	self.m_cam = cam
end
function Component:SetBaseScale(scale)
	self.m_baseScale = scale
end
function Component:OnTick(dt)
	self:UpdateScale() -- TODO: This doesn't belong here, move it to a render callback
end
function Component:UpdateScale()
	local cam = self.m_cam
	if util.is_valid(cam) == false then
		cam = game.get_render_scene_camera()
	end
	if util.is_valid(cam) == false then
		return
	end
	local entCam = cam:GetEntity()
	local plane = math.Plane(entCam:GetForward(), 0)
	plane:MoveToPos(entCam:GetPos())

	local ent = self:GetEntity()
	local pos = ent:GetPos()
	local p = pos:ProjectToPlane(plane:GetNormal(), plane:GetDistance())
	local d = pos:Distance(p)

	d = d * cam:GetFOVRad() * 0.01 -- Resize according to distance to camera
	d = d * (self.m_baseScale or 1.0)
	ent:SetScale(Vector(d, d, d))
end
ents.register_component("fixed_size_scaler", Component, "util", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
