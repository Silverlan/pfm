--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMIkControl", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	if ik == nil then
		engine.load_library("pr_ik")
		if ik == nil then
			return -- IK not available
		end
	end

	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent("pfm_editor_actor") -- Required so the ik control can be detected for mouse hover
	self:AddEntityComponent("debug_dotted_line")
	self:BindEvent(ents.TransformComponent.EVENT_ON_POSE_CHANGED, "OnPoseChanged")
	self.m_debugBoxC = self:AddEntityComponent(ents.COMPONENT_DEBUG_BOX)
	local scalerC = self:AddEntityComponent("fixed_size_scaler")
	scalerC:SetBaseScale(1.5)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

	self:UpdateDebugBoxScale()
end

function Component:UpdateDebugBoxScale()
	if util.is_valid(self.m_debugBoxC) == false then
		return
	end
	local scale = self:GetEntity():GetScale()
	self.m_debugBoxC:SetBounds(-scale, scale)
end

function Component:OnPoseChanged()
	self:UpdateDebugBoxScale()
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
	local propName = "ec/ik_solver/control/" .. bone:GetName() .. "/position"
	pTrC:SetTransformTarget(entTgt, propName)

	trC:StartTransform(hitPos)

	local pm = pfm.get_project_manager()
	if util.is_valid(pm) and pm.SelectActor ~= nil then
		local actor = pfm.dereference(entTgt:GetUuid())
		if actor ~= nil then
			pm:SelectActor(actor, true, propName)
			-- Also select rotation property if available. This will make it faster to create constraints
			-- that affect both the position and rotation.
			pm:SelectActor(actor, false, "ec/ik_solver/control/" .. bone:GetName() .. "/rotation")
		end
	end

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

	local baseColor = Color.White
	if util.is_valid(self.m_ikC) then
		local handle = self.m_ikC:GetControl(self.m_boneId)
		if handle ~= nil then
			local type = handle:GetType()
			local colors = {
				[ik.Control.TYPE_DRAG] = Color.Yellow,
				[ik.Control.TYPE_ANGULAR_PLANE] = Color.Pink,
				[ik.Control.TYPE_STATE] = Color.OrangeRed,
				[ik.Control.TYPE_ORIENTED_DRAG] = Color.LimeGreen,
			}
			baseColor = colors[type] or baseColor
		end
	end
	baseColor = baseColor:Copy()

	self.m_debugBoxC:SetColorOverride(baseColor)
	self.m_debugBoxC:SetIgnoreDepthBuffer(true)
	baseColor.a = 180
	self:GetEntity():SetColor(baseColor)

	--[[
	-- Scale according to bone size
	local ent = ikC:GetEntity()
	local mdl = ent:GetModel()
	if mdl == nil then
		return
	end
	local len = mdl:CalcBoneLength(boneId)
	len = len / 4.0
	self:GetEntity():SetScale(Vector(len, len, len))
	]]
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
