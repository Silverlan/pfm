--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raycast.lua")

util.register_class("ents.PFMGhost", BaseEntityComponent)

function ents.PFMGhost:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	-- self:AddEntityComponent("pfm_grid") -- TODO: UNDO ME

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.PFMGhost:SetPlacementCallback(cb)
	self.m_placementCallback = cb
end

local function find_actor_under_cursor(pos, dir)
	local pl = ents.get_local_player()
	if pl == nil then
		return
	end
	local entPl = pl:GetEntity()
	local distClosest = math.huge
	local actorClosest = nil
	local hitPos
	for ent in
		ents.iterator({
			ents.IteratorFilterComponent(ents.COMPONENT_MODEL),
			ents.IteratorFilterComponent(ents.COMPONENT_RENDER),
		})
	do
		local mdl = ent:GetModel()
		local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		if
			mdl ~= nil
			and ent ~= entPl
			and renderC ~= nil
			and renderC:GetSceneRenderPass() ~= game.SCENE_RENDER_PASS_VIEW
		then
			local r, hitData = renderC:CalcRayIntersection(pos, dir * 32768)
			if r == intersect.RESULT_INTERSECT and hitData.distance < distClosest then
				distClosest = hitData.distance
				hitPos = hitData.position
				actorClosest = ent
			end
		end
	end
	return actorClosest, hitPos
end

function ents.PFMGhost:SetHoverMode(b)
	self.m_hoverMode = b
end

function ents.PFMGhost:SetViewport(vp)
	self.m_viewport = vp
end

function ents.PFMGhost:GetAttachmentTarget()
	if self.m_lastHitActorData == nil or util.is_valid(self.m_lastHitActorData.hitActorAnimC) == false then
		return
	end
	local actorC = self.m_lastHitActorData.hitActorAnimC:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC == nil then
		return
	end
	local mdlTarget = actorC:GetEntity():GetModel()
	if mdlTarget == nil then
		return
	end
	local boneTarget = mdlTarget:GetSkeleton():GetBone(self.m_lastHitActorData.hitActorBone)
	if boneTarget == nil then
		return
	end
	local mdlSelf = self:GetEntity():GetModel()
	if mdlSelf == nil then
		return
	end
	local boneSelf = mdlSelf:GetSkeleton():GetBone(self.m_lastHitActorData.selfBone)
	if boneSelf == nil then
		return
	end
	return boneSelf:GetName(), actorC:GetActorData(), boneSelf:GetName()
end

function ents.PFMGhost:UpdateAttachmentActor(hitActor)
	if self.m_lastHitActorData == nil or hitActor ~= self.m_lastHitActorData.hitActor then
		local data = {}
		data.hitActor = hitActor
		if hitActor ~= nil then
			local animC = hitActor:GetComponent(ents.COMPONENT_ANIMATED)
			local ent = self:GetEntity()
			local mdl = ent:GetModel()
			local mdlHitActor = hitActor:GetModel()
			if animC ~= nil and mdl ~= nil and mdlHitActor ~= nil then
				local skeleton = mdl:GetSkeleton()
				for _, rootBone in pairs(skeleton:GetRootBones()) do
					local boneId = mdlHitActor:LookupBone(rootBone:GetName())
					if boneId ~= -1 then
						local ref = mdl:GetReferencePose()
						local pose = ref:GetBonePose(rootBone:GetID())
						data.selfBone = rootBone:GetID()
						data.selfRootBonePose = pose:GetInverse()
						data.hitActorBone = boneId
						data.hitActorAnimC = animC
						break
					end
				end
			end
		end
		self.m_lastHitActorData = data
	end

	local data = self.m_lastHitActorData
	if data ~= nil and util.is_valid(data.hitActorAnimC) then
		local pose = data.hitActorAnimC:GetGlobalBonePose(data.hitActorBone)
		if pose ~= nil then
			pose = pose * data.selfRootBonePose
			return pose:GetOrigin(), pose:GetRotation()
		end
	end
end

function ents.PFMGhost:OnTick()
	if util.is_valid(self.m_viewport) == false then
		return
	end
	local viewport = self.m_viewport

	local startPos, dir, vpData = ents.ClickComponent.get_ray_data()
	if startPos == nil then
		return
	end

	local ent = self:GetEntity()
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)

	local maxDist = 2048.0
	local actor, hitPos, pos, hitData = pfm.raycast(startPos, dir, maxDist)
	local mainActor = actor
	local hasHit = (hitPos ~= nil)
	local posDst = hitPos
	if posDst == nil and util.is_valid(vpData.camera) then
		local min, max = Vector(), Vector()
		if renderC ~= nil then
			min, max = renderC:GetLocalRenderBounds()
		end
		local maxAxisLength = math.max(max.x - min.x, max.y - min.y, max.z - min.z)
		posDst = startPos + dir * (maxAxisLength + 20.0) -- Move position away from camera

		-- Since we have no level as reference, we'll try to find a good position for placing the object
		-- by creating an implicit plane relative to the camera (angled by 20 degrees)
		local rot = vpData.camera:GetEntity():GetRotation()
		rot = rot * EulerAngles(-20, 0, 0):ToQuaternion()
		local planeUp = rot:GetUp()
		local d = planeUp:DotProduct(startPos)
		local t = intersect.line_with_plane(startPos, dir * maxDist, planeUp, -d + 60.0)
		if t ~= false then
			posDst = startPos + dir * maxDist * t
		end
	end

	--debug.draw_line(Vector(),posDst,Color.Red,12)
	--print(ray.entity)

	if
		input.get_key_state(input.KEY_LEFT_SHIFT) == input.STATE_RELEASE
		and input.get_key_state(input.KEY_RIGHT_SHIFT) == input.STATE_RELEASE
	then
		if hasHit then
			startPos = posDst - dir * 1.0 + Vector(0, 10, 0)
			local dstPos = posDst - dir * 1.0 - Vector(0, 50, 0)
			local dir = (dstPos - startPos)
			maxDist = dir:Length()
			if maxDist > 0.0 then
				dir = dir / maxDist
			end

			actor, hitPos, pos = pfm.raycast(startPos, dir, maxDist)
			if hitPos ~= nil then
				posDst = hitPos
			end
		end
	end
	if renderC ~= nil then
		local min, max = renderC:GetLocalRenderBounds()
		-- debug.draw_box(ent:GetPos() +min,ent:GetPos() +max,Color.Red,0.1)
		max.y = 0
		min.y = 0
		posDst = posDst - (max + min) / 2.0
	end
	if
		input.get_key_state(input.KEY_LEFT_SHIFT) == input.STATE_RELEASE
		and input.get_key_state(input.KEY_RIGHT_SHIFT) == input.STATE_RELEASE
	then
		local spacing = pfm.get_snap_to_grid_spacing()
		if spacing ~= 0 then
			posDst.x = math.snap_to_gridf(posDst.x, spacing)
			posDst.z = math.snap_to_gridf(posDst.z, spacing)
		end
	end
	if renderC ~= nil then
		local min, max = renderC:GetLocalRenderBounds()
		posDst.y = posDst.y - min.y
	end
	if self.m_placementCallback ~= nil and hasHit then
		self.m_placementCallback(posDst, startPos, dir)
	end
	if posDst ~= nil then
		ent:SetPos(posDst)
	end

	if self.m_hoverMode then
		local actorClosest, hitPos = find_actor_under_cursor(pos, dir)
		if actorClosest ~= nil then
			ent:SetPos(hitPos + Vector(0, 50, 0))
		end
	end

	if hasHit then
		local forward = vector.FORWARD
		local dir = Vector(0, 1, 0) -- hitData:CalcHitNormal()
		if dir ~= nil then
			if math.abs(dir:DotProduct(forward)) > 0.99 then
				forward = vector.RIGHT
			end
			local rot = Quaternion(forward, dir)
			ent:SetRotation(rot)
		end
	end

	if self.m_isArticulatedModel == nil then
		local mdl = self:GetEntity():GetModel()
		if mdl ~= nil then
			self.m_isArticulatedModel = pfm.is_articulated_model(mdl)
		end
	end
	if self.m_isArticulatedModel == false then
		-- Attachment preview
		local hitActor = mainActor
		if util.is_valid(mainActor) == false or input.is_alt_key_down() then
			hitActor = nil
		end
		local newPos, newRot = self:UpdateAttachmentActor(hitActor)
		if newPos ~= nil then
			ent:SetPos(newPos)
			ent:SetRotation(newRot)
		end
	end
end
ents.COMPONENT_PFM_GHOST = ents.register_component("pfm_ghost", ents.PFMGhost)
