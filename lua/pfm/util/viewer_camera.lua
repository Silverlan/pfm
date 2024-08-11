--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("meta_rig.lua")

pfm.util.align_viewer_camera_to_head = function(ent, vc, xang, yang, zoomFactor)
	local model = ent:GetModelName()
	if model == nil then
		return false
	end
	local headData = pfm.util.get_character_head_data(model)
	if headData == nil or headData.headBounds[1]:DistanceSqr(headData.headBounds[2]) <= 0.001 then
		return false
	end

	local mdl = ent:GetModel()
	local metaRig = mdl:GetMetaRig()
	if metaRig ~= nil then
		ent:SetRotation(metaRig.forwardFacingRotationOffset)
	end
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if animC ~= nil then
		-- If the model is a character, we'll zoom in on the head
		local pose = animC:GetBonePose(headData.headBoneId, math.COORDINATE_SPACE_WORLD)
		local poseParent = animC:GetBonePose(headData.headParentBoneId, math.COORDINATE_SPACE_WORLD)
		if pose ~= nil and poseParent ~= nil then
			pose:SetOrigin(pose:GetOrigin() + (poseParent:GetOrigin() - pose:GetOrigin()) * 0.7)
			local min = pose * (headData.headBounds[1] * 1.2)
			local max = pose * (headData.headBounds[2] * 1.2)
			vc:FitViewToScene(min, max)

			vc:SetRotation(0.0, 0.0)
			vc:Rotate(xang or 0, yang or 0)
			vc:FitZoomToExtents(min, max)

			-- Zoom out a little bit
			vc:SetZoom((vc:GetZoom() + math.abs(max.z - min.z)) * (zoomFactor or 1.0))

			local mdl = ent:GetModel()
			if mdl ~= nil then
				local mdlMin, mdlMax = mdl:GetRenderBounds()
				local isYDominant = math.abs(mdlMax.y - mdlMin.y)
					> math.max(math.abs(mdlMax.x - mdlMin.x), math.abs(mdlMax.z - mdlMin.z))
				if isYDominant then
					-- If the model is larger on the y axis, we'll assume it's a humanoid character model.
					-- In this case we'll move the camera slightly downwards and adjust the camera angle
					-- to get a nicer perspective.
					local lt = vc:GetLookAtTarget()
					lt.y = lt.y - math.abs(max.y - min.y) * 0.35
					vc:SetLookAtTarget(lt)
					vc:Rotate(0, 10)
					vc:UpdatePosition()
				end
			end
			return true
		end
	end
	return false
end
