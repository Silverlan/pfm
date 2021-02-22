--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm = fudm or {}

fudm.impl = fudm.impl or {}
fudm.impl.registered_types = fudm.impl.registered_types or {}
fudm.impl.class_to_type_id = fudm.impl.class_to_type_id or {}
fudm.impl.name_to_type_id = fudm.impl.name_to_type_id or {}
local registered_types = fudm.impl.registered_types
function fudm.register_type(className,baseClass,elementType,defaultArg,...)
	if(fudm[className] ~= nil) then return fudm.get_type_id(className) end
	if(type(baseClass) == "table") then util.register_class("fudm." .. className,unpack(baseClass))
	else util.register_class("fudm." .. className,baseClass) end
	local class = fudm[className]
	if(fudm.impl.class_to_type_id[class] ~= nil) then return fudm.impl.class_to_type_id[class] end

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
	fudm.impl.class_to_type_id[class] = typeId
	fudm.impl.name_to_type_id[className] = typeId
	return typeId
end

function fudm.impl.get_type_data(typeId) return registered_types[typeId] end

-- Special types
fudm.ELEMENT_TYPE_ANY = -1
fudm.ATTRIBUTE_TYPE_ANY = -2
function fudm.get_type_name(typeId)
	if(registered_types[typeId] == nil) then return end
	return registered_types[typeId].typeName
end

function fudm.get_type_id(typeName)
	return fudm.impl.class_to_type_id[typeName]
end

function fudm.register_attribute(className,defaultValue)
	return fudm.register_type(className,fudm.BaseAttribute,false,defaultValue)
end

function fudm.register_element(className,...)
	return fudm.register_type(className,fudm.BaseElement,true,...)
end

function fudm.register_element_property(elType,propIdentifier,defaultValue,settings)
	local elData = fudm.impl.registered_types[elType]
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
	local isElement = (defaultValue == fudm.ELEMENT_TYPE_ANY)
	if(defaultValue ~= fudm.ELEMENT_TYPE_ANY and defaultValue ~= fudm.ATTRIBUTE_TYPE_ANY) then
		local propertyData = fudm.impl.registered_types[defaultValue:GetType()]
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
			defaultValue = (defaultValue ~= fudm.ELEMENT_TYPE_ANY) and defaultValue or nil
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
			defaultValue = (defaultValue ~= fudm.ATTRIBUTE_TYPE_ANY) and defaultValue or nil
		}
	end
end

function fudm.create(typeIdentifier,arg,shouldBeElement) -- Note: 'shouldBeElement' is for internal purposes only!
	if(type(typeIdentifier) == "string") then
		typeIdentifier = fudm.get_type_id(typeIdentifier)
		if(typeIdentifier == nil) then return end
	end
	if(shouldBeElement == nil) then
		local elData = registered_types[typeIdentifier]
		return fudm.create(typeIdentifier,arg,elData and elData.isElement)
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

function fudm.load(ds)
	local typeName = ds:ReadString()
	local el = fudm.create(fudm.get_type_id(fudm[typeName]))
	el:LoadFromBinary(ds)
	return el
end

function fudm.save(ds,el)
	ds:WriteString(el:GetTypeName())
	el:SaveToBinary(ds)
end

include("udm_attribute.lua")
include("udm_element.lua")

include("attributes")
include("elements")
