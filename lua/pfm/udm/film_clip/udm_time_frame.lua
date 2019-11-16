--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_TIME_FRAME = udm.register_element("PFMTimeFrame")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"start",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"duration",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"offset",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"scale",udm.Float(1.0))

function udm.PFMTimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end
function udm.PFMTimeFrame:Max(timeFrameOther)
	local startTime = math.min(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.max(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = udm.PFMTimeFrame()
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function udm.PFMTimeFrame:Min(timeFrameOther)
	local startTime = math.max(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.min(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = udm.PFMTimeFrame()
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function udm.PFMTimeFrame:LocalizeOffset(offset)
	return offset -self:GetStart() +self:GetOffset()
end
function udm.PFMTimeFrame:IsInTimeFrame(t)
	return t >= self:GetStart() and t < self:GetEnd()
end
