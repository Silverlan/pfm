include("../shared.lua")
include_component("util_transform_arrow")

local flags = bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER)
ents.UtilTransformComponent:RegisterMember("TranslationEnabled",util.VAR_TYPE_BOOL,true,flags,1)
ents.UtilTransformComponent:RegisterMember("RotationEnabled",util.VAR_TYPE_BOOL,true,flags,1)

function ents.UtilTransformComponent:OnEntitySpawn()
  for i=0,2 do
    if(self:IsTranslationEnabled()) then self:CreateTransformUtility(i,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end
    if(self:IsRotationEnabled()) then self:CreateTransformUtility(i,ents.UtilTransformArrowComponent.TYPE_ROTATION) end
  end

  local parent = self:GetParent()
  self.m_angles = util.is_valid(parent) and parent:GetAngles() or EulerAngles()
  if(util.is_valid(parent)) then self:GetEntity():SetPos(parent:GetPos()) end
end

function ents.UtilTransformComponent:SetParent(parent,relative)
  self.m_parent = parent
  self.m_relativeToParent = relative or false

  if(relative) then
    local attC = self:AddEntityComponent(ents.COMPONENT_ATTACHABLE)
    local attInfo = ents.AttachableComponent.AttachmentInfo()
    attInfo.flags = ents.AttachableComponent.FATTACHMENT_MODE_SNAP_TO_ORIGIN
    attC:AttachToEntity(parent,attInfo)
  end
end
function ents.UtilTransformComponent:GetParent() return self.m_parent end
function ents.UtilTransformComponent:GetParentPose()
  if(util.is_valid(self.m_parent) == false) then return phys.Transform() end
  return self.m_parent:GetPose()
end

function ents.UtilTransformComponent:GetAbsTransformPosition()
  return self:GetEntity():GetPos()
end

function ents.UtilTransformComponent:GetTransformPosition()
  local pos = self:GetAbsTransformPosition()
  if(self.m_relativeToParent == true) then
    pos = self:GetParentPose():GetInverse() *pos
  end
  return pos
end

function ents.UtilTransformComponent:SetTransformPosition(pos)
  pos = pos:Copy()
  if(self.m_relativeToParent == true) then
    pos = self:GetParentPose() *pos
  end
  self:SetAbsTransformPosition(pos)
end

function ents.UtilTransformComponent:SetAbsTransformPosition(pos)
  if(pos:Equals(self:GetEntity():GetPos())) then return end
  self:GetEntity():SetPos(pos)
  if(self.m_relativeToParent == true) then
    pos = self:GetParentPose():GetInverse() *pos
  end
  self:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,{pos})
end

function ents.UtilTransformComponent:GetTransformRotation() return self.m_angles:Copy() end

function ents.UtilTransformComponent:SetTransformRotation(ang)
  if(ang:Equals(self.m_angles)) then return end
  self.m_angles = ang
  self:BroadcastEvent(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,{ang})
end

function ents.UtilTransformComponent:CreateTransformUtility(axis,type)
  local entArrow = ents.create("entity")
  local arrowC = entArrow:AddComponent("util_transform_arrow")
  entArrow:Spawn()
  if(self.m_relativeToParent) then arrowC:SetRelative(true) end
  arrowC:SetAxis(axis)
  arrowC:SetType(type)
  arrowC:SetUtilTransformComponent(self)
  
  table.insert(self.m_arrows,entArrow)
  self:GetEntity():RemoveEntityOnRemoval(entArrow)
end

ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_pos_changed")
ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_rot_changed")
