--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ConstraintTarget")
sfm.link_dmx_type("DmeConstraintTarget",sfm.ConstraintTarget)

sfm.register_element_type("RigHandle") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.ConstraintTarget,"target",sfm.RigHandle)
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget,"targetWeight",1.0)
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget,"vecOffset",Vector())
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget,"oOffset",Quaternion())
