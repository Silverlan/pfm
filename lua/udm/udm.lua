--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm = udm or {}

udm.impl = udm.impl or {}
udm.impl.registered_types = udm.impl.registered_types or {}
udm.impl.class_to_type_id = udm.impl.class_to_type_id or {}
udm.impl.name_to_type_id = udm.impl.name_to_type_id or {}
local registered_types = udm.impl.registered_types
function udm.register_type(className,baseClass,elementType,defaultArg,...)
	if(udm[className] ~= nil) then return udm.get_type_id(className) end
	if(type(baseClass) == "table") then util.register_class("udm." .. className,unpack(baseClass))
	else util.register_class("udm." .. className,baseClass) end
	local class = udm[className]
	if(udm.impl.class_to_type_id[class] ~= nil) then return udm.impl.class_to_type_id[class] end

	-- Note: Attributes take an optional value as argument, elements can have variadic arguments depending on the type,
	-- which are redirected to the element's Initialize method.
	if(elementType) then
		local defaultArgs = {defaultArg,...}
		defaultArg = nil

		function class:__init(...)
			if(type(baseClass) == "table") then for _,p in ipairs(baseClass) do p.__init(self,class) end
			else baseClass.__init(self,class) end

			local initArgs = {}
			local userArgs = {...}
			for i=1,math.max(#defaultArgs,#userArgs) do
				if(userArgs[i] ~= nil) then initArgs[i] = userArgs[i]
				else initArgs[i] = defaultArgs[i] end
			end
			class.Initialize(self,unpack(initArgs))
		end
	else
		function class:__init(value)
			baseClass.__init(self,class,value or defaultArg)
			class.Initialize(self)
		end
	end

	if(elementType) then
		function class:__tostring()
			return "UDMElement[" .. className .. "][" .. self:GetName() .. "]"
		end
	else
		function class:__tostring()
			return "UDMAttribute[" .. className .. "][" .. tostring(self:GetValue()) .. "]"
		end
	end
	
	local typeId = #registered_types +1
	function class:GetType()
		return typeId
	end
	
	registered_types[typeId] = {
		class = class,
		typeName = className,
		isElement = elementType
	}
	if(elementType) then registered_types[typeId].properties = {} end
	udm.impl.class_to_type_id[class] = typeId
	udm.impl.name_to_type_id[className] = typeId
	return typeId
end

function udm.impl.get_type_data(typeId) return registered_types[typeId] end

-- Special types
udm.ELEMENT_TYPE_ANY = -1
udm.ATTRIBUTE_TYPE_ANY = -2
function udm.get_type_name(typeId)
	if(registered_types[typeId] == nil) then return end
	return registered_types[typeId].typeName
end

function udm.get_type_id(typeName)
	return udm.impl.class_to_type_id[typeName]
end

function udm.register_attribute(className,defaultValue)
	return udm.register_type(className,udm.BaseAttribute,false,defaultValue)
end

function udm.register_element(className,...)
	return udm.register_type(className,udm.BaseElement,true,...)
end

function udm.register_element_property(elType,propIdentifier,defaultValue,settings)
	local elData = udm.impl.registered_types[elType]
	if(elData == nil or elData.isElement == false) then
		console.print_warning("Attempted to register property '" .. propIdentifier .. "' with element of type '" .. elType .. "', which is not a valid UDM element type!")
		return
	end
	settings = settings or {}
	local methodIdentifier = propIdentifier:sub(1,1):upper() .. propIdentifier:sub(2)
	local baseGetterName = "Get" .. methodIdentifier
	local getterName = settings.getter or baseGetterName
	local setterName = settings.setter or ("Set" .. methodIdentifier)

	-- Depending on whether or not the property is an element or an attribute, we'll handle the getter/setter functions differently
	local isElement = (defaultValue == udm.ELEMENT_TYPE_ANY)
	if(defaultValue ~= udm.ELEMENT_TYPE_ANY and defaultValue ~= udm.ATTRIBUTE_TYPE_ANY) then
		local propertyData = udm.impl.registered_types[defaultValue:GetType()]
		isElement = propertyData.isElement
	end

	if(isElement) then
		elData.class[getterName] = function(self) return self:GetProperty(propIdentifier) end
		elData.class[baseGetterName .. "Attribute"] = elData.class[getterName]
		elData.class[baseGetterName .. "Attr"] = elData.class[getterName]
		elData.class[setterName] = function(self,value) self:AddChild(value,propIdentifier) end
		elData.class[setterName .. "Attribute"] = elData.class[setterName]
		elData.class[setterName .. "Attr"] = elData.class[setterName]

		elData.properties[propIdentifier] = {
			getter = elData.class[getterName],
			getterAttribute = elData.class[getterName],
			setter = elData.class[setterName],
			setterAttribute = elData.class[setterName],
			defaultValue = (defaultValue ~= udm.ELEMENT_TYPE_ANY) and defaultValue or nil
		}
	else
		-- When calling the getter-function, the caller most likely wants the underlying value instead of the attribute
		elData.class[getterName] = function(self) return self:GetProperty(propIdentifier):GetValue() end
		elData.class[setterName] = function(self,value) self:GetProperty(propIdentifier):SetValue(value) end

		-- We'll register an additional getter in case they do want to get the attribute instead of the underlying value
		local getterNameAttribute = baseGetterName .. "Attribute"
		elData.class[getterNameAttribute] = function(self) return self:GetProperty(propIdentifier) end
		-- Shorthand alias
		elData.class[baseGetterName .. "Attr"] = function(self) return self[getterNameAttribute](self) end

		local setterNameAttribute = setterName .. "Attribute"
		elData.class[setterNameAttribute] = function(self,value) self:AddChild(value,propIdentifier) end
		elData.class[setterName .. "Attr"] = elData.class[setterNameAttribute]

		elData.properties[propIdentifier] = {
			getter = elData.class[getterName],
			getterAttribute = elData.class[getterNameAttribute],
			setter = elData.class[setterName],
			setterAttribute = elData.class[setterNameAttribute],
			defaultValue = (defaultValue ~= udm.ATTRIBUTE_TYPE_ANY) and defaultValue or nil
		}
	end
end

function udm.create(typeIdentifier,arg,shouldBeElement) -- Note: 'shouldBeElement' is for internal purposes only!
	if(type(typeIdentifier) == "string") then
		typeIdentifier = udm.get_type_id(typeIdentifier)
		if(typeIdentifier == nil) then return end
	end
	if(shouldBeElement == nil) then
		local elData = registered_types[typeIdentifier]
		return udm.create(typeIdentifier,arg,elData and elData.isElement)
	end
	local elData = registered_types[typeIdentifier]
	if(elData == nil or elData.isElement ~= shouldBeElement) then
		local expectedType = shouldBeElement and "element" or "attribute"
		local msg = "Attempted to create UDM " .. expectedType .. " of type " .. typeIdentifier
		if(elData ~= nil) then msg = msg .. " ('" .. elData.typeName .. "')" end
		console.print_warning(msg .. ", which is not a valid UDM " .. expectedType .. " type!")
		return
	end
	return elData.class(arg)
end

function udm.load(ds)
	local typeName = ds:ReadString()
	local el = udm.create(udm.get_type_id(udm[typeName]))
	el:LoadFromBinary(ds)
	return el
end

function udm.save(ds,el)
	ds:WriteString(el:GetTypeName())
	el:SaveToBinary(ds)
end

include("udm_attribute.lua")
include("udm_element.lua")

include("attributes")
include("elements")
