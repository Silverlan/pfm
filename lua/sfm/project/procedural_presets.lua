--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ProceduralPresets")

sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitteriterations",5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitterscale_vector",2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitterscale",1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothiterations",5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothscale_vector",2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothscale",1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"staggerinterval",0.0833)
