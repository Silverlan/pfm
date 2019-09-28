include("/udm/elements/udm_element.lua")
include("udm_log_list.lua")

udm.ELEMENT_TYPE_PFM_LOG = udm.register_element("PFMLog")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"layers",udm.Array(udm.ELEMENT_TYPE_PFM_LOG_LIST))

function udm.PFMLog:AddLayer(name)
  local logLayer = self:CreateChild(udm.ELEMENT_TYPE_PFM_LOG_LIST,name)
  self:GetLayers():PushBack(logLayer)
  return logLayer
end
