--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

game.precache_model("error")

local Component = util.register_class("ents.PFMIkControl", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent("pfm_editor_actor") -- Required so the ik control can be detected for mouse hover
	self:AddEntityComponent("debug_dotted_line")

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:OnRemove()
	util.remove(self.m_cbOnClick)
end

function Component:OnClicked(buttonDown, hitPos)
	if buttonDown == false or util.is_valid(self.m_ikC) == false then
		return
	end
	local entTgt = self.m_ikC:GetEntity()
	local mdl = entTgt:GetModel()
	local skeleton = (mdl ~= nil) and mdl:GetSkeleton() or nil
	local bone = (skeleton ~= nil) and skeleton:GetBone(self.m_boneId) or nil
	if bone == nil then
		return
	end
	self:GetEntity():RemoveComponent("transform_controller")
	self:GetEntity():RemoveComponent("util_transform_arrow")
	local trC = self:AddEntityComponent("transform_controller")
	trC:SetSpace(ents.TransformController.SPACE_VIEW)
	trC:SetAxis(ents.TransformController.AXIS_XYZ)

	local pTrC = self:AddEntityComponent("pfm_transform_controller")
	pTrC:SetTransformTarget(entTgt, "ec/ik_solver/control/" .. bone:GetName() .. "/position")

	trC:StartTransform(hitPos)
	return util.EVENT_REPLY_HANDLED
end

function Component:GetIkComponent()
	return self.m_ikC
end
function Component:GetBoneId()
	return self.m_boneId
end

function Component:SetIkControl(ikC, boneId)
	self.m_ikC = ikC
	self.m_boneId = boneId
end

function Component:OnTick()
	if util.is_valid(self.m_ikC) == false then
		return
	end
	local handle = self.m_ikC:GetControl(self.m_boneId)
	if handle == nil then
		return
	end
	local pose = self.m_ikC:GetEntity():GetPose()
	local handlePos = pose * handle:GetTargetPosition()
	self:GetEntity():SetPos(handlePos)

	local lineC = self:GetEntity():GetComponent(ents.COMPONENT_DEBUG_DOTTED_LINE)
	if lineC ~= nil then
		local bone = handle:GetTargetBone()
		local bonePose = pose * math.Transform(bone:GetPos(), bone:GetRot())
		lineC:SetStartPosition(bonePose:GetOrigin())
		lineC:SetEndPosition(handlePos)
	end
end

function Component:OnEntitySpawn()
	local ent = self:GetEntity()
	ent:SetModel("pfm/ik_control")
	self:AddEntityComponent(ents.COMPONENT_BVH)

	local clickC = ent:AddComponent(ents.COMPONENT_CLICK)
	clickC:SetPriority(1) -- Make sure control can be clicked even when obstructed
	self.m_cbOnClick = clickC:AddEventCallback(ents.ClickComponent.EVENT_ON_CLICK, function(button, pressed, hitPos)
		if button ~= input.ACTION_ATTACK then
			return
		end
		return self:OnClicked(pressed, hitPos)
	end)
end
ents.COMPONENT_PFM_IK_CONTROL = ents.register_component("pfm_ik_control", Component)
