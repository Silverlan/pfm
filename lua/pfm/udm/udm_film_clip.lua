include("/udm/elements/udm_element.lua")
include("udm_time_frame.lua")

udm.ELEMENT_TYPE_PFM_FILM_CLIP = udm.register_element("PFMFilmClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"animationSets",udm.Array(udm.ELEMENT_TYPE_PFM_ANIMATION_SET))
