--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.EntityComponent:SyncUdmPropertyFromEntity(propertyName, clear)
	local udmData = self:GetMemberValue(propertyName)
	if udmData == nil then
		return
	end
	if clear then
		udmData:Clear()
	end
	local entC = self:FindEntityComponent()
	if entC ~= nil then
		local udmDataEnt = entC:GetMemberValue(propertyName):Get()
		if udmDataEnt ~= nil then
			udmData:Merge(udmDataEnt, udm.MERGE_FLAG_BIT_DEEP_COPY)
		end
	end
end
function pfm.udm.EntityComponent:SyncUdmPropertyToEntity(propertyName, clear)
	local entC = self:FindEntityComponent()
	if entC == nil then
		return
	end
	local udmDataEnt = entC:GetMemberValue(propertyName):Get()
	if udmDataEnt == nil then
		return
	end
	if clear then
		udmDataEnt:Clear()
	end
	local udmData = self:GetMemberValue(propertyName)
	if udmData == nil then
		return
	end
	udmDataEnt:Merge(udmData, udm.MERGE_FLAG_BIT_DEEP_COPY)

	local memberId = entC:GetMemberIndex(propertyName)
	if memberId ~= nil then
		entC:OnMemberValueChanged(memberId)
	end
end
function pfm.udm.EntityComponent:FindEntityComponent()
	local actor = self:GetActor()
	local entActor = actor:FindEntity()
	if util.is_valid(entActor) == false then
		return
	end
	return entActor:GetComponent(self:GetType())
end
function pfm.udm.EntityComponent:GetEffectiveMemberValue(propertyName, type)
	local actor = self:GetActor()
	local entActor = actor:FindEntity()
	if util.is_valid(entActor) == false then
		return
	end
	local panimaC = entActor:GetComponent(ents.COMPONENT_PANIMA)
	if panimaC ~= nil and ents.is_member_type_udm_type(type) then
		local manager = panimaC:GetAnimationManager("pfm")
		if manager ~= nil then
			-- Animated property value (for the current timestamp) without math expression
			local val =
				panimaC:GetRawAnimatedPropertyValue(manager, "ec/" .. self:GetType() .. "/" .. propertyName, type)
			if val ~= nil then
				return val
			end
		end
	end

	-- Property isn't animated? Just retrieve it's current value.
	local val = self:GetMemberValue(propertyName)
	if val == nil then
		-- No value has been set, maybe we can still retrieve it from the entity component
		local component = entActor:GetComponent(self:GetType())
		if component ~= nil then
			return component:GetMemberValue(propertyName)
		end
	end
	return val
end

function pfm.udm.EntityComponent:SetMemberValue(memberName, type, value)
	local path = util.Path.CreateFilePath(memberName)
	local props = self:GetProperties()
	local fullMemberPath = memberName
	if path:GetComponentCount() > 1 then
		memberName = path:GetBack()
		path:PopBack()
		props = props:GetFromPath(path:GetString():sub(0, -2))
	end
	if type == ents.MEMBER_TYPE_ELEMENT then
		type = udm.TYPE_ELEMENT
		if value == nil then
			props:Remove(memberName)
		else
			local child = props:Add(memberName)
			local valueWrapped = udm.LinkedPropertyWrapper(value)
			if udm.is_same_element(child, valueWrapped) == false then
				child:Clear()
				child:Merge(valueWrapped, udm.MERGE_FLAG_BIT_DEEP_COPY)
			end
		end
	else
		if value ~= nil then
			props:SetValue(memberName, type, value)
		else
			props:RemoveValue(memberName)
		end
	end
	self:CallChangeListeners(fullMemberPath, value)
end

function pfm.udm.EntityComponent:GetMemberValue(memberName)
	local val = self:GetProperties():GetFromPath(memberName):GetValue()
	if val ~= nil then
		return val
	end
	-- TODO: Copy this value if it is a non-trivial type (e.g. vec3, mat4, etc.)
	return self.m_defaultMemberValues[memberName]
end

function pfm.udm.EntityComponent:GetMemberType(memberName)
	local prop = self:GetProperties():GetFromPath(memberName)
	if util.is_valid(prop) == false then
		return
	end
	return prop:GetType()
end

function pfm.udm.EntityComponent:OnTypeChanged()
	self.m_defaultMemberValues = {}
	local type = self:GetType()
	local id = ents.get_component_id(type)
	if id ~= nil then
		local componentInfo = ents.get_component_info(id)
		if componentInfo ~= nil then
			local numMembers = componentInfo:GetMemberCount()
			for i = 1, numMembers do
				local memberInfo = componentInfo:GetMemberInfo(i - 1)
				assert(memberInfo ~= nil)
				self.m_defaultMemberValues[memberInfo.name] = memberInfo.default
			end
		end
	end

	self:GetParent():OnComponentTypeChanged(self, type)
end

function pfm.udm.EntityComponent:OnInitialize()
	udm.BaseSchemaType.OnInitialize(self)
	self.m_defaultMemberValues = {}
	self:AddChangeListener("type", function(c, type)
		self:OnTypeChanged()
	end)
	if #self:GetType() > 0 then
		self:OnTypeChanged()
	end
end

function pfm.udm.EntityComponent:GetActor()
	return self:GetParent()
end
