--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMViewport:FindBoneUnderCursor(entActor)
	local handled,entBone,hitPosBone,startPos,hitDataBone = ents.ClickComponent.inject_click_input(input.ACTION_ATTACK,true,function(ent)
		local ownableC = ent:GetComponent(ents.COMPONENT_OWNABLE)
		if(ownableC == nil or ent:HasComponent(ents.COMPONENT_PFM_BONE) == false) then return false end
		return ownableC:GetOwner() == entActor
	end)

	local mdl = entActor:GetModel()
	local skel = (mdl ~= nil) and mdl:GetSkeleton() or nil
	if(handled ~= util.EVENT_REPLY_UNHANDLED or not util.is_valid(entBone)) then
		local handled,entActor,hitPos,startPos,hitData = ents.ClickComponent.inject_click_input(input.ACTION_ATTACK,true)
		if(handled == util.EVENT_REPLY_UNHANDLED and hitData.mesh ~= nil) then
			-- Try to determine bone by vertex weight of selected triangle
			local vws = {
				hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex *3)),
				hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex *3 +1)),
				hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex *3 +2))
			}

			local vWeights = {1.0 -hitData.u,1.0 -hitData.v,hitData.u +hitData.v}
			local accWeights = {}
			for i=0,3 do
				for j,vw in ipairs(vws) do
					local boneId = vw.boneIds:Get(i)
					if(boneId ~= -1) then
						accWeights[boneId] = accWeights[boneId] or 0.0
						accWeights[boneId] = accWeights[boneId] +vw.weights:Get(i) *vWeights[j]
					end
				end
			end

			local largestWeight = -1.0
			local boneId = -1
			for accBoneId,accWeight in pairs(accWeights) do
				if(accWeight > largestWeight) then
					largestWeight = accWeight
					boneId = accBoneId
				end
			end

			if(boneId ~= -1) then
				local bone = (skel ~= nil) and skel:GetBone(boneId) or nil
				return bone,hitPos
			end
		end
		return
	end
	local boneC = entBone:GetComponent(ents.COMPONENT_PFM_BONE)
	local boneId = boneC:GetBoneId()
	local bone = (skel ~= nil) and skel:GetBone(boneId) or nil
	return bone,hitPosBone
end
function gui.PFMViewport:SelectActor(entActor,bone,deselectCurrent)
	local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	if(actor == nil) then return end
	local property
	if(bone ~= nil) then
		local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
		if(ikSolverC ~= nil) then
			if(ikSolverC:GetControl(bone:GetID()) ~= nil) then
				-- Prefer ik_solver controls if they exist
				property = "ec/ik_solver/control/" .. bone:GetName()
			end
		end
		property = property or ("ec/animated/bone/" .. bone:GetName() .. "/position")
	end

	tool.get_filmmaker():SelectActor(actor,deselectCurrent,property)
end
function gui.PFMViewport:UpdateMultiActorSelection()
	local actors = tool.get_filmmaker():GetSelectionManager():GetSelectedActors()
	local n = 0
	for ent,_ in pairs(actors) do
		if(ent:IsValid()) then
			n = n +1
			if(n > 1) then break end
		end
	end

	if(n > 1) then
		self:CreateMultiActorTransformWidget()
		return true
	end
	return false
end
function gui.PFMViewport:OnActorSelectionChanged(ent,selected)
	if(self:UpdateMultiActorSelection()) then return end
	self:UpdateActorManipulation(ent,selected)
	self:UpdateManipulationMode()
end
function gui.PFMViewport:ApplySelection()
	if(util.is_valid(self.m_selectionRect) == false) then return false end
	-- self:SetCursorTrackerEnabled(false)
	local function getWorldSpacePoint(pos,near)
		local uv = Vector2(
			pos.x /self.m_viewport:GetWidth(),
			pos.y /self.m_viewport:GetHeight()
		)
		local cam = self:GetCamera()
		local p = cam:GetPlanePoint(near and cam:GetNearZ() or cam:GetFarZ(),uv)
		return p
	end
	local pos = self.m_selectionRect:GetPos()
	local posEnd = pos +self.m_selectionRect:GetSize()
	local p0n = getWorldSpacePoint(pos,true)
	local p1n = getWorldSpacePoint(Vector2i(posEnd.x,pos.y),true)
	local p2n = getWorldSpacePoint(Vector2i(pos.x,posEnd.y),true)
	local p3n = getWorldSpacePoint(posEnd,true)

	local p0f = getWorldSpacePoint(pos,false)
	local p1f = getWorldSpacePoint(Vector2i(posEnd.x,pos.y),false)
	local p2f = getWorldSpacePoint(Vector2i(pos.x,posEnd.y),false)
	local p3f = getWorldSpacePoint(posEnd,false)

	local planes = {
		math.Plane(p0n,p2n,p1n), -- Front
		math.Plane(p0n,p0f,p2f), -- Left
		math.Plane(p1n,p3f,p1f), -- Right
		math.Plane(p0n,p1n,p0f), -- Top
		math.Plane(p2n,p2f,p3n), -- Bottom
		math.Plane(p0f,p1f,p2f) -- Back
	}

	local results = ents.ClickComponent.find_entities_in_kdop(planes)

	local pm = tool.get_filmmaker()
	if(input.is_ctrl_key_down() == false and input.is_alt_key_down() == false) then pm:DeselectAllActors() end
	local selectionManager = pm:GetSelectionManager()
	for _,res in ipairs(results) do
		local actorC = res.entity:GetComponent(ents.COMPONENT_PFM_ACTOR)
		local actor = (actorC ~= nil) and actorC:GetActorData() or nil
		if(actor ~= nil) then
			if(input.is_alt_key_down()) then pm:DeselectActor(actor)
			else pm:SelectActor(actor,false) end
		end
	end

	util.remove(self.m_selectionRect)
	self:DisableThinking()
	return true
end
