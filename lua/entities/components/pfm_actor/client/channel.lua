util.register_class("ents.PFMActorComponent.Channel")

function ents.PFMActorComponent.Channel:__init()
	self.m_transforms = {}
end
function ents.PFMActorComponent.Channel:AddTransform(controllerId,time,value)
	self.m_transforms[controllerId] = self.m_transforms[controllerId] or {
		lastIndex = 1,
		transforms = {}
	}
	table.insert(self.m_transforms[controllerId].transforms,{time,value})
end
function ents.PFMActorComponent.Channel:GetTransforms() return self.m_transforms end
function ents.PFMActorComponent.Channel:GetInterpolatedValue(value0,value1,interpAm)
	return value0 -- To be implemented by derived classes
end
function ents.PFMActorComponent.Channel:ApplyValue(ent,controllerId,value)
	-- To be implemented by derived classes
	return false
end
function ents.PFMActorComponent.Channel:Apply(ent,offset)
	for controllerId,transformData in pairs(self.m_transforms) do
		-- We'd have to do a LOT of iterations here, but in most cases the new offset will be very
		-- close to the previous offset, which we can use to our advantage. Using this information we
		-- can narrow the number of iterations down to 1 or 2 per controller for most cases.
		local lastIndex = transformData.lastIndex
		local lastOffset = transformData.transforms[lastIndex][1]

		local startIndex = lastIndex
		local endIndex = #transformData.transforms
		local increment = 1
		if(offset < lastOffset) then
			-- New offset is in the past, we'll have to increment backwards
			increment = -1
			endIndex = 1
		end
		for i=startIndex,endIndex,increment do
			local t = transformData.transforms[i]
			local tPrev = transformData.transforms[i -1] or t
			if((offset >= tPrev[1] and offset < t[1]) or i == endIndex) then
				local dt = t[1] -tPrev[1]
				local relOffset = offset -tPrev[1]
				local interpFactor = (dt > 0.0) and math.clamp(relOffset /dt,0.0,1.0) or 0.0

				local value = self:GetInterpolatedValue(tPrev[2],t[2],interpFactor)
				self:ApplyValue(ent,controllerId,value)
				transformData.lastIndex = i -- Optimization: This will be the new start index next time the offset has changed
				break
			end
		end
	end
end

include("channel")
