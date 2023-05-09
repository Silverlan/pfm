--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
