include("/udm/elements/udm_element.lua")
include("udm_time_frame.lua")
include("udm_sound.lua")

udm.ELEMENT_TYPE_PFM_AUDIO_CLIP = udm.register_element("PFMAudioClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"sound",udm.PFMSound())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeInTime",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeOutTime",udm.Float(0.0))
