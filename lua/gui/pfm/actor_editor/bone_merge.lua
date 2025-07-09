-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function gui.PFMActorEditor:BoneMerge(srcActor, targetActor, cmd)
	local targetModelC = targetActor:FindComponent("model")
	local srcModelC = srcActor:FindComponent("model")
	if targetModelC == nil or srcModelC == nil then
		return
	end
	local mdlTgt = targetModelC:GetMemberValue("model")
	local mdlSrc = srcModelC:GetMemberValue("model")
	if mdlTgt == nil or mdlSrc == nil then
		return
	end
	local mdl = game.load_model(mdlSrc)
	mdlTgt = game.load_model(mdlTgt)
	if mdl == nil or mdlTgt == nil then
		return
	end

	local pfmTargetActorC = targetActor:FindComponent("pfm_actor")
	if pfmTargetActorC == nil then
		return
	end

	local pfmActorC = self:CreateNewActorComponent(srcActor, "pfm_actor", false)
	pfmActorC:SetMemberValue("position", udm.TYPE_VECTOR3, pfmTargetActorC:GetMemberValue("position"))
	pfmActorC:SetMemberValue("rotation", udm.TYPE_QUATERNION, pfmTargetActorC:GetMemberValue("rotation"))
	pfmActorC:SetMemberValue("scale", udm.TYPE_VECTOR3, pfmTargetActorC:GetMemberValue("scale"))
	self:CreateNewActorComponent(srcActor, "animated", false)

	if ents.BoneMergeComponent.can_merge(mdl, mdlTgt) then
		local boneMergeC = self:CreateNewActorComponent(srcActor, "bone_merge", false)
		boneMergeC:SetMemberValue("target", udm.TYPE_STRING, tostring(targetActor:GetUniqueId()))
	end

	if ents.FlexMergeComponent.can_merge(mdl, mdlTgt) then
		local flexMergeC = self:CreateNewActorComponent(srcActor, "flex_merge", false)
		flexMergeC:SetMemberValue("target", udm.TYPE_STRING, tostring(targetActor:GetUniqueId()))
	end

	self:UpdateActorComponents(srcActor)
	self:AddConstraint(
		gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF,
		srcActor,
		"ec/pfm_actor/pose",
		targetActor,
		"ec/pfm_actor/pose",
		cmd
	)
	return actor
end
