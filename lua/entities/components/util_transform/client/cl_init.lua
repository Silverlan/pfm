include("../shared.lua")
include_component("util_transform_arrow")

local Component = ents.UtilTransformComponent
local flags = bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER,ents.BaseEntityComponent.MEMBER_FLAG_BIT_PROPERTY)
Component:RegisterMember("TranslationEnabled",udm.TYPE_BOOLEAN,true,{},flags)
Component:RegisterMember("RotationEnabled",udm.TYPE_BOOLEAN,true,{},flags)
Component:RegisterMember("ScaleEnabled",udm.TYPE_BOOLEAN,false,{},flags)
Component:RegisterMember("Space",udm.TYPE_UINT8,Component.SPACE_WORLD,{},bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT))))

function Component:ScheduleUpdate()
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnTick()
	self:UpdateAxes()
end
function Component:OnEntitySpawn()
	self:ScheduleUpdate()

	local parent = self:GetParent()
	self.m_angles = util.is_valid(parent) and parent:GetAngles() or EulerAngles()
	if(util.is_valid(parent)) then self:GetEntity():SetPos(parent:GetPos()) end
end

function Component:SetTranslationAxisEnabled(axis,enabled)
	self.m_translationAxisEnabled[axis] = enabled
	self:ScheduleUpdate()
end
function Component:SetRotationAxisEnabled(axis,enabled)
	self.m_rotationAxisEnabled[axis] = enabled
	self:ScheduleUpdate()
end
function Component:SetScaleAxisEnabled(axis,enabled)
	self.m_scaleAxisEnabled[axis] = enabled
	self:ScheduleUpdate()
end
function Component:IsTranslationAxisEnabled(axis) return self:IsTranslationEnabled() and self.m_translationAxisEnabled[axis] end
function Component:IsRotationAxisEnabled(axis) return self:IsRotationEnabled() and self.m_rotationAxisEnabled[axis] end
function Component:IsScaleAxisEnabled(axis) return self:IsScaleEnabled() and self.m_scaleAxisEnabled[axis] end

if(util.get_class_value(Component,"SetSpaceBase") == nil) then Component.SetSpaceBase = Component.SetSpace end
function Component:SetSpace(space)
	Component.SetSpaceBase(self,space)
	self:UpdateSpace()
end

function Component:UpdateSpace()
	for _,ent in ipairs(self:GetArrowEntities()) do
		local arrowC = ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
		if(arrowC ~= nil) then arrowC:SetSpace(self:GetSpace()) end
	end
end

function Component:RemoveTransformUtility(id,type,axis)
	if(self.m_arrows[type] == nil or self.m_arrows[type][axis] == nil) then return end
	util.remove(self.m_arrows[type][axis][id])
end

function Component:UpdateAxes()
	if(self:GetEntity():IsSpawned() == false) then return end
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	for i=0,2 do
		if(self:IsTranslationAxisEnabled(i)) then self:CreateTransformUtility("translation",i,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
		else self:RemoveTransformUtility("translation",i,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end

		if(self:IsRotationAxisEnabled(i)) then self:CreateTransformUtility("rotation",i,ents.UtilTransformArrowComponent.TYPE_ROTATION)
		else self:RemoveTransformUtility("rotation",i,ents.UtilTransformArrowComponent.TYPE_ROTATION) end

		if(self:IsScaleAxisEnabled(i)) then self:CreateTransformUtility("scale",i,ents.UtilTransformArrowComponent.TYPE_SCALE)
		else self:RemoveTransformUtility("scale",i,ents.UtilTransformArrowComponent.TYPE_SCALE) end
	end

	if(self:IsTranslationAxisEnabled(ents.UtilTransformArrowComponent.AXIS_X)) then self:CreateTransformUtility("xy",ents.UtilTransformArrowComponent.AXIS_XY,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
	else self:RemoveTransformUtility("xy",ents.UtilTransformArrowComponent.AXIS_X,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end

	if(self:IsTranslationAxisEnabled(ents.UtilTransformArrowComponent.AXIS_Y)) then self:CreateTransformUtility("yz",ents.UtilTransformArrowComponent.AXIS_YZ,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
	else self:RemoveTransformUtility("yz",ents.UtilTransformArrowComponent.AXIS_Y,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end

	if(self:IsTranslationAxisEnabled(ents.UtilTransformArrowComponent.AXIS_Z)) then self:CreateTransformUtility("xz",ents.UtilTransformArrowComponent.AXIS_XZ,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
	else self:RemoveTransformUtility("xz",ents.UtilTransformArrowComponent.AXIS_Y,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end

	if(self:IsTranslationAxisEnabled(ents.UtilTransformArrowComponent.AXIS_Z)) then self:CreateTransformUtility("xyz",ents.UtilTransformArrowComponent.AXIS_XYZ,ents.UtilTransformArrowComponent.TYPE_TRANSLATION)
	else self:RemoveTransformUtility("xyz",ents.UtilTransformArrowComponent.AXIS_Y,ents.UtilTransformArrowComponent.TYPE_TRANSLATION) end

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
	if(util.is_valid(self.m_parent) == false) then return math.Transform() end
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

function Component:SetTransformScale(scale)
	local bone = self:GetParentBone()
	if(bone ~= nil) then
		local mdl = self:GetEntity():GetModel()
		local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
		if(mdl ~= nil and animC ~= nil) then
			local boneId = mdl:LookupBone(bone)
			if(boneId ~= -1) then
				-- animC:SetBonePos(boneId,Vector(123,123,123))
			end
		end
	end
	if(scale:Equals(self:GetEntity():GetScale())) then return end
	--[[self:GetEntity():SetPos(pos)
	if(self.m_relativeToParent == true) then
		pos = self:GetParentPose():GetInverse() *pos
	end]]
	self:BroadcastEvent(Component.EVENT_ON_SCALE_CHANGED,{scale})
end

function Component:SetAbsTransformPosition(pos)
	local bone = self:GetParentBone()
	if(bone ~= nil) then
		local mdl = self:GetEntity():GetModel()
		local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
		if(mdl ~= nil and animC ~= nil) then
			local boneId = mdl:LookupBone(bone)
			if(boneId ~= -1) then
				-- animC:SetBonePos(boneId,Vector(123,123,123))
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

function Component:GetArrowEntities()
	local r = {}
	for type,t in pairs(self.m_arrows) do
		for axis,tEnts in pairs(t) do
			for id,ent in pairs(tEnts) do
				if(ent:IsValid()) then
					table.insert(r,ent)
				end
			end
		end
	end
	return r
end

function Component:SetTransformRotation(rot)--ang)
	--if(ang:Equals(self.m_angles)) then return end
	self:GetEntity():SetRotation(rot)
	--self.m_angles = ang
	self:BroadcastEvent(Component.EVENT_ON_ROTATION_CHANGED,{rot})

	for _,ent in ipairs(self:GetArrowEntities()) do
		local arrowC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) or nil
		if(arrowC ~= nil) then
			arrowC:UpdateRotation()
		end
	end
end

function Component:SetReferenceEntity(entRef)
	self.m_refEnt = entRef
	for _,ent in ipairs(self:GetArrowEntities()) do
		local arrowC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) or nil
		if(arrowC ~= nil) then arrowC:SetReferenceEntity(entRef) end
	end
end

function Component:OnRemove()
	util.remove(self:GetArrowEntities())
end

function Component:GetTransformUtility(type,axis,id)
	if(self.m_arrows[type] == nil) then return end
	local t = self.m_arrows[type][axis]
	if(id == nil) then return t end
	if(t == nil) then return end
	return t[id]
end

function Component:CreateTransformUtility(id,axis,type)
	if(self.m_arrows[type] ~= nil and self.m_arrows[type][axis] ~= nil and util.is_valid(self.m_arrows[type][axis][id])) then return end
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
		if(type == ents.UtilTransformArrowComponent.TYPE_ROTATION and self:GetSpace() == Component.SPACE_WORLD) then
			for _,ent in ipairs(self:GetArrowEntities()) do
				if(util.is_same_object(ent,entArrow) == false) then
					local renderC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_RENDER) or nil
					if(renderC ~= nil) then
						renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE)
					end
				end
			end
		end
		self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)
	end)
	arrowC:AddEventCallback(ents.UtilTransformArrowComponent.EVENT_ON_TRANSFORM_END,function()
		for _,ent in ipairs(self:GetArrowEntities()) do
			local renderC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_RENDER) or nil
			if(renderC ~= nil) then
				renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_WORLD)
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
	self.m_arrows[type][axis] = self.m_arrows[type][axis] or {}
	self.m_arrows[type][axis][id] = entArrow
end

Component.EVENT_ON_POSITION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_pos_changed")
Component.EVENT_ON_ROTATION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_rot_changed")
Component.EVENT_ON_SCALE_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_scale_changed")
Component.EVENT_ON_TRANSFORM_START = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_transform_start")
Component.EVENT_ON_TRANSFORM_END = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM,"on_transform_end")
