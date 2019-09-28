include("log_layer.lua")

util.register_class("sfm.Log",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.Log,"layers",sfm.LogLayer)

function sfm.Log:__init()
  sfm.BaseElement.__init(self,sfm.Log)
end

function sfm.Log:ToPFMLog(pfmLog)
  for _,logLayer in ipairs(self:GetLayers()) do
    local pfmLogLayer = pfmLog:AddLayer(logLayer:GetName())
    logLayer:ToPFMLogLayer(pfmLogLayer)
  end
end
