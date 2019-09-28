util.register_class("sfm.LogLayer",sfm.BaseElement)

function sfm.LogLayer:__init()
  sfm.BaseElement.__init(self,sfm.LogLayer)
  self.m_times = {}
  self.m_values = {}
end

function sfm.LogLayer:Load(el)
  sfm.BaseElement.Load(self,el)
  for _,elValue in ipairs(el:GetAttrV("values")) do
    table.insert(self.m_values,elValue:GetValue())
  end
  
  for _,elValue in ipairs(el:GetAttrV("times")) do
    table.insert(self.m_times,elValue:GetValue())
  end
end

function sfm.LogLayer:GetTimes() return self.m_times end
function sfm.LogLayer:GetValues() return self.m_values end
function sfm.LogLayer:GetType() return self.m_type end

function sfm.LogLayer:ToPFMLogLayer(pfmLogLayer)
  for _,t in ipairs(self:GetTimes()) do
    pfmLogLayer:GetTimes():PushBack(udm.Float(t))
  end
  local TYPE_FLOAT = 0
  local TYPE_VECTOR3 = 1
  local TYPE_QUATERNION = 2
  local type = self:GetType()
  if(type == "DmeFloatLogLayer") then type = TYPE_FLOAT
  elseif(type == "DmeVector3LogLayer") then type = TYPE_VECTOR3
  elseif(type == "DmeQuaternionLogLayer") then type = TYPE_QUATERNION
  else
    console.print_warning("Unsupported log layer type: ",type)
    return
  end
  for _,v in ipairs(self:GetValues()) do
    local udmValue
    if(type == TYPE_FLOAT) then udmValue = udm.Float(v)
    elseif(type == TYPE_VECTOR3) then
      v = Vector(v.x,-v.z,v.y) -- Conversion into Pragma coordinate system
      udmValue = udm.Vector3(v)
    elseif(type == TYPE_QUATERNION) then
      v = Quaternion(v.w,v.x,-v.z,v.y) -- Conversion into Pragma coordinate system
      udmValue = udm.Quaternion(v)
    end
    pfmLogLayer:GetValues():PushBack(udmValue)
  end
end
