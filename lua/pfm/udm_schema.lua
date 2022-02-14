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

local function is_enum_type(schemaType) return schemaType == "enum" or schemaType == "enum_flags" end
local function initialize_udm_data_from_schema_object(udmData,udmSchemaType,udmSchema)
	local udmSchemaTypes = udmSchema:GetUdmData():Get("types")
	for name,udmSchemaChild in pairs(udmSchemaType:Get("children"):GetChildren()) do
		local type = udmSchemaChild:GetValue("type",udm.TYPE_STRING)
		local default = udmSchemaChild:Get("default")
		if(type == nil) then
			if(default:IsValid() == false) then error("Property '" .. name .. "' in UDM schema has neither type nor default value!") end
			type = udm.enum_type_to_ascii(default:GetType())
		end

		local udmValue = udmData:Get(name)
		local udmSchemaChildType = udmSchemaTypes:Get(type)
		if(udmSchemaChildType:IsValid()) then
			local schemaChildType = udmSchemaChildType:GetValue("type",udm.TYPE_STRING)
			if(is_enum_type(schemaChildType)) then
				if(default:IsValid() == false) then error("Enum property '" .. name .. "' of type '" .. type .. "' in UDM schema has no default value!") end
				local value = default:GetValue(udm.TYPE_STRING)
				local enumSet = udmSchema:GetEnumSet(type)
				if(enumSet == nil) then error("Enum value '" .. value .. "' of property '" .. name .. "' of type '" .. type .. "' references unknown enum set!") end
				local ivalue = enumSet[value]
				if(ivalue == nil) then error("Enum value '" .. value .. "' of property '" .. name .. "' of type '" .. type .. "' is not a valid enum!") end
				udmData:SetValue(name,udm.TYPE_STRING,value)
			elseif(schemaChildType ~= nil) then
				error("Unknown schema element type '" .. schemaChildType .. "'!")
			else
				if(udmValue:IsValid() == false) then udmValue = udmData:Add(name,udm.TYPE_ELEMENT) end
				local res,msg = initialize_udm_data_from_schema_object(udmValue,udmSchemaChildType,udmSchema)
				if(res ~= true) then return res,msg end
			end
		elseif(type == "Reference") then
			udmData:SetValue(name,udm.TYPE_STRING,"")
		elseif(type == "Uuid") then
			udmData:SetValue(name,udm.TYPE_STRING,tostring(util.generate_uuid_v4()))
		else
			local udmType = udm.ascii_type_to_enum(type)
			if(udmType == nil or udmType == udm.TYPE_INVALID) then error("Type '" .. type .. "' of property '" .. name .. "' is not a known type!") end
			if(udmType == udm.TYPE_ARRAY) then
				local valueType = udmSchemaChild:GetValue("valueType",udm.TYPE_STRING)
				if(valueType == nil) then error("Property '" .. name .. "' is array type, but no value type has been specified for array!") end
				local udmSchemaValueType = udmSchemaTypes:Get(valueType)
				local udmValueType
				if(udmSchemaValueType:IsValid()) then udmValueType = udm.TYPE_ELEMENT
				else udmValueType = udm.ascii_type_to_enum(valueType) end
				if(valueType ~= "Any") then -- "any" is a special case where we don't know the actual type yet
					if(udmValueType == nil or udmValueType == udm.TYPE_INVALID) then error("Property '" .. name .. "' is array type, but specified value type '" .. valueType .. "' is not a known type!") end
					udmData:AddArray(name,0,udmValueType)
				end
			else
				-- Initialize value with default
				if(default:IsValid() == false) then
					local opt = udmSchemaChild:Get("optional") or false
					if(opt == false) then error("Missing default value for UDM type '" .. type .. "' of property '" .. name .. "'!") end
					udmData:SetValue(name,udm.TYPE_NIL,nil)
				else udmData:SetValue(name,udmType,default:GetValue()) end
			end
		end
	end
	return true
end

local function initialize_udm_data_from_schema(udmData,udmSchema,baseType)
	local udmTypes = udmSchema:GetUdmData():GetChildren("types")
	local udmSchemaBaseType = udmTypes[baseType]
	if(udmSchemaBaseType == nil) then
		error("Type '" .. baseType .. "' is not a known type!")
	end
	return initialize_udm_data_from_schema_object(udmData,udmSchemaBaseType,udmSchema)
end

util.register_class("udm.Schema")
function udm.Schema:__init()
	self.m_seed = 0
end
function udm.Schema:GetUdmData() return self.m_udmData:Get("schema") end
function udm.Schema:GetEnumSet(name) return self.m_enumSets[name] end
function udm.Schema:FindTypeData(type,includeEnumTypes)
	if(includeEnumTypes == nil) then includeEnumTypes = true end
	local prop = self:GetUdmData():Get("types"):Get(type)
	if(prop:IsValid() == false) then return end
	if(includeEnumTypes == false) then
		local type = prop:GetValue("type",udm.TYPE_STRING)
		if(is_enum_type(type)) then return end
	end
	return prop
end
function udm.Schema:InitializeType(udmData,type)
	return initialize_udm_data_from_schema(udmData,self,type)
end
function udm.Schema:SetSeed(seed) self.m_seed = seed end
function udm.Schema:GetSeed() return self.m_seed end
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
		if(is_enum_type(type)) then
			if(type == "enum") then
				local values = udmChild:GetArrayValues("values",udm.TYPE_STRING)
				local enumSet = {}
				for i,name in ipairs(values) do
					enumSet[name] = i -1
				end

				schema.m_enumSets[name] = enumSet
			elseif(type == "enum_flags") then
				local enumSet = {}
				for name,val in pairs(udmChild:Get("values"):GetChildren()) do
					enumSet[name] = val:GetValue()
				end

				schema.m_enumSets[name] = enumSet
			end
		end
	end
	return schema
end

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
			if(schemaType ~= nil and is_enum_type(schemaType:GetValue("type",udm.TYPE_STRING)) == false) then
				self.m_typedChildren[name] = udm.create_property_from_schema(schema,childType,self,udmData:Get(name))
			elseif(udm.ascii_type_to_enum(childType) == udm.TYPE_ARRAY) then
				local childValueType = child:GetValue("valueType",udm.TYPE_STRING)
				local schemaValueType = schema:FindTypeData(childValueType)
				if(schemaValueType ~= nil and is_enum_type(schemaValueType:GetValue("type",udm.TYPE_STRING)) == false) then
					self.m_typedChildren[name] = {}
				end
			end
		end
	end
end
function udm.BaseSchemaType:Remove() self:OnRemove() end
function udm.BaseSchemaType:OnRemove()
	for name,listeners in pairs(self.m_changeListeners) do
		util.remove(listeners)
	end
	if(self.GetUniqueId) then
		self.m_schema:GetLibrary().detail.referenceables[tostring(self:GetUniqueId())] = nil
	end
	for name,child in pairs(self.m_typedChildren) do
		if(type(child) == "table") then for _,c in ipairs(child) do c:OnRemove() end
		else child:OnRemove() end
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
	if(obj.GetUniqueId) then schema:GetLibrary().detail.referenceables[tostring(obj:GetUniqueId())] = obj end
	return obj
end

local function get_enum_name(name,valName)
	local baseName = name .. valName:sub(1,1):upper() .. valName:sub(2)
	local enumName = ""
	for i=1,#baseName do
		local c = baseName:sub(i,i)
		if(c == c:upper()) then
			if(#enumName > 0) then enumName = enumName .. "_" end
		else c = c:upper() end
		enumName = enumName .. c
	end
	return enumName
end

function udm.generate_lua_api_from_schema(schema)
	local lib = schema:GetLibrary()
	lib.detail = lib.detail or {}
	lib.detail.referenceables = lib.detail.referenceables or {}
	for name,udmType in pairs(schema:GetUdmData():GetChildren("types")) do
		local schemaType = udmType:GetValue("type",udm.TYPE_STRING)
		if(is_enum_type(schemaType) == false) then
			util.register_class(lib,name,udm.BaseSchemaType)
		else
			local values = udmType:GetArrayValues("values",udm.TYPE_STRING)
			if(schemaType == "enum" or schemaType == "enum_flags") then
				lib.detail = lib.detail or {}
				lib.detail.enumSets = lib.detail.enumSets or {}
				lib.detail.enumSets[name] = lib.detail.enumSets[name] or {}
				if(schemaType == "enum") then
					for i,valName in ipairs(values) do
						local val = i -1
						lib[get_enum_name(name,valName)] = val

						lib.detail.enumSets[name][valName] = val
						lib.detail.enumSets[name][val] = valName
					end
				elseif(schemaType == "enum_flags") then
					for valName,val in pairs(udmType:Get("values"):GetChildren()) do
						val = val:GetValue()
						lib[get_enum_name(name,valName)] = val

						lib.detail.enumSets[name][valName] = val
						lib.detail.enumSets[name][val] = valName
					end
				end
			else
				error("Invalid schema type '" .. schemaType .. "'!")
			end
		end
	end
	for name,udmType in pairs(schema:GetUdmData():GetChildren("types")) do
		local schemaType = udmType:GetValue("type",udm.TYPE_STRING)
		if(is_enum_type(schemaType) == false) then
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
					if(stype == "Any") then
						-- TODO
					elseif(stype == "Uuid") then
						class[getterName] = function(self)
							return util.Uuid(self:GetUdmData():GetValue(name,udm.TYPE_STRING))
						end
						class[setterName] = function(self,value)
							self:GetUdmData():SetValue(name,udm.TYPE_STRING,tostring(value))
							self:CallChangeListeners(name,(util.get_type_name(value) == "Uuid") and value or util.Uuid(value))
						end
					elseif(stype == "Reference") then
						class[getterName .. "Id"] = function(self)
							return util.Uuid(self:GetUdmData():GetValue(name,udm.TYPE_STRING))
						end
						class[setterName .. "Id"] = function(self,value)
							self:GetUdmData():SetValue(name,udm.TYPE_STRING,tostring(value))
							self:CallChangeListeners(name,(util.get_type_name(value) == "Uuid") and value or util.Uuid(value))
						end
						class[getterName] = function(self)
							return lib.detail.referenceables[self:GetUdmData():GetValue(name,udm.TYPE_STRING)]
						end
						class[setterName] = function(self,value)
							local type = util.get_type_name(value)
							if(type == "Uuid" or type == "string") then
								if(type == "Uuid") then value = tostring(value) end
								local o = lib.detail.referenceables[value]
								if(o == nil) then error("Uuid '" .. value .. "' does not refer to known object!") end
							else value = tostring(value:GetUniqueId()) end
							self:GetUdmData():SetValue(name,udm.TYPE_STRING,value)
							self:CallChangeListeners(name,util.Uuid(value))
						end
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
								if(is_enum_type(specType)) then
									local underlyingType = schemaType:GetValue("underlyingType",udm.TYPE_STRING) or "int32"
									local udmUnderlyingType = udm.ascii_type_to_enum(underlyingType)
									if(udmUnderlyingType == nil or udmUnderlyingType == udm.TYPE_INVALID) then
										error("Invalid underlying type '" .. underlyingType .. "' used for enum '" .. stype .. "'!")
									else
										class[getterName .. "Name"] = function(self)
											return self:GetUdmData():GetValue(name,udm.TYPE_STRING)
										end
										if(specType == "enum") then
											class[getterName] = function(self)
												local value = self:GetUdmData():GetValue(name,udm.TYPE_STRING)
												return lib.detail.enumSets[stype][value]
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
										elseif(specType == "enum_flags") then
											class[getterName] = function(self)
												local value = self:GetUdmData():GetValue(name,udm.TYPE_STRING)
												local bitValues = 0
												for _,strVal in ipairs(string.split(value,"|")) do
													local val = lib.detail.enumSets[stype][strVal]
													if(val == nil) then error("Not a valid enum!") end
													bitValues = bit.bor(bitValues,val)
												end
												return bitValues
											end
											class[setterName] = function(self,val)
												local str = ""
												for _,v in ipairs(math.get_power_of_2_values(val)) do
													if(#str > 0) then str = str .. "|" end
													str = str .. lib.detail.enumSets[stype][v]
												end
												self:GetUdmData():SetValue(name,udm.TYPE_STRING,str)
												self:CallChangeListeners(name,val)
											end
										end
									end
								end
							end
						end
					end
				else
					if(udmType == udm.TYPE_ARRAY) then
						local baseName = udmChild:GetValue("baseName",udm.TYPE_STRING)
						if(baseName == nil) then baseName = name:sub(1,1):upper() .. name:sub(2,#name -1) end
						local valueType = udmChild:GetValue("valueType",udm.TYPE_STRING)
						local schemaValueType = schema:FindTypeData(valueType,false)
						local udmValueType = udm.ascii_type_to_enum(valueType)
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
							if(valueType == "Any") then
								local setValueTypeName = "Set" .. (name:sub(1,1):upper() .. name:sub(2,#name)) .. "ValueType"
								if(setValueTypeName ~= nil) then
									class[setValueTypeName] = function(self,valueType)
										local udmValue = self:GetUdmData():Get(name)
										if(udmValue:IsValid() == false) then self:GetUdmData():AddArray(name,0,valueType)
										else self:GetUdmData():Get(name):SetValueType(valueType) end
									end
								end
							end
							local elementSetterName = "Set" .. baseName
							if(elementSetterName ~= nil) then
								class[elementSetterName] = function(self,i,value)
									self:GetUdmData():Get(name):SetValue(i,value)
								end
							end
						end

						local adderName = "Add" .. baseName
						if(adderName ~= nil) then
							class[adderName] = function(self,value)
								local el = self:GetUdmData():Get(name)
								el:Resize(el:GetSize() +1)
								if(schemaValueType ~= nil) then
									local child = el:Get(el:GetSize() -1)
									local prop,err = udm.create_property_from_schema(schema,valueType,self,child)
									table.insert(self:GetTypedChildren()[name],prop)
									return prop
								end
								el:SetValue(el:GetSize() -1,el:GetValueType(),value)
							end
						end

						local removerName = "Remove" .. baseName
						if(removerName ~= nil) then
							class[removerName] = function(self,idx)
								local a = self:GetUdmData():Get(name)
								if(idx >= a:GetSize()) then return end
								a:RemoveValue(idx)
								local children = self:GetTypedChildren()[name]
								children[idx +1]:OnRemove()
								table.remove(children,idx +1)
							end
						end
					end
					class[getterName] = function(self)
						return self:GetUdmData():GetValue(name,udmType)
					end
					local optional = udmChild:GetValue("optional",udm.TYPE_BOOLEAN) or false
					class[setterName] = function(self,value)
						if(optional and value == nil) then self:GetUdmData():RemoveValue(name)
						else self:GetUdmData():SetValue(name,udmType,value) end
						self:CallChangeListeners(name,value)
					end
				end
				-- TODO: Array
			end
		end
	end
	return true
end

local schema = udm.Schema.load("pfm.udm")
schema:SetLibrary(pfm.udm)

local res,err = udm.generate_lua_api_from_schema(schema,pfm.udm)
if(res ~= true) then
	console.print_warning(err)
	return
end
local session = udm.create_property_from_schema(schema,"Session")
session:GetSettings():GetRenderSettings():AddChangeListener("samples",function(rs,newSamples)
	print("New samples: ",newSamples)
end)
session:GetSettings():GetRenderSettings():SetSamples(12)
session:GetSettings():GetRenderSettings():SetPreviewQuality(2)
print("Preview quality: ",session:GetSettings():GetRenderSettings():GetPreviewQualityName())

local clip = session:AddClip()
local trackGroup = clip:AddTrackGroup()
local track = trackGroup:AddTrack()
local animClip = track:AddAnimationClip()
session:SetActiveClip(clip)

local scene = clip:GetScene()
local actor = scene:AddActor()
print(actor:GetUniqueId())

animClip:SetActor(actor)
print(animClip:GetActor())

local anim = animClip:GetAnimation()
anim:SetFlags(pfm.udm.ANIMATION_FLAGS_LOOP_BIT)

local channel = anim:AddChannel()
channel:SetValuesValueType(udm.TYPE_FLOAT)
channel:AddValue(5.0)
channel:AddValue(3.0)

channel:AddTime(3)
print("Flags: ",anim:GetFlags())

-- TODO: Asset
--print("ACTOR: ",animClip:GetActor())
--[[animClip:SetActor("uuid")
local anim = animClip:GetAnimation()
local channel = anim:AddChannel()
channel:SetTargetPath("ec/light/intensity")
channel:AddTime(5.0)]]

--session:AddClip()
--[[print(session:GetSettings():GetRenderSettings():GetUdmData())
print(session:AddClip())
session:RemoveClip(0)]]
--print(session:GetClip(session:GetActiveClip()):GetTimeFrame():GetScale())

local x = udm.create()
x:GetAssetData():GetData():SetValue("session",session:GetUdmData())--Merge(session:GetUdmData())
x:SaveAscii("test.udm")

session:Remove()

-- lua_exec_cl pfm/udm_schema.lua

