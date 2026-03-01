-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function gui.PFMCoreViewportBase:FindBoneUnderCursor(entActor)
	local handled, entBone, hitPosBone, startPos, hitDataBone = ents.ClickComponent.inject_click_input(
		input.ACTION_ATTACK,
		true,
		function(ent)
			local ownableC = ent:GetComponent(ents.COMPONENT_OWNABLE)
			if ownableC == nil or ent:HasComponent(ents.COMPONENT_PFM_BONE) == false then
				return false
			end
			return ownableC:GetOwner() == entActor
		end
	)

	local mdl = entActor:GetModel()
	local skel = (mdl ~= nil) and mdl:GetSkeleton() or nil
	if handled ~= util.EVENT_REPLY_UNHANDLED or not util.is_valid(entBone) then
		local handled, entActor, hitPos, startPos, hitData =
			ents.ClickComponent.inject_click_input(input.ACTION_ATTACK, true)
		if handled == util.EVENT_REPLY_UNHANDLED and hitData.mesh ~= nil then
			local boneId = pfm.get_bone_index_from_hit_data(hitData)
			if boneId ~= -1 then
				local bone = (skel ~= nil) and skel:GetBone(boneId) or nil
				return bone, hitPos
			end
		end
		return
	end
	local boneC = entBone:GetComponent(ents.COMPONENT_PFM_BONE)
	local boneId = boneC:GetBoneId()
	local bone = (skel ~= nil) and skel:GetBone(boneId) or nil
	return bone, hitPosBone
end
function gui.PFMCoreViewportBase:IsActorSelected(entActor)
	local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	if actor == nil then
		return false
	end
	local pm = pfm.get_project_manager()
	if pm.IsActorSelected == nil then
		return false
	end
	return pm:IsActorSelected(actor)
end
function gui.PFMCoreViewportBase:SelectActor(entActor, bone, deselectCurrent)
	local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	if actor == nil then
		return
	end
	local property
	if bone ~= nil then
		local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
		if ikSolverC ~= nil then
			if ikSolverC:GetControl(bone:GetID()) ~= nil then
				-- Prefer ik_solver controls if they exist
				property = "ec/ik_solver/control/" .. bone:GetName()
			end
		end
		property = property or ("ec/animated/bone/" .. bone:GetName() .. "/position")
	end

	local pm = pfm.get_project_manager()
	if pm.SelectActor == nil then
		return
	end
	pm:SelectActor(actor, deselectCurrent, property)
end
function gui.PFMCoreViewportBase:SetActorSelectionDirty()
	self.m_transformWidgetDirty = true
	self:UpdateThinkState()
end
function gui.PFMCoreViewportBase:UpdateMultiActorSelection()
	local actors = pfm.get_project_manager():GetSelectionManager():GetSelectedObjects()
	local n = 0
	for ent, _ in pairs(actors) do
		if ent:IsValid() then
			n = n + 1
			if n > 1 then
				break
			end
		end
	end

	if n > 1 then
		self:CreateMultiActorTransformWidget()
		return true
	end
	return false
end
function gui.PFMCoreViewportBase:ApplySelection()
	if util.is_valid(self.m_selectionRect) == false then
		return false
	end
	-- self:SetCursorTrackerEnabled(false)
	local function getWorldSpacePoint(pos, near)
		local uv = Vector2(pos.x / self.m_viewport:GetWidth(), pos.y / self.m_viewport:GetHeight())
		local cam = self:GetCamera()
		local p = cam:GetPlanePoint(near and cam:GetNearZ() or cam:GetFarZ(), uv)
		return p
	end
	local pos = self.m_selectionRect:GetPos()
	local posEnd = pos + self.m_selectionRect:GetSize()
	local p0n = getWorldSpacePoint(pos, true)
	local p1n = getWorldSpacePoint(Vector2i(posEnd.x, pos.y), true)
	local p2n = getWorldSpacePoint(Vector2i(pos.x, posEnd.y), true)
	local p3n = getWorldSpacePoint(posEnd, true)

	local p0f = getWorldSpacePoint(pos, false)
	local p1f = getWorldSpacePoint(Vector2i(posEnd.x, pos.y), false)
	local p2f = getWorldSpacePoint(Vector2i(pos.x, posEnd.y), false)
	local p3f = getWorldSpacePoint(posEnd, false)

	local planes = {
		math.Plane(p0n, p2n, p1n), -- Front
		math.Plane(p0n, p0f, p2f), -- Left
		math.Plane(p1n, p3f, p1f), -- Right
		math.Plane(p0n, p1n, p0f), -- Top
		math.Plane(p2n, p2f, p3n), -- Bottom
		math.Plane(p0f, p1f, p2f), -- Back
	}

	local results = ents.ClickComponent.find_entities_in_kdop(planes)

	local pm = pfm.get_project_manager()
	if input.is_ctrl_key_down() == false and input.is_alt_key_down() == false then
		pm:DeselectAllActors()
	end
	local selectionManager = pm:GetSelectionManager()
	for _, res in ipairs(results) do
		local actorC = res.entity:GetComponent(ents.COMPONENT_PFM_ACTOR)
		local actor = (actorC ~= nil) and actorC:GetActorData() or nil
		if actor ~= nil then
			if input.is_alt_key_down() then
				pm:DeselectActor(actor)
			else
				pm:SelectActor(actor, false)
			end
		end
	end

	util.remove(self.m_selectionRect)
	return true
end
