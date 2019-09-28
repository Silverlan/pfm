util.register_class("sfm.Transform",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Transform,"position",Vector())
sfm.BaseElement.RegisterAttribute(sfm.Transform,"orientation",Quaternion())

function sfm.Transform:__init()
  sfm.BaseElement.__init(self,sfm.Transform)
end

function sfm.Transform:ToPFMTransform(pfmTransform)
  pfmTransform:SetPosition(self:GetPosition()) -- TODO: Convert coordinate system
  pfmTransform:SetRotation(self:GetOrientation()) -- TODO: Convert coordinate system
end
