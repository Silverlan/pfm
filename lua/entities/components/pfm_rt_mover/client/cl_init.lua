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
	local refPoint = self:Raycast(pos,dir,500) -- Position where cursor trace hit actor
	if(refPoint == nil) then
		self.m_valid = false
		return
	end -- TODO

	self:GetEntity():RemoveComponent(ents.COMPONENT_STATIC_BVH_USER)

	local ent = self:GetEntity()
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	local centerPos,radius = renderC:GetAbsoluteRenderSphereBounds()
	local initPos = self:Raycast(centerPos,-ent:GetUp(),128)
	if(initPos == nil) then
		self.m_valid = false
		return
	end
	local min,max = ent:GetComponent(ents.COMPONENT_RENDER):GetAbsoluteRenderBounds()

	--[[local drawInfo = debug.DrawInfo()
	drawInfo:SetDuration(12)
	drawInfo:SetColor(Color.Lime)
	debug.draw_line(ent:GetPos(),refPoint,drawInfo)]]

	self.m_initialOffset = initPos.y -min.y
	print("Initial values: ",centerPos,initPos,min)

	local uv,dist = ents.ClickComponent.world_space_point_to_screen_space_uv(initPos)
	if(uv ~= nil) then
		self.m_refUv = Vector2(
			vpData.cursorPos.x /vpData.width,
			vpData.cursorPos.y /vpData.height
		) -uv
	end

	-- Test
	local initPos = self:Raycast(refPoint,-ent:GetUp(),radius +280)
	if(initPos == nil) then
		self.m_valid = false
		return
	end
	self.m_refDist = refPoint:Distance(initPos)
	self.m_refOffset = refPoint -ent:GetPos()
	print("Offset: ",self.m_refOffset)
end
function Component:OnRemove()
	local ent,c = ents.citerator(ents.COMPONENT_STATIC_BVH_CACHE)()
	c:AddEntity(self:GetEntity())
end
function Component:Raycast(startPos,dir,maxDist)
	local actor,hitPos,pos = pfm.raycast(startPos,dir,maxDist,function(ent,renderC)
		return ent ~= self:GetEntity()
	end)
	return hitPos
end
function Component:OnTick(dt)
	if(self.m_valid == false) then
		return
	end
	local ent = self:GetEntity()
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	local pos = renderC:GetAbsoluteRenderSphereBounds()
	local dir = Vector(0,-1,0)

	--self.m_refUv
	--print(self.m_refUv)

	local useTest = true
	local pos,dir,vpData = ents.ClickComponent.get_ray_data(function(vpData,cam)
		if(useTest == false) then
			vpData.cursorPos = vpData.cursorPos -self.m_refUv *Vector2(vpData.width,vpData.height)
		end
	end)
	if(pos == nil) then return end

	local t = time.time_since_epoch()
	local cursorHitPos = self:Raycast(pos,dir,10000)
	local dt = time.time_since_epoch() -t
	--print(dt /1000000.0)
	--[[if(cursorHitPos ~= nil) then
		local drawInfo = debug.DrawInfo()
		drawInfo:SetDuration(12)
		drawInfo:SetColor(Color.Aqua)
		debug.draw_line(hitPos,hitPos +Vector(0,100,0),drawInfo)
	end]]

	if(cursorHitPos ~= nil) then
		local pos = cursorHitPos +Vector(0,self.m_initialOffset,0)
		--self:GetEntity():SetPos(pos)
		--print(self.m_initialOffset)
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
				local p = self:Raycast(pstart,Vector(0,-1,0),10000)

				--[[local drawInfo = debug.DrawInfo()
				drawInfo:SetDuration(12)
				drawInfo:SetColor(Color.Aqua)
				debug.draw_line(pos +dir *dist *i,p,drawInfo)]]

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
		local f = find_best_candidate(0.0,1.0,0.01,depth)
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


			local drawInfo = debug.DrawInfo()
			drawInfo:SetDuration(0.1)
			drawInfo:SetColor(Color.Red)
			debug.draw_line(pos,p,drawInfo)
			self:GetEntity():SetPos(p)
			--self:GetEntity():SetPos(Vector(136.545, 21.972, -954.841))
		end

	end

	--

	--[[local hitPos = self:Raycast(pos,dir,500)
	if(hitPos ~= nil) then
		local movePos = hitPos +self.m_initialOffset

	end]]

end
ents.COMPONENT_PFM_RT_MOVER = ents.register_component("pfm_rt_mover",Component)
