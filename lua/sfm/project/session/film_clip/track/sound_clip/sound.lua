-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("Sound")
sfm.link_dmx_type("DmeGameSound", sfm.Sound)

sfm.BaseElement.RegisterAttribute(sfm.Sound, "soundname", "", {
	getterName = "GetSoundName",
	setterName = "SetSoundName",
})
sfm.BaseElement.RegisterAttribute(sfm.Sound, "gameSoundName", "")
sfm.BaseElement.RegisterAttribute(sfm.Sound, "volume", 1.0)
sfm.BaseElement.RegisterAttribute(sfm.Sound, "pitch", 100)
sfm.BaseElement.RegisterAttribute(sfm.Sound, "origin", Vector())
sfm.BaseElement.RegisterAttribute(sfm.Sound, "direction", Vector())
