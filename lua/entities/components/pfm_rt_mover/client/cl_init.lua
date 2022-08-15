--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raycast.lua")

local Component = util.register_class("ents.PFMRtMover",BaseEntityComponent)

function Component:Initialize()
end
function Component:OnEntitySpawn()
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

	local pos,dir,vpData = ents.ClickComponent.get_ray_data()
	if(pos == nil) then return end

	-- TODO: Make this an input
	local refPoint = self:Raycast(pos,dir,500,false) -- Position where cursor trace hit actor
	if(refPoint == nil) then
		self.m_valid = false
		return
	end -- TODO

	local ent = self:GetEntity()
	ent:RemoveComponent(ents.COMPONENT_STATIC_BVH_USER)

	if(ent:HasComponent(ents.COMPONENT_DECAL)) then
		self.m_placeAtRaycastPosition = true
		return
	end

	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	local min,max = renderC:GetAbsoluteRenderBounds()
	local center = (min +max) /2.0
	local bottom = center:Copy()
	bottom.y = min.y
	local r = bottom:Distance(center) +100.0

	local initPos = self:Raycast(center,-vector.UP,r)
	if(initPos == nil) then
		initPos = bottom:Copy()
		self.m_implicitPlane = math.Plane(vector.UP,bottom)
	end

	self.m_initialOffset = initPos.y -min.y

	local uv,dist = ents.ClickComponent.world_space_point_to_screen_space_uv(initPos)
	if(uv ~= nil) then
		self.m_refUv = Vector2(
			vpData.cursorPos.x /vpData.width,
			vpData.cursorPos.y /vpData.height
		) -uv
	end

	-- Test
	local initPos = self:Raycast(refPoint,-vector.UP,r)
	if(initPos == nil) then
		initPos = bottom:Copy()
		initPos.x = refPoint.x
		initPos.z = refPoint.z
	end
	self.m_refDist = refPoint:Distance(initPos)
	self.m_refOffset = refPoint -ent:GetPos()
end
function Component:OnRemove()
	local ent,c = ents.citerator(ents.COMPONENT_STATIC_BVH_CACHE)()
	c:AddEntity(self:GetEntity())
end
function Component:Raycast(startPos,dir,maxDist,filterSelf)
	if(filterSelf == nil) then filterSelf = true end

	local filter
	if(filterSelf) then
		filter = function(ent,renderC)
			return ent ~= self:GetEntity()
		end
	end
	local actor,hitPos,pos = pfm.raycast(startPos,dir,maxDist,filter)
	return hitPos
end
function Component:OnTick(dt)
	if(self.m_valid == false) then return end
	local ent = self:GetEntity()

	if(self.m_placeAtRaycastPosition) then
		local pos,dir,vpData = ents.ClickComponent.get_ray_data()
		if(pos == nil) then return end
		local pose = pfm.calc_decal_target_pose(pos,dir)
		if(pose ~= nil) then self:GetEntity():SetPose(pose) end
		return
	end
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	local pos = renderC:GetAbsoluteRenderSphereBounds()
	local dir = -vector.UP

	local useTest = true
	local pos,dir,vpData = ents.ClickComponent.get_ray_data(function(vpData,cam)
		if(useTest == false) then
			vpData.cursorPos = vpData.cursorPos -self.m_refUv *Vector2(vpData.width,vpData.height)
		end
	end)
	if(pos == nil) then return end

	local cursorHitPos = self:Raycast(pos,dir,10000)
	--[[if(cursorHitPos ~= nil) then
		local pos = cursorHitPos +Vector(0,self.m_initialOffset,0)
		--self:GetEntity():SetPos(pos)
		--print(self.m_initialOffset)
	end]]

	local placeAtCursorHitPos = false
	if(dir.y > -0.001) then
		placeAtCursorHitPos = true
	end


	-- Test
	if(cursorHitPos ~= nil) then
		local dist = pos:Distance(cursorHitPos)

		local function delta_dist(d)
			return math.abs(self.m_refDist -d)
		end

		local function find_best_candidate(fstart,fend,finterval,depth)
			if(depth == 2) then return end
			depth = depth and (depth +1) or 0

			local nearestPoint
			local distances = {}
			local fvals = {}
			local iNearest
			for i=fstart +finterval,fend -finterval,finterval do
				local pstart = pos +dir *dist *i
				local p
				if(self.m_implicitPlane == nil) then p = self:Raycast(pstart,-vector.UP,10000)
				else
					local dir = -vector.UP *10000
					local t = intersect.line_with_plane(pstart,dir,self.m_implicitPlane:GetNormal(),self.m_implicitPlane:GetDistance())
					if(t ~= false) then
						p = pstart +dir *t
					end
				end

				local l = (p ~= nil) and delta_dist(pstart:Distance(p)) or math.huge
				table.insert(distances,l)
				table.insert(fvals,i)

				if(p ~= nil and (iNearest == nil or l < distances[iNearest])) then
					iNearest = #distances
					nearestPoint = p
				end
			end
			if(iNearest == nil) then return end
			if(depth == 1) then
				-- TODO: If final distance > 0.1 then adjust (will not match cursor pos anymore)
				local pstart = pos +dir *dist *fvals[iNearest]
				return fvals[iNearest]
			else
				local stepSize = 0.001
				local m = stepSize *10.0
				if(iNearest == 1) then
					return find_best_candidate(fstart,fstart +m,stepSize,depth)
				elseif(iNearest == #distances) then
					return find_best_candidate(fend -m,fend,stepSize,depth)
				elseif(distances[iNearest -1] < distances[iNearest +1]) then
					return find_best_candidate(fvals[iNearest -1],fvals[iNearest],stepSize,depth)
				else
					return find_best_candidate(fvals[iNearest],fvals[iNearest +1],stepSize,depth)
				end
			end
		end
		local f = placeAtCursorHitPos and 1.0 or find_best_candidate(0.0,1.0,0.01,depth)
		if(f ~= nil) then
			local p = pos +dir *f *dist
			local offset = Vector(self.m_refOffset.x,0.0,self.m_refOffset.z)
			--print(offset)
			p = p -self.m_refOffset

			-- Adjust
			--[[local hp = self:Raycast(p,dir,10000)
			p = hp
			p.y = p.y +self.m_refDist]]
			--

			self:GetEntity():SetPos(p)
		end

	end

	--

	--[[local hitPos = self:Raycast(pos,dir,500)
	if(hitPos ~= nil) then
		local movePos = hitPos +self.m_initialOffset

	end]]

end
ents.COMPONENT_PFM_RT_MOVER = ents.register_component("pfm_rt_mover",Component)
