--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Actor:FindEntity()
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR) }) do
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if util.is_same_object(actorC:GetActorData(), self) then
			return ent
		end
	end
end

function pfm.udm.Actor:IsVisible()
	local c = self:FindComponent("pfm_actor")
	if c == nil then
		return true
	end
	local visible = c:GetMemberValue("visible")
	if visible == nil then
		return true
	end
	return visible
end

pfm.udm.Actor.POSE_CHANGE_FLAG_NONE = 0
pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_POSITION = 1
pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_ROTATION = 2
pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_SCALE = 4
function pfm.udm.Actor:ChangePose(pose, changeFlags)
	local oldPose = self:GetTransform():Copy()
	self:SetTransform(pose)

	local filmClip = self:GetFilmClip()
	filmClip:CallChangeListeners("OnActorPoseChanged", self, oldPose, pose, changeFlags)
end

function pfm.udm.Actor:GetMemberValue(path)
	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	if componentName == nil then
		return
	end
	local component = self:FindComponent(componentName)
	if component == nil then
		return
	end
	return component:GetMemberValue(pathName:GetString())
end

function pfm.udm.Actor:SetMemberValue(path, type, value)
	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	if componentName == nil then
		return false
	end
	local component = self:FindComponent(componentName)
	if component == nil then
		return false
	end
	component:SetMemberValue(pathName:GetString(), type, value)
	return true
end

function pfm.udm.Actor:GetMemberType(path)
	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	if componentName == nil then
		return
	end
	local component = self:FindComponent(componentName)
	if component == nil then
		return
	end
	return component:GetMemberType(pathName:GetString())
end

function pfm.udm.Actor:FindComponent(name)
	for _, component in ipairs(self:GetComponents()) do
		if component:GetType() == name then
			return component
		end
	end
end

function pfm.udm.Actor:HasComponent(name)
	if type(name) == "string" then
		return self:FindComponent(name) ~= nil
	end
	for _, component in ipairs(self:GetComponents()) do
		if util.is_same_object(name, component) then
			return true
		end
	end
	return false
end

function pfm.udm.Actor:GetFilmClip()
	return self:GetParent():GetFilmClip()
end

function pfm.udm.Actor:AddComponentType(componentType, uuid)
	local component = self:FindComponent(componentType)
	if component ~= nil then
		return component
	end
	component = self:AddComponent()
	if uuid ~= nil then
		component:ChangeUniqueId(uuid)
	end
	component:SetType(componentType)

	self:GetFilmClip():CallChangeListeners("OnActorComponentAdded", self, componentType)
	return component
end

function pfm.udm.Actor:RemoveComponentType(componentType)
	local component = self:FindComponent(componentType)
	if component == nil then
		return
	end
	self:RemoveComponent(component)

	self:GetFilmClip():CallChangeListeners("OnActorComponentRemoved", self, componentType)
end

function pfm.udm.Actor:ChangeModel(mdlName)
	mdlName = asset.normalize_asset_name(mdlName, asset.TYPE_MODEL)
	local mdlC = self:FindComponent("model") or self:AddComponentType("model")
	-- TODO: Clear animation data for this actor?
	debug.start_profiling_task("pfm_load_model")
	local mdl = game.load_model(mdlName)
	debug.stop_profiling_task()
	mdlC:SetMemberValue("model", udm.TYPE_STRING, mdlName)
end

function pfm.udm.Actor:GetModel()
	local mdlC = self:FindComponent("model")
	if mdlC == nil then
		return
	end
	return mdlC:GetMemberValue("model")
end

function pfm.udm.Actor:GetAbsolutePose(filter)
	return self:GetAbsoluteParentPose(filter) * self:GetTransform()
end

function pfm.udm.Actor:OnComponentTypeChanged(c, type)
	if type == "pfm_actor" then
		self.m_pfmActorC = c
	elseif util.is_same_object(c, self.m_pfmActorC) then
		self.m_pfmActorC = nil
	end
end

function pfm.udm.Actor:GetTransform()
	local transform = math.ScaledTransform()
	if self.m_pfmActorC == nil then
		return transform
	end
	local pos = self.m_pfmActorC:GetMemberValue("position")
	local rot = self.m_pfmActorC:GetMemberValue("rotation")
	local scale = self.m_pfmActorC:GetMemberValue("scale")
	if pos ~= nil then
		transform:SetOrigin(pos)
	end
	if rot ~= nil then
		transform:SetRotation(rot)
	end
	if scale ~= nil then
		transform:SetScale(scale)
	end
	return transform
end

function pfm.udm.Actor:SetTransform(t)
	if self.m_pfmActorC == nil then
		return
	end
	self.m_pfmActorC:SetMemberValue("position", udm.TYPE_VECTOR3, t:GetOrigin())
	self.m_pfmActorC:SetMemberValue("rotation", udm.TYPE_QUATERNION, t:GetRotation())
	self.m_pfmActorC:SetMemberValue("scale", udm.TYPE_VECTOR3, t:GetScale())
end

function pfm.udm.Actor:GetAbsoluteParentPose(filter)
	local parent = self:GetParent()
	if parent.TypeName ~= "Group" then
		return math.ScaledTransform()
	end
	return parent:GetAbsolutePose()
end

function pfm.udm.Actor:IsAbsoluteVisible()
	local parent = self:GetParent()
	if parent.TypeName ~= "Group" then
		return true
	end
	return parent:IsAbsoluteVisible()
end

function pfm.udm.Actor:SetBodyGroup(bgName, val)
	local mdlC = self:FindComponent("model") or self:AddComponentType("model")
	local udmData = mdlC:GetUdmData():Get("properties")

	local udmBg = udmData:Get("bodyGroup")
	if udmBg:IsValid() == false then
		udmBg = udmData:Add("bodyGroup")
	end

	udmBg:SetValue(bgName, udm.TYPE_UINT32, val)
end

function pfm.udm.Actor:GetBodyGroup(bgName)
	local mdlC = self:FindComponent("model")
	if mdlC == nil then
		return 0
	end
	local udmData = mdlC:GetUdmData():Get("properties")
	local udmBg = udmData:Get("bodyGroup")
	if udmBg:IsValid() == false then
		return 0
	end
	return udmBg:GetValue(bgName, udm.TYPE_UINT32) or 0
end

function pfm.udm.Actor:SetBodyGroups(bodyGroups)
	local mdlC = self:FindComponent("model") or self:AddComponentType("model")
	local udmData = mdlC:GetUdmData():Get("properties")

	local udmBg = udmData:Get("bodyGroup")
	if udmBg:IsValid() == false then
		udmBg = udmData:Add("bodyGroup")
	end

	for name, val in pairs(bodyGroups) do
		udmBg:SetValue(name, udm.TYPE_UINT32, val)
	end
end

function pfm.udm.Actor:GetBodyGroups()
	local mdlC = self:FindComponent("model")
	if mdlC == nil then
		return {}
	end
	local udmData = mdlC:GetUdmData():Get("properties")
	local udmBg = udmData:Get("bodyGroup")
	if udmBg:IsValid() == false then
		return {}
	end

	local bgs = {}
	for name, _ in pairs(udmBg:GetChildren()) do
		bgs[name] = udmBg:GetValue(name, udm.TYPE_UINT32)
	end
	return bgs
end
