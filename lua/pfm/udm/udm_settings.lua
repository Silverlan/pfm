--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("settings")

fudm.ELEMENT_TYPE_PFM_SETTINGS = fudm.register_element("PFMSettings")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SETTINGS,"renderSettings",fudm.PFMRenderSettings())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SETTINGS,"playheadOffset",fudm.Float(0.0))

function fudm.PFMSettings:GetPlayheadFrameOffset() return self:TimeOffsetToFrameOffset(self:GetPlayheadOffset()) end
function fudm.PFMSettings:GetFrameRate() return self:GetRenderSettings():GetFrameRate() end
function fudm.PFMSettings:TimeOffsetToFrameOffset(offset) return offset *self:GetFrameRate() end
function fudm.PFMSettings:FrameOffsetToTimeOffset(offset) return offset /self:GetFrameRate() end
