include("/udm/elements/udm_element.lua")

udm.ELEMENT_TYPE_PFM_MODEL = udm.register_element("PFMModel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"modelName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"skin",udm.Int(0))
