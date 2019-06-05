include("udm_element.lua")

udm.ELEMENT_TYPE_TRANSFORM = udm.register_element("Transform")
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"position",udm.Vector3(Vector()))
-- udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"orientation",udm.Quaternion(1,0,0,0))
