include("/udm/elements/udm_element.lua")

udm.ELEMENT_TYPE_PFM_SOUND = udm.register_element("PFMSound")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SOUND,"soundName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SOUND,"volume",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SOUND,"pitch",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SOUND,"origin",udm.Vector3())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SOUND,"direction",udm.Vector3())
