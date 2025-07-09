-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm.udm.TimeFrame.EPSILON = 0.001
function pfm.udm.TimeFrame.localize_offset(tfStart, tfOffset, tfScale, offset)
	return (offset - tfStart + tfOffset) * tfScale
end
function pfm.udm.TimeFrame.globalize_offset(tfStart, tfOffset, tfScale, offset)
	return (tfStart + offset - tfOffset) / tfScale
end
function pfm.udm.TimeFrame:GetEnd()
	return self:GetStart() + self:GetDuration()
end
function pfm.udm.TimeFrame:IsInTimeFrame(t, e)
	e = e or pfm.udm.TimeFrame.EPSILON
	-- Note: -e for both start and end is on purpose
	return t >= self:GetStart() - e and t <= self:GetEnd() - e
end
function pfm.udm.TimeFrame:ClampToTimeFrame(t, e)
	e = e or pfm.udm.TimeFrame.EPSILON
	local tStart = self:GetStart() + e
	local tEnd = self:GetEnd() - e
	return math.clamp(t, tStart, tEnd)
end
function pfm.udm.TimeFrame:Max(timeFrameOther)
	local startTime = math.min(self:GetStart(), timeFrameOther:GetStart())
	local endTime = math.max(self:GetEnd(), timeFrameOther:GetEnd())
	local duration = endTime - startTime
	local result = pfm.udm.TimeFrame.create(self:GetSchema())
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function pfm.udm.TimeFrame:Min(timeFrameOther)
	local startTime = math.max(self:GetStart(), timeFrameOther:GetStart())
	local endTime = math.min(self:GetEnd(), timeFrameOther:GetEnd())
	local duration = endTime - startTime
	local result = pfm.udm.TimeFrame.create(self:GetSchema())
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function pfm.udm.TimeFrame:LocalizeOffset(offset)
	return pfm.udm.TimeFrame.localize_offset(self:GetStart(), self:GetOffset(), self:GetScale(), offset)
end
function pfm.udm.TimeFrame:GlobalizeOffset(offset)
	return pfm.udm.TimeFrame.globalize_offset(self:GetStart(), self:GetOffset(), self:GetScale(), offset)
end
function pfm.udm.TimeFrame:LocalizeTimeOffset(offset)
	return offset - self:GetStart()
end
function pfm.udm.TimeFrame:GlobalizeTimeOffset(offset)
	return offset + self:GetStart()
end

function pfm.udm.TimeFrame:LocalizeOffsetAbs(t)
	t = self:LocalizeOffset(t)
	local parent = self:GetParent()
	while parent ~= nil do
		if parent.GetTimeFrame then
			local tf = parent:GetTimeFrame()
			if util.is_same_object(tf, self) == false then
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
	while parent ~= nil do
		if parent.GetTimeFrame then
			local tf = parent:GetTimeFrame()
			if util.is_same_object(tf, self) == false then
				t = tf:GlobalizeOffset(t)
			end
		end
		parent = parent:GetParent()
	end
	return t
end
