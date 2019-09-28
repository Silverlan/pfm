include("udm_element.lua")

udm.ELEMENT_TYPE_TRANSFORM = udm.register_element("Transform")
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"position",udm.Vector3(Vector()))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"rotation",udm.Quaternion(Quaternion()))
