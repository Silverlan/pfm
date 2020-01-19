include_component("click")

util.register_class("ents.UtilTransformArrowComponent",BaseEntityComponent)

ents.UtilTransformArrowComponent.TYPE_TRANSLATION = 0
ents.UtilTransformArrowComponent.TYPE_ROTATION = 1

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
ents.UtilTransformArrowComponent:RegisterMember("Axis",util.VAR_TYPE_UINT8,math.AXIS_X,ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,1)
ents.UtilTransformArrowComponent:RegisterMember("Selected",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)
ents.UtilTransformArrowComponent:RegisterMember("Relative",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)
ents.UtilTransformArrowComponent:RegisterMember("Type",util.VAR_TYPE_UINT8,ents.UtilTransformArrowComponent.TYPE_TRANSLATION,ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,1)

function ents.UtilTransformArrowComponent:Initialize()
	BaseEntityComponent.Initialize(self)
  
  self:AddEntityComponent(ents.COMPONENT_MODEL)
  self:AddEntityComponent(ents.COMPONENT_RENDER)
  self:AddEntityComponent(ents.COMPONENT_COLOR)
  self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
  self:AddEntityComponent(ents.COMPONENT_CLICK)
  self:AddEntityComponent(ents.COMPONENT_LOGIC)
  
  self:BindEvent(ents.ClickComponent.EVENT_ON_CLICK,"OnClick")
  self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
end
function ents.UtilTransformArrowComponent:OnEntitySpawn()
  self:UpdateAxis()
end

local setAxis = ents.UtilTransformArrowComponent.SetAxis
function ents.UtilTransformArrowComponent:SetAxis(axis)
  setAxis(self,axis)
  self:UpdateAxis()
end

local setType = ents.UtilTransformArrowComponent.SetType
function ents.UtilTransformArrowComponent:SetType(type)
  setType(self,type)
  self:UpdateModel()
end

function ents.UtilTransformArrowComponent:SetUtilTransformComponent(c)
  self.m_transformComponent = c
  local axis = self:GetAxis()
  local rot = c:GetEntity():GetRotation()
  
  if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then
    if(axis == math.AXIS_X) then
      rot = rot *EulerAngles(0,90,0):ToQuaternion()
    elseif(axis == math.AXIS_Y) then
      rot = rot *EulerAngles(-90,0,0):ToQuaternion()
    end
  else
    if(axis == math.AXIS_X) then
      rot = rot *EulerAngles(0,0,90):ToQuaternion()
    elseif(axis == math.AXIS_Z) then
      rot = rot *EulerAngles(90,0,0):ToQuaternion()
    end
  end
  local ent = self:GetEntity()
  ent:SetRotation(rot)
  local attC = ent:AddComponent(ents.COMPONENT_ATTACHABLE)
  if(attC ~= nil) then
    ent:SetPos(c:GetEntity():GetPos())
    
    local attInfo = ents.AttachableComponent.AttachmentInfo()
    attInfo.flags = ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME
    attC:AttachToEntity(c:GetEntity(),attInfo)
  end
end
function ents.UtilTransformArrowComponent:GetBaseUtilTransformComponent() return self.m_transformComponent end
function ents.UtilTransformArrowComponent:UpdateAxis()
  local ent = self:GetEntity()
  if(ent:IsSpawned() == false) then return end
  local axis = self:GetAxis()
  local colC = ent:GetComponent(ents.COMPONENT_COLOR)
  if(colC ~= nil) then
    if(axis == math.AXIS_X) then colC:SetColor(Color.Red)
    elseif(axis == math.AXIS_Y) then colC:SetColor(Color.Lime)
    elseif(axis == math.AXIS_Z) then colC:SetColor(Color.Aqua) end
  end
  self:UpdateModel()
end
function ents.UtilTransformArrowComponent:UpdateModel()
  local ent = self:GetEntity()
  local mdl
  if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then mdl = self:GetArrowModel()
  else mdl = self:GetDiskModel() end
  if(mdl == ent:GetModel()) then return end
  ent:SetModel(mdl)
end
function ents.UtilTransformArrowComponent:GetReferenceAxis()
  local axis = self:GetAxis()
  if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then return axis end
  if(axis == math.AXIS_X) then return math.AXIS_Z end
  if(axis == math.AXIS_Z) then return math.AXIS_X end
  return axis
end
function ents.UtilTransformArrowComponent:GetCursorAxisAngle()
  local transformC = self:GetBaseUtilTransformComponent()
  if(transformC == nil) then return end
  local entTransform = transformC:GetEntity()
  local ang = entTransform:GetAngles()
  local axis = self:GetAxis()

  local intersectPos = self:GetCursorIntersectionWithAxisPlane()
  if(intersectPos == nil) then return end
  local pos = intersectPos -self:GetEntity():GetPos()
  local axisAngle = 0.0
  if(axis == math.AXIS_X) then axisAngle = math.atan2(pos.z,pos.y)
  elseif(axis == math.AXIS_Y) then axisAngle = math.atan2(pos.x,pos.z)
  else axisAngle = math.atan2(pos.y,pos.x) end
  return math.deg(axisAngle)
end
function ents.UtilTransformArrowComponent:GetCursorIntersectionWithAxisPlane()
  local transformC = self:GetBaseUtilTransformComponent()
  local ent = self:GetEntity()
  local clickC = ent:GetComponent(ents.COMPONENT_CLICK)
  if(transformC == nil or clickC == nil) then return end
  local axis = self:GetAxis()

  local plane
  if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then
    if(axis == math.AXIS_X) then
      plane = math.Plane(transformC:GetEntity():GetUp(),ent:GetPos())
    elseif(axis == math.AXIS_Y) then
      plane = math.Plane(-transformC:GetEntity():GetRight(),ent:GetPos())
    else
      plane = math.Plane(transformC:GetEntity():GetUp(),ent:GetPos())
    end
  else
    if(axis == math.AXIS_X) then
      plane = math.Plane(vector.FORWARD,ent:GetPos())
    elseif(axis == math.AXIS_Y) then
      plane = math.Plane(vector.UP,ent:GetPos())
    else
      plane = math.Plane(vector.RIGHT,ent:GetPos())
    end
  end

  local pos,dir = clickC:GetRayData()
  local maxDist = 32768
  local bIntersect,t = intersect.line_with_plane(pos,dir *maxDist,plane:GetNormal(),plane:GetDistance())
  if(bIntersect == false) then return end
  return pos +dir *t *maxDist
end
function ents.UtilTransformArrowComponent:OnTick(dt)
  if(self:IsSelected() ~= true) then return end
  local ent = self:GetEntity()
  local clickC = ent:GetComponent(ents.COMPONENT_CLICK)
  local transformC = self:GetBaseUtilTransformComponent()
  if(util.is_valid(transformC) == false or util.is_valid(clickC) == false) then return end
	self:ApplyTransform()
end
function ents.UtilTransformArrowComponent:ApplyTransform()
	local transformC = self:GetBaseUtilTransformComponent()
	local entTransform = transformC:GetEntity()
	if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then
    local intersectPos = self:GetCursorIntersectionWithAxisPlane()
    if(intersectPos ~= nil) then
      local axis = self:GetReferenceAxis()
      local delta = Vector()
      delta:Set(axis,(self:ToLocalSpace(intersectPos) -self:ToLocalSpace(self.m_moveStartPos)):Get(axis))

      --[[if(self:IsRelative() == false) then
        local pos = transformC:GetAbsTransformPosition()
        pos = pos +delta

        self.m_moveStartPos = intersectPos
        transformC:SetAbsTransformPosition(pos)
      else
        local pos = transformC:GetTransformPosition()
        pos = pos +delta

        self.m_moveStartPos = intersectPos
        transformC:SetTransformPosition(pos)
      end]]
      local axis = self:GetReferenceAxis()
      local delta = Vector()
      delta:Set(axis,(self:ToLocalSpace(intersectPos) -self:ToLocalSpace(self.m_moveStartPos)):Get(axis))
      print("Relative: ",self:IsRelative())
      if(self:IsRelative()) then
        local parent = transformC:GetParent()
        if(util.is_valid(parent)) then
          delta:Rotate(parent:GetRotation())
        end
      end

      local pos = transformC:GetAbsTransformPosition()
      pos = pos +delta

      self.m_moveStartPos = intersectPos
      transformC:SetAbsTransformPosition(pos)
    end
	else
    local cursorAxisAngle = self:GetCursorAxisAngle()
    if(cursorAxisAngle ~= nil) then
      local ang = transformC:GetTransformRotation()
      local axis = self:GetAxis()

      local angAxis = EulerAngles()
      angAxis:Set(axis,cursorAxisAngle -self.m_rotStartAngle)
      local rot = ang:ToQuaternion()
      if(self:IsRelative() == false) then
        rot = angAxis:ToQuaternion() *rot
      else
        rot = rot *rotAxis:ToQuaternion()
      end
      ang = rot:ToEulerAngles()

      self.m_rotStartAngle = cursorAxisAngle
      transformC:SetTransformRotation(ang)
    end
	end
end
function ents.UtilTransformArrowComponent:ToLocalSpace(pos)
  local transformC = self:GetBaseUtilTransformComponent()
  if(transformC == nil) then return pos end
  return transformC:GetEntity():GetPose():GetInverse() *pos
end
function ents.UtilTransformArrowComponent:ToGlobalSpace(pos)
  local transformC = self:GetBaseUtilTransformComponent()
  if(transformC == nil) then return pos end
  return transformC:GetEntity():GetPose() *pos
end
function ents.UtilTransformArrowComponent:OnClick(action,pressed,hitPos)
  if(action ~= input.ACTION_ATTACK) then return util.EVENT_REPLY_UNHANDLED end
  if(pressed == true) then
    local intersectPos = self:GetCursorIntersectionWithAxisPlane()
    if(intersectPos == nil) then return util.EVENT_REPLY_UNHANDLED end

    if(self:GetType() == ents.UtilTransformArrowComponent.TYPE_TRANSLATION) then self.m_moveStartPos = intersectPos
    else self.m_rotStartAngle = self:GetCursorAxisAngle() end
  end
  self:SetSelected(pressed)
  return util.EVENT_REPLY_HANDLED
end

local arrowModel
function ents.UtilTransformArrowComponent:GetArrowModel()
  if(arrowModel ~= nil) then return arrowModel end
  local mdl = game.create_model()
  local meshGroup = mdl:GetMeshGroup(0)
  
  local scale = 1.5
  scale = Vector(scale,scale,scale)
  local mesh = game.Model.Mesh.Create()
  local meshBase = game.Model.Mesh.Sub.CreateCylinder(1.0,16.0,12)
  meshBase:SetSkinTextureIndex(0)
  meshBase:Scale(scale)
  mesh:AddSubMesh(meshBase)
  
  local meshTip = game.Model.Mesh.Sub.CreateCone(
    2.0, -- startRadius
    4.0, -- length
    0.0, -- endRadius
    12 -- segmentCount
  )
  meshTip:SetSkinTextureIndex(0)
  meshTip:Translate(Vector(0.0,0.0,16.0))
  meshTip:Scale(scale)
  mesh:AddSubMesh(meshTip)

  
  meshGroup:AddMesh(mesh)

  mdl:Update(game.Model.FUPDATE_ALL)
  mdl:AddMaterial(0,"tools/toolswhite")
  
  arrowModel = mdl
  return mdl
end

local diskModel
function ents.UtilTransformArrowComponent:GetDiskModel()
  if(diskModel ~= nil) then return diskModel end
  local mdl = game.create_model()
  local meshGroup = mdl:GetMeshGroup(0)
  
  local scale = 1.5
  scale = Vector(scale,scale,scale)
  local mesh = game.Model.Mesh.Create()

  local meshDisk = game.Model.Mesh.Sub.CreateRing(12.0,16.0,true)
  meshDisk:SetSkinTextureIndex(0)
  meshDisk:Scale(scale)
  mesh:AddSubMesh(meshDisk)

  
  meshGroup:AddMesh(mesh)

  mdl:Update(game.Model.FUPDATE_ALL)
  mdl:AddMaterial(0,"tools/toolswhite")
  
  diskModel = mdl
  return mdl
end
ents.COMPONENT_UTIL_TRANSFORM_ARROW = ents.register_component("util_transform_arrow",ents.UtilTransformArrowComponent)
