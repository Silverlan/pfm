--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMGhost",BaseEntityComponent)

function ents.PFMGhost:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	-- self:AddEntityComponent("pfm_grid") -- TODO: UNDO ME

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.PFMGhost:SetPlacementCallback(cb) self.m_placementCallback = cb end

local function find_actor_under_cursor(pos,dir)
	local pl = ents.get_local_player()
	if(pl == nil) then return end
	local entPl = pl:GetEntity()
	local distClosest = math.huge
	local actorClosest = nil
	local hitPos
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_MODEL),ents.IteratorFilterComponent(ents.COMPONENT_RENDER)}) do
		local mdl = ent:GetModel()
		local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		if(mdl ~= nil and ent ~= entPl and renderC ~= nil and renderC:GetRenderMode() ~= ents.RenderComponent.RENDERMODE_VIEW) then
			local r,hitData = renderC:CalcRayIntersection(pos,dir *32768)
			if(r == intersect.RESULT_INTERSECT and hitData.distance < distClosest) then
				distClosest = hitData.distance
				hitPos = hitData.position
				actorClosest = ent
			end
		end
	end
	return actorClosest,hitPos
end

function ents.PFMGhost:SetHoverMode(b) self.m_hoverMode = b end

function ents.PFMGhost:SetViewport(vp) self.m_viewport = vp end

function ents.PFMGhost:OnTick()
	if(util.is_valid(self.m_viewport) == false) then return end
	local viewport = self.m_viewport
	local cam = viewport:GetCamera()

	local res = Vector2(viewport:GetWidth(),viewport:GetHeight())
	local cursorPos = viewport:GetCursorPos()

	local dir = util.calc_world_direction_from_2d_coordinates(cam,Vector2(cursorPos.x /res.x,cursorPos.y /res.y))
	local entCam = cam:GetEntity()
	local pos = entCam:GetPos() +entCam:GetForward() *cam:GetNearZ()

	local pl = ents.get_local_player()
	local charComponent = (pl ~= nil) and pl:GetEntity():GetComponent(ents.COMPONENT_CHARACTER) or nil
	if(charComponent == nil) then return end
	local posDst = pos +dir *2048.0
	local rayData = charComponent:GetAimRayData(1200.0)
	rayData:SetSource(pos)
	rayData:SetTarget(posDst)
	local ent = self:GetEntity()
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	local ray = phys.raycast(rayData)
	if(ray ~= false) then posDst = ray.position
	else
		local min,max = Vector(),Vector()
		if(renderC ~= nil) then min,max = renderC:GetLocalRenderBounds() end
		local maxAxisLength = math.max(max.x -min.x,max.y -min.y,max.z -min.z)
		posDst = pos +dir *(maxAxisLength +20.0) -- Move position away from camera

		-- Since we have no level as reference, we'll try to find a good position for placing the object
		-- by creating an implicit plane relative to the camera (angled by 20 degrees)
		local rot = entCam:GetRotation()
		rot = rot *EulerAngles(-20,0,0):ToQuaternion()
		local planeUp = rot:GetUp()
		local d = planeUp:DotProduct(pos)
		local t = intersect.line_with_plane(pos,dir *2048.0,planeUp,-d +60.0)
		if(t ~= false) then
			posDst = pos +dir *2048.0 *t
		end
	end
	--debug.draw_line(Vector(),posDst,Color.Red,12)
	--print(ray.entity)

	if(renderC ~= nil) then
		local min,max = renderC:GetLocalRenderBounds()
		-- debug.draw_box(ent:GetPos() +min,ent:GetPos() +max,Color.Red,0.1)
		max.y = 0
		min.y = 0
		posDst = posDst -(max +min) /2.0
	end
	if(input.get_key_state(input.KEY_LEFT_SHIFT) == input.STATE_RELEASE and input.get_key_state(input.KEY_RIGHT_SHIFT) == input.STATE_RELEASE) then
		posDst.x = math.snap_to_grid(posDst.x,ents.PFMGrid.get_unit_size())
		posDst.z = math.snap_to_grid(posDst.z,ents.PFMGrid.get_unit_size())

		if(ray ~= false) then
			rayData:SetSource(posDst +Vector(0,10,0))
			rayData:SetTarget(posDst -Vector(0,50,0))
			ray = phys.raycast(rayData)
			if(ray ~= false) then
				posDst = ray.position
			end
		end
	end
	if(renderC ~= nil) then
		local min,max = renderC:GetLocalRenderBounds()
		posDst.y = posDst.y -min.y
	end
	if(self.m_placementCallback ~= nil) then
		self.m_placementCallback(posDst,ray)
	end
	ent:SetPos(posDst)

	if(self.m_hoverMode) then
		local actorClosest,hitPos = find_actor_under_cursor(pos,dir)
		if(actorClosest ~= nil) then
			ent:SetPos(hitPos +Vector(0,50,0))
		end
	end

	if(ray ~= false) then
		local forward = vector.FORWARD
		if(math.abs(ray.normal:DotProduct(forward)) > 0.99) then
			forward = vector.RIGHT
		end
		local rot = Quaternion(forward,ray.normal)
		ent:SetRotation(rot)
	end
end
ents.COMPONENT_PFM_GHOST = ents.register_component("pfm_ghost",ents.PFMGhost)
