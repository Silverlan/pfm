--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.TimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end
function pfm.udm.TimeFrame:IsInTimeFrame(t,e)
    e = e or 0.001
    -- Note: -e for both start and end is on purpose
    return t >= self:GetStart() -e and t < self:GetEnd() -e
end
function pfm.udm.TimeFrame:Max(timeFrameOther)
    local startTime = math.min(self:GetStart(),timeFrameOther:GetStart())
    local endTime = math.max(self:GetEnd(),timeFrameOther:GetEnd())
    local duration = endTime -startTime
    local result = pfm.udm.TimeFrame.create(self:GetSchema())
    result:SetStart(startTime)
    result:SetDuration(endTime)
    return result
end
function pfm.udm.TimeFrame:Min(timeFrameOther)
    local startTime = math.max(self:GetStart(),timeFrameOther:GetStart())
    local endTime = math.min(self:GetEnd(),timeFrameOther:GetEnd())
    local duration = endTime -startTime
    local result = pfm.udm.TimeFrame.create(self:GetSchema())
    result:SetStart(startTime)
    result:SetDuration(endTime)
    return result
end
function pfm.udm.TimeFrame:LocalizeOffset(offset)
    return (offset -self:GetStart() +self:GetOffset()) *self:GetScale()
end
function pfm.udm.TimeFrame:GlobalizeOffset(offset)
    return (self:GetStart() +offset -self:GetOffset()) /self:GetScale()
end
function pfm.udm.TimeFrame:LocalizeTimeOffset(offset)
    return offset -self:GetStart()
end
function pfm.udm.TimeFrame:GlobalizeTimeOffset(offset)
    return offset +self:GetStart()
end

function pfm.udm.TimeFrame:LocalizeOffsetAbs(t)
	t = self:LocalizeOffset(t)
	local parent = self:GetParent()
	while(parent ~= nil) do
		if(parent.GetTimeFrame) then
			local tf = parent:GetTimeFrame()
			if(util.is_same_object(tf,self) == false) then
				t = tf:LocalizeOffset(t)
			end
		end
		parent = parent:GetParent()
	end
	return t
end

function pfm.udm.TimeFrame:GlobalizeOffsetAbs(t)
	t = self:GlobalizeOffset(t)
	local parent = self:GetParent()
	while(parent ~= nil) do
		if(parent.GetTimeFrame) then
			local tf = parent:GetTimeFrame()
			if(util.is_same_object(tf,self) == false) then
				t = tf:GlobalizeOffset(t)
			end
		end
		parent = parent:GetParent()
	end
	return t
end
