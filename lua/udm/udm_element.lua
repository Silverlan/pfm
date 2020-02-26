--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.BaseElement",udm.BaseItem)
function udm.BaseElement:__init(class)
	udm.BaseItem.__init(self)
	self:ChangeName("")
	self.m_class = class
	self.m_children = {}
	self.m_attributes = {}
	
	local type = self:GetType()
	local elData = udm.impl.get_type_data(type)
	if(elData == nil) then
		console.print_warning("Attempted to use unregistered element type " .. type .. " for UDM element '" .. self:GetName() .. "'!")
		return
	end
	for identifier,prop in pairs(elData.properties) do
		if(prop.defaultValue ~= nil) then
			local val = prop.defaultValue:Copy()
			self:SetProperty(identifier,val)
		end
	end
end

function udm.BaseElement:DebugPrint(t,cache)
	cache = cache or {}
	if(cache[self] ~= nil) then return end
	cache[self] = true
	t = t or ""
	for name,child in pairs(self:GetChildren()) do
		if(name:sub(1,1) == '[' and name:sub(-1) == ']') then
			local val = tonumber(name:sub(2,#name -2))
			if(val ~= nil) then
				if(val > 5) then return end
				if(val == 5) then name = "[...]" end
			end
		end
		if(child:IsElement()) then
			print(t .. "[" .. name .. "]: " .. child:GetName() .. " of type " .. child:GetTypeName())
		else
			print(t .. "[" .. name .. "]: " .. tostring(child:GetValue()) .. " of type " .. child:GetTypeName())
		end
		if(child:IsElement()) then
			child:DebugPrint(t .. "\t")
		end
	end
end

function udm.BaseElement:DebugDump(f,t,name)
	t = t or ""
	f:WriteString(t)
	if(name) then f:WriteString("[" .. name .. "] = ") end
	f:WriteString(tostring(self) .. "\n")
	for name,child in pairs(self:GetChildren()) do
		child:DebugDump(f,t .. "\t",name)
	end
end

function udm.BaseElement:IterateTree(callback,iterated)
	iterated = iterated or {}
	for keyName,child in pairs(self:GetChildren()) do
		if(iterated[child] == nil) then
			iterated[child] = true -- Prevent infinite recursion
			callback(keyName,child)
			if(child:IsElement()) then
				child:IterateTree(callback,iterated)
			end
		end
	end
end

function udm.BaseElement:FindElementsByFilter(filter,elements,iterated)
	elements = elements or {}
	self:IterateTree(function(keyName,child)
		if(filter(keyName,child)) then table.insert(elements,child) end
	end)
	return elements
end

function udm.BaseElement:FindElementsByKey(name,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return keyName == name end,elements,iterated)
end

function udm.BaseElement:FindElementsByName(name,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return child:IsElement() and child:GetName() == name end,elements,iterated)
end

function udm.BaseElement:FindElementsByType(type,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return child:GetType() == type end,elements,iterated)
end

-- Returns the first parent element that isn't a reference. If the parent is an array, the parent
-- of that array will be returned.
function udm.BaseElement:FindParentElement()
	for _,elParent in ipairs(self:GetParents()) do
		local type = elParent:GetType()
		if(type ~= udm.ELEMENT_TYPE_REFERENCE) then -- A reference means that this isn't our actual parent
			if(type == udm.ELEMENT_TYPE_ARRAY) then
				-- We don't care about arrays, so we'll skip them and go for their parent instead.
				return elParent:FindParentElement()
			end
			return elParent
		end
	end
end

function udm.BaseElement:SetProperty(name,prop)
	if(prop:IsElement()) then prop:ChangeName(name) end
	self:AddChild(prop,name)
	return self:GetProperty(name)
end
function udm.BaseElement:GetProperty(name)
	local property = self:GetChild(name)
	if(property ~= nil and property:GetType() == udm.ELEMENT_TYPE_REFERENCE) then
		return property:GetTarget()
	end
	return property
end

function udm.BaseElement:ChangeName(name) self.m_name = name end
function udm.BaseElement:GetName() return self.m_name end

function udm.BaseElement:GetChild(name) return self.m_children[name] end

function udm.BaseElement:GetChildren() return self.m_children end
function udm.BaseElement:GetAttributes() return self.m_attributes end

function udm.BaseElement:CreateChild(type,name)
	local el = udm.create_element(type,name)
	if(el == nil) then return end
	self:AddChild(el,name)
	return el
end

function udm.BaseElement:CreateAttribute(type,name)
	local attr = udm.create_attribute(type,name)
	if(attr == nil) then return end
	self:AddAttribute(attr,name)
	return attr
end

function udm.BaseElement:CreateAttributeArray(type,name)
	local attr = udm.create_attribute_array(type,name)
	if(attr == nil) then return end
	self:AddAttribute(attr,name)
	return attr
end

function udm.BaseElement:IsElement() return true end
function udm.BaseElement:IsAttribute() return false end

function udm.BaseElement:AddChild(element,name)
	name = name or element:GetName()
	self:RemoveChild(name)
	self.m_children[name] = element
	if(element == nil) then return end
	table.insert(element.m_parents,self)
	return element
end

function udm.BaseElement:RemoveChild(name)
	if(type(name) ~= "string") then name = name:GetName() end
	local child = self.m_children[name]
	if(child == nil) then return end
	self.m_children[name] = nil
	for i,p in ipairs(child.m_parents) do
		if(util.is_same_object(p,self)) then
			table.remove(child.m_parents,i)
			break
		end
	end
end

function udm.BaseElement:AddAttribute(attr,name)
	self.m_attributes[name] = attr
	return attr
end

function udm.BaseElement:RemoveAttribute(name)
	self.m_attributes[name] = nil
end

function udm.BaseElement:GetType() return -1 end

function udm.BaseElement:Copy()
	local copy = self.m_class(self:GetName())
	
	local type = self:GetType()
	local elData = udm.impl.get_type_data(type)
	if(elData == nil) then return copy end
	for name,prop in pairs(elData.properties) do
		if(prop.getterAttribute(self) == nil) then
			-- pfm.error("Property '" .. name .. "' of type '" .. util.get_type_name(prop) .. "' is invalid!") -- TODO: Should this be a warning?
			prop.setterAttribute(copy,nil)
		else
			prop.setterAttribute(copy,prop.getterAttribute(self):Copy())
		end
	end
	return copy
end

function udm.BaseElement:SaveToBinary(ds)
	ds:WriteString(self:GetName())
	
	local type = self:GetType()
	local elData = udm.impl.get_type_data(type)
	if(elData == nil) then return end
	for _,prop in pairs(elData.properties) do
		prop.getter(self):SaveToBinary(ds)
	end
end
function udm.BaseElement:LoadFromBinary(ds)
	self:ChangeName(ds:ReadString())
	
	local type = self:GetType()
	local elData = udm.impl.get_type_data(type)
	if(elData == nil) then return end
	for _,prop in pairs(elData.properties) do
		prop.getter(self):LoadFromBinary(ds)
	end
end

function udm.create_element(type,name)
	return udm.create(type,name,true)
end
