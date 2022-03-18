--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local fontSet = engine.get_default_font_set_name()
local fontFeatures = bit.bor(engine.FONT_FEATURE_FLAG_SANS_BIT,engine.FONT_FEATURE_FLAG_MONO_BIT)
engine.create_font("pfm_small",fontSet,fontFeatures,10)
engine.create_font("pfm_medium",fontSet,fontFeatures,12)
engine.create_font("pfm_large",fontSet,fontFeatures,20)
