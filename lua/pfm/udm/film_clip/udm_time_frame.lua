--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_TIME_FRAME = fudm.register_element("PFMTimeFrame")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_FRAME,"start",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_FRAME,"duration",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_FRAME,"offset",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_FRAME,"scale",fudm.Float(1.0))

function fudm.PFMTimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end
function fudm.PFMTimeFrame:Max(timeFrameOther)
	local startTime = math.min(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.max(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = fudm.PFMTimeFrame()
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function fudm.PFMTimeFrame:Min(timeFrameOther)
	local startTime = math.max(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.min(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = fudm.PFMTimeFrame()
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function fudm.PFMTimeFrame:LocalizeOffset(offset)
	return (offset -self:GetStart() +self:GetOffset()) *self:GetScale()
end
function fudm.PFMTimeFrame:GlobalizeOffset(offset)
	return (self:GetStart() +offset -self:GetOffset()) /self:GetScale()
end
function fudm.PFMTimeFrame:LocalizeTimeOffset(offset)
	return offset -self:GetStart()
end
function fudm.PFMTimeFrame:GlobalizeTimeOffset(offset)
	return offset +self:GetStart()
end
function fudm.PFMTimeFrame:IsInTimeFrame(t,e)
	e = e or 0.001
	-- Note: -e for both start and end is on purpose
	return t >= self:GetStart() -e and t < self:GetEnd() -e
end
