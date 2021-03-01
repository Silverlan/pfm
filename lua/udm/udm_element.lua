--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("fudm.BaseElement",fudm.BaseItem)
function fudm.BaseElement:__init(class)
	fudm.BaseItem.__init(self)
	self.m_class = class
	self.m_children = {}
	self.m_attributes = {}
	self:SetProperty("name",fudm.String(""))
	
	local type = self:GetType()
	local elData = fudm.impl.get_type_data(type)
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

function fudm.BaseElement:DebugPrint(t,cache)
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

function fudm.BaseElement:DebugDump(f,t,name)
	t = t or ""
	f:WriteString(t)
	if(name) then f:WriteString("[" .. name .. "] = ") end
	f:WriteString(tostring(self) .. "\n")
	for name,child in pairs(self:GetChildren()) do
		child:DebugDump(f,t .. "\t",name)
	end
end

function fudm.BaseElement:IterateTree(callback,iterated)
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

function fudm.BaseElement:FindElementsByFilter(filter,elements,iterated)
	elements = elements or {}
	self:IterateTree(function(keyName,child)
		if(filter(keyName,child)) then table.insert(elements,child) end
	end)
	return elements
end

function fudm.BaseElement:FindElementsByKey(name,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return keyName == name end,elements,iterated)
end

function fudm.BaseElement:FindElementsByName(name,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return child:IsElement() and child:GetName() == name end,elements,iterated)
end

function fudm.BaseElement:FindElementsByType(type,elements,iterated)
	return self:FindElementsByFilter(function(keyName,child) return child:GetType() == type end,elements,iterated)
end

-- Returns the first parent element that isn't a reference. If the parent is an array, the parent
-- of that array will be returned.
function fudm.BaseElement:FindParentElement(filter)
	for _,elParent in ipairs(self:GetParents()) do
		local type = elParent:GetType()
		if(type ~= fudm.ELEMENT_TYPE_REFERENCE) then -- A reference means that this isn't our actual parent
			if(type == fudm.ELEMENT_TYPE_ARRAY) then
				-- We don't care about arrays, so we'll skip them and go for their parent instead.
				elParent = elParent:FindParentElement(filter)
			end
			if(elParent ~= nil and (filter == nil or filter(elParent) == true)) then return elParent end
		end
	end
end

function fudm.BaseElement:SetProperty(name,prop)
	-- if(prop:IsElement()) then prop:ChangeName(name) end
	self:AddChild(prop,name)
	return self:GetProperty(name)
end
function fudm.BaseElement:GetProperty(name)
	local property = self:GetChild(name)
	if(property ~= nil and property:GetType() == fudm.ELEMENT_TYPE_REFERENCE) then
		return property:GetTarget()
	end
	return property
end

function fudm.BaseElement:ChangeName(name) self:GetProperty("name"):SetValue(name) end
function fudm.BaseElement:GetName() return self:GetProperty("name"):GetValue() end

function fudm.BaseElement:GetChild(name) return self.m_children[name] end

function fudm.BaseElement:GetChildren() return self.m_children end
function fudm.BaseElement:GetAttributes() return self.m_attributes end

function fudm.BaseElement:CreateChild(type,name)
	local el = fudm.create_element(type,name)
	if(el == nil) then return end
	self:AddChild(el,name)
	return el
end

function fudm.BaseElement:CreateAttribute(type,name)
	local attr = fudm.create_attribute(type,name)
	if(attr == nil) then return end
	self:AddAttribute(attr,name)
	return attr
end

function fudm.BaseElement:CreateAttributeArray(type,name)
	local attr = fudm.create_attribute_array(type,name)
	if(attr == nil) then return end
	self:AddAttribute(attr,name)
	return attr
end

function fudm.BaseElement:IsElement() return true end
function fudm.BaseElement:IsAttribute() return false end

function fudm.BaseElement:AddChild(element,name)
	name = name or element:GetName()
	self:RemoveChild(name)
	self.m_children[name] = element
	if(element == nil) then return end
	table.insert(element.m_parents,self)
	return element
end

function fudm.BaseElement:RemoveChild(name)
	if(type(name) ~= "string" and type(name) ~= "number") then name = name:GetName() end
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

function fudm.BaseElement:AddAttribute(attr,name)
	self.m_attributes[name] = attr
	return attr
end

function fudm.BaseElement:RemoveAttribute(name)
	self.m_attributes[name] = nil
end

function fudm.BaseElement:GetType() return -1 end

function fudm.BaseElement:Copy()
	local copy = self.m_class(self:GetName())
	
	local type = self:GetType()
	local elData = fudm.impl.get_type_data(type)
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

function fudm.BaseElement:SaveToBinary(ds)
	self:WriteToBinary(ds)
end
function fudm.BaseElement:LoadFromBinary(ds)
	self:ReadFromBinary(ds)
end

function fudm.BaseElement:OnLoaded() end

function fudm.create_element(type,name)
	return fudm.create(type,name,true)
end
