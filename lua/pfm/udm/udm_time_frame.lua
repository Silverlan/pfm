include("/udm/elements/udm_element.lua")

udm.ELEMENT_TYPE_PFM_TIME_FRAME = udm.register_element("PFMTimeFrame")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"start",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"duration",udm.Float(0.0))

function udm.PFMTimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end
