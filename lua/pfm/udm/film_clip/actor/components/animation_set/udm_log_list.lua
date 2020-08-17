--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_LOG_LIST = udm.register_element("PFMLogList")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG_LIST,"times",udm.ValueArray(util.VAR_TYPE_FLOAT))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG_LIST,"values",udm.ValueArray())

local interpolationFunctions = {
	[util.VAR_TYPE_INT32] = function(value0,value1,interpAm) return (interpAm == 1.0) and value1 or value0 end, -- No interpolation, just return the lower value
	[util.VAR_TYPE_BOOL] = function(value0,value1,interpAm)
		if(interpAm == 1.0) then return value1 end
		return value0
	end, -- No interpolation, just return the lower value
	[util.VAR_TYPE_FLOAT] = function(value0,value1,interpAm) return math.lerp(value0,value1,interpAm) end,
	[util.VAR_TYPE_VECTOR] = function(value0,value1,interpAm) return value0:Lerp(value1,interpAm) end,
	[util.VAR_TYPE_QUATERNION] = function(value0,value1,interpAm) return value0:Slerp(value1,interpAm) end
}

function udm.PFMLogList:Initialize()
	self.m_lastIndex = 1
end

function udm.PFMLogList:CalcInterpolatedValue(targetTime)
	local times = self:GetTimes():GetTable()
	local values = self:GetValues():GetTable()
	local numItems = math.min(#times,#values)
	if(numItems == 0) then return end
	local type = self:GetValues():GetValueType()
	local interpolationFunction = interpolationFunctions[type]
	if(interpolationFunction == nil) then
		pfm.log("No interpolation function found for log attribute type '" .. util.variable_type_to_string(type) .. "'! Log layer '" .. self:GetName() .. "' will be ignored!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end
	
	for i,t in ipairs(times) do
		local tNext = times[i +1] or t
		local v = values[i]
		local vNext = values[i +1] or v

		if(targetTime >= t and (targetTime < tNext or t == tNext)) then
			local dt = tNext -t
			local interpFactor = (dt > 0.0) and math.clamp((targetTime -t) /dt,0.0,1.0) or 0.0

			return interpolationFunction(v,vNext,interpFactor)
		end
	end
end

function udm.PFMLogList:SetPlaybackOffset(offset)
	local times = self:GetTimes()
	local values = self:GetValues()
	local numItems = math.min(#times,#values)
	if(numItems == 0) then return end
	local type = self:GetValues():GetValueType()
	local interpolationFunction = interpolationFunctions[type]
	if(interpolationFunction == nil) then
		pfm.log("No interpolation function found for log attribute type '" .. udm.get_type_name(type) .. "'! Log layer '" .. self:GetName() .. "' will be ignored!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end

	-- We'd have to do a LOT of iterations here, but in most cases the new offset will be very
	-- close to the previous offset, which we can use to our advantage. Using this information we
	-- can narrow the number of iterations down to 1 or 2 per controller for most cases.
	local lastIndex = self.m_lastIndex
	local lastOffset = times:Get(lastIndex)

	local startIndex = lastIndex
	local endIndex = numItems
	local increment = 1
	if(offset < lastOffset) then
		-- New offset is in the past, we'll have to increment backwards
		increment = -1
		endIndex = 1
	end

	for i=startIndex,endIndex,increment do
		local t = {times:Get(i),values:Get(i)}
		local tPrev = (values:Get(i -1) ~= nil) and {times:Get(i -1),values:Get(i -1)} or t
		if((offset >= tPrev[1] and offset < t[1]) or i == endIndex) then
			local dt = t[1] -tPrev[1]
			local relOffset = offset -tPrev[1]
			local interpFactor = (dt > 0.0) and math.clamp(relOffset /dt,0.0,1.0) or 0.0

			local value = interpolationFunction(tPrev[2],t[2],interpFactor)
			self.m_lastIndex = i -- Optimization: This will be the new start index next time the offset has changed
			return value
		end
	end
end
