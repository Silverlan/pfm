include("/udm/elements/udm_element.lua")
include("udm_log.lua")

udm.ELEMENT_TYPE_PFM_CHANNEL = udm.register_element("PFMChannel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"log",udm.PFMLog())
