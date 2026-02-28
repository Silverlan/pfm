-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local fontSet = engine.get_default_font_set_name()
local fontFeatures = bit.bor(engine.FONT_FEATURE_FLAG_SANS_BIT, engine.FONT_FEATURE_FLAG_MONO_BIT)
engine.create_font("pfm_small", fontSet, fontFeatures, 10)
engine.create_font("pfm_medium", fontSet, fontFeatures, 12)
engine.create_font("pfm_large", fontSet, fontFeatures, 20)
