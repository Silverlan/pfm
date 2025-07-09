-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.UtilBoneTransformComponent", BaseEntityComponent)

function ents.UtilBoneTransformComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_transforms = {}
end
function ents.UtilBoneTransformComponent:OnRemove()
	for boneId, ent in pairs(self.m_transforms) do
		if ent:IsValid() then
			ent:Remove()
		end
	end
end
function ents.UtilBoneTransformComponent:SetTransformEnabled(boneId)
	if type(boneId) == "string" then
		local mdl = self:GetEntity():GetModel()
		if mdl == nil then
			return
		end
		boneId = mdl:LookupBone(boneId)
	end
	if boneId == -1 then
		return
	end
	if util.is_valid(self.m_transforms[boneId]) then
		return self.m_transforms[boneId]:GetComponent("util_transform")
	end
	local ent = self:GetEntity():CreateChild("util_transform")
	ent:AddComponent("pfm_transform_gizmo")
	ent:Spawn()
	self.m_transforms[boneId] = ent

	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if animC ~= nil then
		local pose = animC:GetBonePose(boneId, math.COORDINATE_SPACE_WORLD)
		if pose ~= nil then
			ent:SetPose(pose)
		end
	end

	local utilTransformC = ent:GetComponent("util_transform")
	if utilTransformC ~= nil then
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED, function(pos)
			local localPos = pos:Copy()
			if animC ~= nil then
				local pose = animC:GetBonePose(boneId, math.COORDINATE_SPACE_WORLD)
				pose:SetOrigin(pos)
				animC:SetBonePose(boneId, posemath.COORDINATE_SPACE_WORLD)

				localPos = animC:GetBonePos(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED, { boneId, pos, localPos })
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED, function(rot)
			local localRot = rot:Copy()
			if animC ~= nil then
				local pose = animC:GetBonePose(boneId, math.COORDINATE_SPACE_WORLD)
				pose:SetRotation(rot)
				animC:SetBonePose(boneId, posemath.COORDINATE_SPACE_WORLD)

				localRot = animC:GetBoneRot(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED, { boneId, rot, localRot })
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED, function(scale)
			if animC ~= nil then
				local pose = animC:GetBonePose(boneId, math.COORDINATE_SPACE_WORLD)
				pose:SetScale(scale)
				animC:SetBonePose(boneId, posemath.COORDINATE_SPACE_WORLD)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED, { boneId, scale, scale })
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END, function()
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_TRANSFORM_END)
		end)
		utilTransformC:SetParentBone(boneId)
	end
	return ent:GetComponent("util_transform")
end
ents.register_component(
	"util_bone_transform",
	ents.UtilBoneTransformComponent,
	"pfm",
	ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR
)
ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED =
	ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM, "on_pos_changed")
ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED =
	ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM, "on_rot_changed")
ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED =
	ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM, "on_scale_changed")
ents.UtilBoneTransformComponent.EVENT_ON_TRANSFORM_END =
	ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM, "on_transform_end")
