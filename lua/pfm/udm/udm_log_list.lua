include("/udm/elements/udm_element.lua")

udm.ELEMENT_TYPE_PFM_LOG_LIST = udm.register_element("PFMLogList")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG_LIST,"times",udm.Array())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG_LIST,"values",udm.Array())
