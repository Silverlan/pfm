--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util = util or {}

util.retarget = util.retarget or {}

util.retarget.change_actor_model = function(actorC, mdlName)
	console.run("asset_clear_unused") -- Clear all unused assets, so we don't run into memory issues
	actorC:SetDefaultRenderMode(game.SCENE_RENDER_PASS_WORLD)

	local impersonateeC = actorC:GetEntity():AddComponent("impersonatee")
	if impersonateeC == nil then
		return
	end
	impersonateeC:SetImpostorModel(mdlName)

	local impostorC = impersonateeC:GetImpostor()
	if util.is_valid(impostorC) == false then
		return
	end
	local entImpostor = impostorC:GetEntity()

	local impersonated = impersonateeC:IsImpersonated()
	actorC:SetDefaultRenderMode(impersonated and game.SCENE_RENDER_PASS_NONE or game.SCENE_RENDER_PASS_WORLD)

	local entActor = actorC:GetEntity()
	if entActor:HasComponent("click") then
		entImpostor:AddComponent("click")
	end
	if entActor:HasComponent("bvh") then
		entImpostor:AddComponent("bvh")
	end

	-- TODO: We shouldn't have to do this!
	local renderC = entImpostor:GetComponent(ents.COMPONENT_RENDER)
	if renderC ~= nil then
		renderC:SetExemptFromOcclusionCulling(true)
	end

	if impersonated == false then
		actorC:GetEntity():SetPose(actorC:GetEntity():GetPose())
	end -- We have to reset the actor's pose, I'm not sure why
	return entImpostor
end

util.retarget.get_impersonatee = function(actor)
	local targetActor = actor
	local imposterC = actor:GetComponent("impostor")
	if imposterC ~= nil then
		local impersonatee = imposterC:GetImpersonatee()
		if util.is_valid(impersonatee) then
			targetActor = impersonatee:GetEntity()
		end
	end
	return targetActor
end

util.retarget.retarget_actor = function(targetActor, mdlName)
	targetActor = util.retarget.get_impersonatee(targetActor)
	if util.is_valid(targetActor) == false then
		return false
	end
	local srcModelName = targetActor:GetModelName()

	local skeleton = true
	local flexController = true
	local headControllerC = targetActor:GetComponent(ents.COMPONENT_HEAD_CONTROLLER)
	local headTarget = (headControllerC ~= nil) and headControllerC:GetHeadTarget() or nil
	if util.is_valid(headTarget) then
		local headModel = headTarget:GetModelName()
		if #headModel > 0 then
			-- Flex retargeting uses a different head model, so we'll try to retarget that first.
			-- We don't care about the result. If it fails, flexes will not work unless retargeted manually.
			if file.exists(ents.RetargetRig.Rig.get_rig_file_path(headModel, mdlName):GetString()) == false then
				ents.RetargetRig.Rig.find_and_import_viable_retarget_rig(headModel, mdlName, false, true)
			end
			flexController = false
		end
	end
	local res = file.exists(ents.RetargetRig.Rig.get_rig_file_path(srcModelName, mdlName):GetString())
	if res == false then
		res = ents.RetargetRig.Rig.find_and_import_viable_retarget_rig(srcModelName, mdlName, skeleton, flexController)
	end
	if res == false then
		return false, targetActor, srcModelName
	end
	local actorC = targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		util.retarget.change_actor_model(actorC, mdlName)
	end
	return res, targetActor, srcModelName
end
