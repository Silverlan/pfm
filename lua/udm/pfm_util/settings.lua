-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.Settings:GetPlayheadFrameOffset()
	return self:TimeOffsetToFrameOffset(self:GetPlayheadOffset())
end
function pfm.udm.Settings:GetFrameRate()
	return self:GetRenderSettings():GetFrameRate()
end
function pfm.udm.Settings:TimeOffsetToFrameOffset(offset)
	return offset * self:GetFrameRate()
end
function pfm.udm.Settings:FrameOffsetToTimeOffset(offset)
	return offset / self:GetFrameRate()
end
