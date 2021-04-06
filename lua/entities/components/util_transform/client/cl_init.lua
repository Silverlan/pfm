include("../shared.lua")
include_component("util_transform_arrow")

local Component = ents.UtilTransformComponent
local flags = bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER,ents.BaseEntityComponent.MEMBER_FLAG_BIT_PROPERTY)
Component:RegisterMember("TranslationEnabled",util.VAR_TYPE_BOOL,true,flags,1)
Component:RegisterMember("RotationEnabled",util.VAR_TYPE_BOOL,true,flags,1)
Component:RegisterMember("Space",util.VAR_TYPE_UINT8,Component.SPACE_WORLD,bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT))),1)

function Component:OnEntitySpawn()
	self:UpdateAxes()

	local parent = self:GetParent()
	self.m_angles = util.is_valid(parent) and parent:GetAngles() or EulerAngles()
	if(util.is_valid(parent)) then self:GetEntity():SetPos(parent:GetPos()) end
end

function Component:SetTranslationAxisEnabled(axis,enabled)
	self.m_translationAxisEnabled[axis] = enabled
	self:UpdateAxes()
end
function Component:SetRotationAxisEnabled(axis,enabled)
	self.m_rotationAxisEnabled[axis] = enabled
	self:UpdateAxes()
end
function Component:IsTranslationAxisEnabled(axis) return self:IsTranslationEnabled() and self.m_translationAxisEnabled[axis] end
function Component:IsRotationAxisEnabled(axis) return self:IsRotationEnabled() and self.m_rotationAxisEnabled[axis] end

if(util.get_class_value(Component,"SetSpaceBase") == nil) then Component.SetSpaceBase = Component.SetSpace end
function Component:SetSpace(space)
	Component.SetSpaceBase(self,space)
	self:UpdateSpace()
end

function Component:UpdateSpace()
	for type,tEnts in pairs(self.m_arrows) do
		for axis,ent in pairs(tEnts) do
			if(ent:IsValid()) then
				local arrowC = ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
				if(arrowC ~= nil) then arrowC:SetSpace(self:GetSpace()) end
			end
		end
	end
end

function Component:UpdateAxes()
	if(self:GetEntity():IsSpawned() == false) then return end
	for i=0,2 do
		if(self:IsTranslationAxisEnabled(i)) then self:CreateTransformUtility(i,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
		elseif(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION] ~= nil and util.is_valid(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION][i])) then self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION][i]:Remove() end

		if(self:IsRotationAxisEnabled(i)) then self:CreateTransformUtility(i,ents.UtilTransformArrowComponent.TYPE_ROTATION)
		elseif(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION] ~= nil and util.is_valid(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION][i])) then self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION][i]:Remove() end
	end
	self:UpdateSpace()
end

function Component:SetParentBone(bone) self.m_parentBone = bone end
function Component:GetParentBone() return self.m_parentBone end

function Component:SetParent(parent,relative)
	self.m_parent = parent
	self.m_relativeToParent = relative or false

	if(relative) then
		local attC = self:AddEntityComponent(ents.COMPONENT_ATTACHABLE)
		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags = ents.AttachableComponent.FATTACHMENT_MODE_SNAP_TO_ORIGIN
		attC:AttachToEntity(parent,attInfo)
	end
end
function Component:GetParent() return self.m_parent end
function Component:GetParentPose()
	if(util.is_valid(self.m_parent) == false) then return phys.Transform() end
	return self.m_parent:GetPose()
end

function Component:GetAbsTransformPosition()
	return self:GetEntity():GetPos()
end

function Component:GetTransformPosition()
	local pos = self:GetAbsTransformPosition()
	if(self.m_relativeToParent == true) then
		pos = self:GetParentPose():GetInverse() *pos
	end
	return pos
end

function Component:SetTransformPosition(pos)
	pos = pos:Copy()
	if(self.m_relativeToParent == true) then
		pos = self:GetParentPose() *pos
	end
	self:SetAbsTransformPosition(pos)
end

function Component:SetAbsTransformPosition(pos)
	local bone = self:GetParentBone()
	if(bone ~= nil) then
		local mdl = self:GetEntity():GetModel()
		local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
		if(mdl ~= nil and animC ~= nil) then
			local boneId = mdl:LookupBone(bone)
			if(boneId ~= -1) then
				animC:SetBonePos(boneId,Vector(123,123,123))
			end
		end
	end
	if(pos:Equals(self:GetEntity():GetPos())) then return end
	self:GetEntity():SetPos(pos)
	if(self.m_relativeToParent == true) then
		pos = self:GetParentPose():GetInverse() *pos
	end
	self:BroadcastEvent(Component.EVENT_ON_POSITION_CHANGED,{pos})
end

function Component:GetTransformRotation() return self.m_angles:Copy() end

function Component:SetTransformRotation(ang)
	if(ang:Equals(self.m_angles)) then return end
	self:GetEntity():SetAngles(ang)
	self.m_angles = ang
	self:BroadcastEvent(Component.EVENT_ON_ROTATION_CHANGED,{ang})
end

function Component:SetReferenceEntity(entRef)
	self.m_refEnt = entRef
	for type,tEnts in pairs(self.m_arrows) do
		for axis,ent in pairs(tEnts) do
			local arrowC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) or nil
			if(arrowC ~= nil) then arrowC:SetReferenceEntity(entRef) end
		end
	end
end

function Component:OnRemove()
	for type,t in pairs(self.m_arrows) do
		for axis,ent in pairs(t) do
			if(ent:IsValid()) then ent:RemoveSafely() end
		end
	end
end

function Component:GetTransformUtility(type,axis)
	if(self.m_arrows[type] == nil) then return end
	return self.m_arrows[type][axis]
end

function Component:CreateTransformUtility(axis,type)
	if(self.m_arrows[type] ~= nil and util.is_valid(self.m_arrows[type][axis])) then return end
	local trC = self:GetEntity():GetComponent(ents.COMPONENT_TRANSFORM)
	local entArrow = ents.create("entity")
	local arrowC = entArrow:AddComponent("util_transform_arrow")
	entArrow:Spawn()
	if(self.m_relativeToParent) then arrowC:SetRelative(true) end
	arrowC:SetAxis(axis)
	arrowC:SetType(type)
	arrowC:SetUtilTransformComponent(self)
	arrowC:SetSpace(self:GetSpace())
	if(util.is_valid(self.m_refEnt)) then arrowC:SetReferenceEntity(self.m_refEnt) end

	arrowC:AddEventCallback(ents.UtilTransformArrowComponent.EVENT_ON_TRANSFORM_START,function()
		for type,tEnts in pairs(self.m_arrows) do
			for axis,ent in pairs(tEnts) do
				if(ent ~= entArrow) then
					local renderC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_RENDER) or nil
					if(renderC ~= nil) then
						renderC:SetRenderMode(ents.RenderComponent.RENDERMODE_NONE)
					end
				end
			end
		end
		self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)
	end)
	arrowC:AddEventCallback(ents.UtilTransformArrowComponent.EVENT_ON_TRANSFORM_END,function()
		for type,tEnts in pairs(self.m_arrows) do
			for axis,ent in pairs(tEnts) do
				local renderC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_RENDER) or nil
				if(renderC ~= nil) then
					renderC:SetRenderMode(ents.RenderComponent.RENDERMODE_WORLD)
				end
			end
		end
		self:UpdateSpace()
		self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_END)
	end)

	local trArrowC = entArrow:GetComponent(ents.COMPONENT_TRANSFORM)
	if(trC ~= nil and trArrowC ~= nil) then
		--trArrowC:GetScaleProperty():Link(trC:GetScaleProperty())
		trArrowC:SetScale(Vector(0.3,0.3,0.3))
	end

	self.m_arrows[type] = self.m_arrows[type] or {}
	self.m_arrows[type][axis] = entArrow
end

Component.EVENT_ON_POSITION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_pos_changed")
Component.EVENT_ON_ROTATION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_rot_changed")
Component.EVENT_ON_TRANSFORM_START = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_transform_start")
Component.EVENT_ON_TRANSFORM_END = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_transform_end")
