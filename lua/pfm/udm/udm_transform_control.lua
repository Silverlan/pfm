include("/udm/elements/udm_element.lua")
include("udm_channel.lua")

udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL = udm.register_element("PFMTransformControl")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"positionChannel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"rotationChannel",udm.PFMChannel())
