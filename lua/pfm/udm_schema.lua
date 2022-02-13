--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function register_type()

end

pfm = pfm or {}
pfm.udm = pfm.udm or {}

local function load_udm(fileName)
	local udmData,err = udm.load("udm_schemas/" .. fileName)
	if(udmData == false) then return false,err end
	local assetData = udmData:GetAssetData()
	local data = assetData:GetData()
	local udmSchema = data:Get("schema")

	for _,include in ipairs(udmSchema:GetArrayValues("includes",udm.TYPE_STRING)) do
		local res,err = load_udm(include)
		if(res == false) then return false,"Failed to load include '" .. include .. "': " .. err end
		udmSchema:Merge(res:Get("schema"))
	end
	return data:ClaimOwnership()
end

local function initialize_udm_element_from_schema_type(el,udmSchema,type)
	local udmSchemaTypeData = udmSchema:GetChild(type)
	if(udmSchemaBaseType == nil) then return false,"Type '" .. type .. "' is not a known type!" end

	return true
end

local function initialize_udm_data_from_schema_object(udmData,udmSchemaType,udmSchema)
	local udmSchemaTypes = udmSchema:GetUdmData():Get("types")
	for name,udmSchemaChild in pairs(udmSchemaType:Get("children"):GetChildren()) do
		local type = udmSchemaChild:GetValue("type",udm.TYPE_STRING)
		local default = udmSchemaChild:Get("default")
		if(type == nil) then
			if(default:IsValid() == false) then return false,"Property '" .. name .. "' in UDM schema has neither type nor default value!" end
			type = udm.enum_type_to_ascii(default:GetType())
		end

		local udmValue = udmData:Get(name)
		local udmSchemaChildType = udmSchemaTypes:Get(type)
		if(udmSchemaChildType:IsValid()) then
			local schemaChildType = udmSchemaChildType:GetValue("type",udm.TYPE_STRING)
			if(schemaChildType == "enum") then
				if(default:IsValid() == false) then return false,"Enum property '" .. name .. "' of type '" .. type .. "' in UDM schema has no default value!" end
				local value = default:GetValue(udm.TYPE_STRING)
				local enumSet = udmSchema:GetEnumSet(type)
				if(enumSet == nil) then return false,"Enum value '" .. value .. "' of property '" .. name .. "' of type '" .. type .. "' references unknown enum set!" end
				local ivalue = enumSet[value]
				if(ivalue == nil) then return false,"Enum value '" .. value .. "' of property '" .. name .. "' of type '" .. type .. "' references unknown enum set!" end
				udmData:SetValue(name,udm.TYPE_STRING,value)
			elseif(schemaChildType ~= nil) then
				return false,"Unknown schema element type '" .. schemaChildType .. "'!"
			else
				if(udmValue:IsValid() == false) then udmValue = udmData:Add(name,udm.TYPE_ELEMENT) end
				local res,msg = initialize_udm_data_from_schema_object(udmValue,udmSchemaChildType,udmSchema)
				if(res ~= true) then return res,msg end
			end
		else
			local udmType = udm.ascii_type_to_enum(type)
			if(udmType == nil or udmType == udm.TYPE_INVALID) then return false,"Type '" .. type .. "' of property '" .. name .. "' is not a known type!" end
			if(udmType == udm.TYPE_ARRAY) then
				local valueType = udmSchemaChild:GetValue("valueType",udm.TYPE_STRING)
				if(valueType == nil) then return false,"Property '" .. name .. "' is array type, but no value type has been specified for array!" end
				local udmSchemaValueType = udmSchemaTypes:Get(valueType)
				local udmValueType
				if(udmSchemaValueType:IsValid()) then udmValueType = udm.TYPE_ELEMENT
				else udmValueType = udm.ascii_type_to_enum(valueType) end
				if(udmValueType == nil or udmValueType == udm.TYPE_INVALID) then return false,"Property '" .. name .. "' is array type, but specified value type '" .. valueType .. "' is not a known type!" end
				udmData:AddArray(name,0,udmValueType)
			else
				-- Initialize value with default
				if(default:IsValid() == false) then return false,"Missing default value for UDM type '" .. type .. "' of property '" .. name .. "'!" end
				udmData:SetValue(name,udmType,default:GetValue())
			end
		end
	end
	return true
end

local function initialize_udm_data_from_schema(udmData,udmSchema,baseType)
	local udmTypes = udmSchema:GetUdmData():GetChildren("types")
	local udmSchemaBaseType = udmTypes[baseType]
	if(udmSchemaBaseType == nil) then
		return false,"Type '" .. baseType .. "' is not a known type!"
	end
	return initialize_udm_data_from_schema_object(udmData,udmSchemaBaseType,udmSchema)
end

util.register_class("udm.Schema")
function udm.Schema:GetUdmData() return self.m_udmData:Get("schema") end
function udm.Schema:GetEnumSet(name) return self.m_enumSets[name] end
function udm.Schema:FindTypeData(type,includeEnumTypes)
	if(includeEnumTypes == nil) then includeEnumTypes = true end
	local prop = self:GetUdmData():Get("types"):Get(type)
	if(prop:IsValid() == false) then return end
	if(includeEnumTypes == false) then
		local type = prop:GetValue("type",udm.TYPE_STRING)
		if(type == "enum") then return end
	end
	return prop
end
function udm.Schema:InitializeType(udmData,type)
	return initialize_udm_data_from_schema(udmData,self,type)
end
function udm.Schema:SetLibrary(lib) self.m_library = lib end
function udm.Schema:GetLibrary() return self.m_library end
udm.Schema.load = function(fileName)
	local udmData,msg = load_udm(fileName)
	if(udmData == false) then return false,msg end
	local schema = udm.Schema()
	schema.m_udmData = udmData
	schema.m_enumSets = {}

	local udmSchemaTypes = schema:GetUdmData():Get("types")
	for name,udmChild in pairs(udmSchemaTypes:GetChildren()) do
		local type = udmChild:GetValue("type",udm.TYPE_STRING)
		if(type == "enum") then
			local values = udmChild:GetArrayValues("values",udm.TYPE_STRING)
			local enumSet = {}
			for i,name in ipairs(values) do
				enumSet[name] = i -1
			end

			schema.m_enumSets[name] = enumSet
		end
	end

	return schema
end

local schema = udm.Schema.load("pfm.udm")
schema:SetLibrary(pfm.udm)
local x = udm.create()
local data = x:GetAssetData():GetData()
local res,msg = schema:InitializeType(data,"Session")
print(res,msg)
--print(data:ToAscii())
--local function initialize_udm_data_from_schema(udmData,udmSchema,baseType)

util.register_class("udm.BaseSchemaType")
function udm.BaseSchemaType:Initialize(schema,udmData,parent)
	self.m_schema = schema
	self.m_udmData = udmData
	self.m_parent = parent
	self.m_typedChildren = {}
	self.m_changeListeners = {}

	local typeData = schema:FindTypeData(self.TypeName)
	for name,child in pairs(typeData:Get("children"):GetChildren()) do
		local childType = child:GetValue("type",udm.TYPE_STRING)
		if(childType ~= nil) then
			local schemaType = schema:FindTypeData(childType)
			if(schemaType ~= nil and schemaType:GetValue("type",udm.TYPE_STRING) ~= "enum") then
				self.m_typedChildren[name] = udm.create_property_from_schema(schema,childType,self,udmData:Get(name))
			elseif(udm.ascii_type_to_enum(childType) == udm.TYPE_ARRAY) then
				local childValueType = child:GetValue("valueType",udm.TYPE_STRING)
				local schemaValueType = schema:FindTypeData(childValueType)
				if(schemaValueType ~= nil and schemaValueType:GetValue("type",udm.TYPE_STRING) ~= "enum") then
					self.m_typedChildren[name] = {}
				end
			end
		end
	end
end
function udm.BaseSchemaType:OnRemove()
	for name,listeners in pairs(self.m_changeListeners) do
		util.remove(listeners)
	end
end
function udm.BaseSchemaType:GetUdmData() return self.m_udmData end
function udm.BaseSchemaType:GetTypedChildren() return self.m_typedChildren end
function udm.BaseSchemaType:GetParent() return self.m_parent end
function udm.BaseSchemaType:AddChangeListener(keyName,listener)
	local cb = util.Callback.Create(listener)
	self.m_changeListeners[keyName] = self.m_changeListeners[keyName] or {}
	table.insert(self.m_changeListeners[keyName],cb)
	return cb
end
function udm.BaseSchemaType:CallChangeListeners(keyName,newValue)
	if(self.m_changeListeners[keyName] == nil) then return end
	local i = 1
	local listeners = self.m_changeListeners[keyName]
	while(i <= #listeners) do
		local cb = listeners[i]
		if(cb:IsValid()) then
			cb:Call(self,newValue)
			i = i +1
		else
			table.remove(listeners,i)
		end
	end
end

function udm.create_property_from_schema(schema,type,parent,el)
	el = el or udm.create_element()
	local res,err = schema:InitializeType(el,type)
	if(res ~= true) then return false,err end
	local obj = schema:GetLibrary()[type]()
	obj:Initialize(schema,el,parent)
	return obj
end

function udm.generate_lua_api_from_schema(schema)
	local lib = schema:GetLibrary()
	for name,udmType in pairs(schema:GetUdmData():GetChildren("types")) do
		local schemaType = udmType:GetValue("type",udm.TYPE_STRING)
		if(schemaType ~= "enum") then
			util.register_class(lib,name,udm.BaseSchemaType)
		else
			local values = udmType:GetArrayValues("values",udm.TYPE_STRING)

			for i,valName in ipairs(values) do
				local val = i -1
				local baseName = name .. valName:sub(1,1):upper() .. valName:sub(2)
				local enumName = ""
				for i=1,#baseName do
					local c = baseName:sub(i,i)
					if(c == c:upper()) then
						if(#enumName > 0) then enumName = enumName .. "_" end
					else c = c:upper() end
					enumName = enumName .. c
				end
				lib[enumName] = val

				lib.detail = lib.detail or {}
				lib.detail.enumSets = lib.detail.enumSets or {}
				lib.detail.enumSets[name] = lib.detail.enumSets[name] or {}
				lib.detail.enumSets[name][valName] = val
				lib.detail.enumSets[name][val] = valName
			end
		end
	end
	for name,udmType in pairs(schema:GetUdmData():GetChildren("types")) do
		local schemaType = udmType:GetValue("type",udm.TYPE_STRING)
		if(schemaType ~= "enum") then
			local class = lib[name]
			class.TypeName = name
			for name,udmChild in pairs(udmType:GetChildren("children")) do
				local nameUpper = name:sub(1,1):upper() .. name:sub(2)
				local getterName = udmChild:GetValue("getterName",udm.TYPE_STRING) or ("Get" .. nameUpper)
				local setterName = udmChild:GetValue("setterName",udm.TYPE_STRING) or ("Set" .. nameUpper)
				local stype = udmChild:GetValue("type",udm.TYPE_STRING)
				local udmType
				if(stype == nil) then
					local default = udmChild:Get("default")
					if(default:IsValid()) then
						udmType = default:GetType()
					end
				end
				if(udmType == nil) then udmType = udm.ascii_type_to_enum(stype) end
				if(udmType == nil or udmType == udm.TYPE_INVALID) then
					if(stype == "any") then
						-- TODO
					else
						-- Check classes
						local childClass = lib[stype]
						if(childClass ~= nil) then
							class[getterName] = function(self)
								return self:GetTypedChildren()[name]
							end
						else
							local schemaType = schema:FindTypeData(stype)
							if(schemaType ~= nil) then
								local specType = schemaType:GetValue("type",udm.TYPE_STRING)
								if(specType == "enum") then
									local underlyingType = schemaType:GetValue("underlyingType",udm.TYPE_STRING) or "int32"
									local udmUnderlyingType = udm.ascii_type_to_enum(underlyingType)
									if(udmUnderlyingType == nil or udmUnderlyingType == udm.TYPE_INVALID) then
										print("Invalid underlying type '" .. underlyingType .. "' used for enum '" .. stype .. "'!")
									else
										class[getterName] = function(self)
											local value = self:GetUdmData():GetValue(name,udm.TYPE_STRING)
											return lib.detail.enumSets[stype][value]
										end
										class[getterName .. "Name"] = function(self)
											return self:GetUdmData():GetValue(name,udm.TYPE_STRING)
										end
										class[setterName] = function(self,val)
											if(type(val) == "number") then
												val = lib.detail.enumSets[stype][val]
												if(val == nil) then error("Not a valid enum!") end
											end
											if(lib.detail.enumSets[stype][val] == nil) then error("Not a valid enum!") end
											self:GetUdmData():SetValue(name,udm.TYPE_STRING,val)
											self:CallChangeListeners(name,val)
										end
									end
								end
							end
						end
					end
				else
					if(udmType == udm.TYPE_ARRAY) then
						local baseName = udmChild:GetValue("baseName",udm.TYPE_STRING)
						if(baseName ~= nil) then
							local valueType = udmChild:GetValue("valueType",udm.TYPE_STRING)
							local schemaValueType = schema:FindTypeData(valueType,false)
							local elementGetterName = "Get" .. baseName
							if(elementGetterName ~= nil) then
								class[elementGetterName] = function(self,i)
									if(schemaValueType ~= nil) then return self:GetTypedChildren()[name][i +1] end
									local a = self:GetUdmData():Get(name)
									if(i >= a:GetSize()) then return end
									local el = a:Get(i)
									if(el:IsValid() == false) then return end
									return el:GetValue(valueType)
								end
							end

							if(schemaValueType == nil) then
								local elementSetterName = "Set" .. baseName
								if(elementSetterName ~= nil) then
									class[elementSetterName] = function(self,i,value)
										self:GetUdmData():Get(name):SetValue(i,value)
									end
								end
							end

							local adderName = "Add" .. baseName
							if(adderName ~= nil) then
								class[adderName] = function(self)
									local el = self:GetUdmData():Get(name)
									el:Resize(el:GetSize() +1)
									if(schemaValueType ~= nil) then
										local child = el:Get(el:GetSize() -1)
										local prop = udm.create_property_from_schema(schema,valueType,self,child)
										table.insert(self:GetTypedChildren()[name],prop)
										return prop
									end
									return el:GetValue(el:GetSize() -1,valueType)
								end
							end

							local removerName = "Remove" .. baseName
							if(removerName ~= nil) then
								class[removerName] = function(self,idx)
									local a = self:GetUdmData():Get(name)
									if(idx >= a:GetSize()) then return end
									a:RemoveValue(idx)
									table.remove(self:GetTypedChildren()[name],idx +1)
								end
							end
						end
					end
					class[getterName] = function(self)
						return self:GetUdmData():GetValue(name,udmType)
					end
					class[setterName] = function(self,value)
						self:GetUdmData():SetValue(name,udmType,value)
						self:CallChangeListeners(name,value)
					end
				end
				-- TODO: Array
			end
		end
	end
	return true
end

udm.generate_lua_api_from_schema(schema,pfm.udm)
local session = udm.create_property_from_schema(schema,"Session")
session:GetSettings():GetRenderSettings():AddChangeListener("samples",function(rs,newSamples)
	print("New samples: ",newSamples)
end)
session:GetSettings():GetRenderSettings():SetSamples(12)
session:GetSettings():GetRenderSettings():SetPreviewQuality(2)
print("Preview quality: ",session:GetSettings():GetRenderSettings():GetPreviewQualityName())
--session:AddClip()
--[[print(session:GetSettings():GetRenderSettings():GetUdmData())
print(session:AddClip())
session:RemoveClip(0)]]
--print(session:GetClip(session:GetActiveClip()):GetTimeFrame():GetScale())

--[[local x = udm.create()
x:GetAssetData():GetData():SetValue("session",session:GetUdmData())--Merge(session:GetUdmData())
x:SaveAscii("test.udm")]]


-- lua_exec_cl pfm/udm_schema.lua

