include("/udm/elements/udm_element.lua")
include("udm_channel.lua")

udm.ELEMENT_TYPE_PFM_FLEX_CONTROL = udm.register_element("PFMFlexControl")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"channel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"leftValueChannel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"rightValueChannel",udm.PFMChannel())
