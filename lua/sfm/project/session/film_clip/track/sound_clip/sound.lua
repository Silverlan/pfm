--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("Sound")
sfm.link_dmx_type("DmeGameSound",sfm.Sound)

sfm.BaseElement.RegisterAttribute(sfm.Sound,"soundname","",{
	getterName = "GetSoundName",
	setterName = "SetSoundName"
})
sfm.BaseElement.RegisterAttribute(sfm.Sound,"gameSoundName","")
sfm.BaseElement.RegisterAttribute(sfm.Sound,"volume",1.0)
sfm.BaseElement.RegisterAttribute(sfm.Sound,"pitch",100)
sfm.BaseElement.RegisterAttribute(sfm.Sound,"origin",Vector())
sfm.BaseElement.RegisterAttribute(sfm.Sound,"direction",Vector())
