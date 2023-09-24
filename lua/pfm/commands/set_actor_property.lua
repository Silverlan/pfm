--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetActorProperty", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, oldValue, newValue, memberType)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	local oldValue, type = self:ToUdmValue(oldValue, memberType)
	local newValue, type = self:ToUdmValue(newValue, memberType)
	data:SetValue("actor", udm.TYPE_STRING, pfm.get_unique_id(actorUuid))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	if oldValue ~= nil then
		data:SetValue("oldValue", type, oldValue)
	end
	data:SetValue("newValue", type, newValue)
	data:SetValue("udmValueType", udm.TYPE_STRING, ents.member_type_to_string(type))
	data:SetValue("entityValueType", udm.TYPE_STRING, ents.member_type_to_string(memberType))
	return true
end
function Command:ToUdmValue(value, valueType)
	local udmValue = value
	local udmType = valueType
	if valueType == ents.MEMBER_TYPE_ENTITY then
		if type(udmValue) == "string" then
			udmType = udm.TYPE_STRING
		else
			local uuid = udmValue:GetUuid()
			if uuid:IsValid() then
				udmValue = tostring(uuid)
			else
				udmValue = ""
			end
			udmType = udm.TYPE_STRING
		end
	elseif valueType == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
		if type(udmValue) == "string" then
			udmType = udm.TYPE_STRING
		else
			udmValue = udmValue:GetPath() or ""
			udmType = udm.TYPE_STRING
		end
	end
	return udmValue, udmType
end
function Command:ApplyValue(key)
	local pm = self:GetProjectManager()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor with uuid '" .. actorUuid .. "' not found!")
		return
	end

	local strType = data:GetValue("udmValueType", udm.TYPE_STRING)
	local type = ents.string_to_member_type(strType)
	if type == nil then
		self:LogFailure("Invalid value type '" .. strType .. "'!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local componentName, memberName =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath))

	if componentName == nil then
		self:LogFailure("Failed to parse property path '" .. propertyPath .. "'!")
		return
	end

	local c = actor:FindComponent(componentName)
	if c == nil then
		self:LogFailure("Could not find component '" .. componentName .. "' in actor '" .. actorUuid .. "'!")
		return
	end

	local value = data:GetValue(key, type)
	--[[if value == nil then
		self:LogFailure("Invalid value for '" .. key .. "'!")
		return
	end]]

	-- Apply value to UDM component
	c:SetMemberValue(memberName:GetString(), type, value)

	if type ~= udm.TYPE_ELEMENT and value ~= nil then
		-- TODO: If value is nil, we should restore the default value
		local ent = actor:FindEntity()
		if util.is_valid(ent) then
			-- Apply value directly to entity
			local entValue = value

			local strEntType = data:GetValue("entityValueType", udm.TYPE_STRING)
			local entValueType = ents.string_to_member_type(strEntType)
			if entValueType == nil then
				self:LogFailure("Invalid entity value type '" .. strEntType .. "'!")
				return
			end

			-- If the property type is a non-udm type, we have to do some additional steps
			if entValueType == ents.MEMBER_TYPE_ELEMENT then
				local entC = ent:FindComponent(componentName)
				if entC ~= nil then
					local udmVal = entC:GetMemberValue(memberName:GetString())
					if udmVal ~= nil then
						local value = c:GetMemberValue(memberName:GetString())
						if value ~= nil then
							udmVal:Clear()
							udmVal:Merge(value, udm.MERGE_FLAG_BIT_DEEP_COPY)
							entC:InvokeElementMemberChangeCallback(memberIdx) -- TODO
						end
					end
				end
			else
				if entValueType == ents.MEMBER_TYPE_ENTITY then
					entValue = ents.UniversalEntityReference(util.Uuid(value))
				elseif entValueType == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
					entValue = ents.UniversalMemberReference(value)
				end
			end
			ent:SetMemberValue(propertyPath, entValue)
		end
	end

	-- Mark actor and property as dirty
	self:SetActorPropertyDirty(actor, propertyPath)
end
function Command:DoExecute(data)
	self:ApplyValue("newValue")
end
function Command:DoUndo(data)
	self:ApplyValue("oldValue")
end
pfm.register_command("set_actor_property", Command)
