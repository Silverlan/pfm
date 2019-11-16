--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.BaseElement")
sfm.BaseElement.class_data = {}
sfm.BaseElement.PROPERTY_FLAG_NONE = 0
sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL = 1
function sfm.BaseElement:__init(class)
	self.m_name = ""
	self.m_type = ""
	self.m_class = class
	self.m_parents = {}
	
	local classData = sfm.BaseElement.class_data[class]
	if(classData == nil) then return end
	if(classData.attributes ~= nil) then
		for name,attrData in pairs(classData.attributes) do
			self["m_" .. name] = attrData[1]
		end
	end
	if(classData.properties ~= nil) then
		local project = self:GetProject()
		for name,propData in pairs(classData.properties) do
			if(bit.band(propData[2],sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL) == 0 and propData[1] ~= nil) then
				self["m_" .. name] = project:CreateElement(propData[1],self)
			end
		end
	end
	if(classData.arrays ~= nil) then
		for name,arrayData in pairs(classData.arrays) do
			self["m_" .. name] = {}
		end
	end
end

function sfm.BaseElement:Initialize()
end

function sfm.BaseElement:AddParent(parent) table.insert(self.m_parents,parent) end
function sfm.BaseElement:GetParents() return self.m_parents end

function sfm.BaseElement:GetDMXElement()
	return self:GetProject():GetDMXElement(self)
end

function sfm.BaseElement.RegisterGetter(elClass,name,settings)
	local getterName
	if(settings ~= nil and settings.getterName ~= nil) then getterName = settings.getterName
	else getterName = "Get" .. name:sub(1,1):upper() .. name:sub(2) end
	elClass[getterName] = function(el) return el["m_" .. name] end
end

function sfm.BaseElement.RegisterSetter(elClass,name,settings)
	local setterName
	if(settings ~= nil and settings.setterName ~= nil) then setterName = settings.setterName
	else setterName = "Set" .. name:sub(1,1):upper() .. name:sub(2) end
	elClass[setterName] = function(el,value) el["m_" .. name] = value end
end

function sfm.BaseElement.RegisterAttribute(elClass,name,default,settings)
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].attributes = classData[elClass].attributes or {}
	
	classData[elClass].attributes[name] = {default}
	
	sfm.BaseElement.RegisterGetter(elClass,name,settings)
	sfm.BaseElement.RegisterSetter(elClass,name,settings)
end

function sfm.BaseElement.RegisterProperty(elClass,name,class,settings,flags)
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].properties = classData[elClass].properties or {}
	
	classData[elClass].properties[name] = {class,flags or 0} -- Note: class can be nil!
	
	sfm.BaseElement.RegisterGetter(elClass,name,settings)
	sfm.BaseElement.RegisterSetter(elClass,name,settings)
end

function sfm.BaseElement.RegisterArray(elClass,name,class,settings)
	if(class == nil) then
		console.print_warning("Attempted to register SFM array '" .. name .. "', but specified class does not exist!")
		return
	end
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].arrays = classData[elClass].arrays or {}
	
	classData[elClass].arrays[name] = {class}
	
	sfm.BaseElement.RegisterGetter(elClass,name,settings)
	sfm.BaseElement.RegisterSetter(elClass,name,settings)
end

function sfm.BaseElement:Load(el)
	self:GetProject():MapDMXElement(el,self)

	self.m_name = el:GetName()
	self.m_type = el:GetType()

	local classData = sfm.BaseElement.class_data[self.m_class]
	if(classData == nil) then return end
	if(classData.attributes ~= nil) then
		for name,attrData in pairs(classData.attributes) do
			local v = self:LoadAttributeValue(el,name)
			if(v ~= nil) then self["m_" .. name] = v
			else self["m_" .. name] = attrData[1] end
		end
	end
	if(classData.properties ~= nil) then
		local project = self:GetProject()
		for name,propData in pairs(classData.properties) do
			local class = propData[1]
			if(class == nil) then
				local elVal = el:GetAttributeValue(name)
				if(elVal ~= nil) then
					class = sfm.get_dmx_element_type(elVal:GetType())
				end
			end
			if(class ~= nil) then
				self["m_" .. name] = self:LoadProperty(el,name,class)
				if(bit.band(propData[2],sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL) == 0 and self["m_" .. name] == nil) then
					self["m_" .. name] = project:CreateElement(class,self)
				end
			end
		end
	end
	if(classData.arrays ~= nil) then
		for name,arrayData in pairs(classData.arrays) do
			self["m_" .. name] = self:LoadArray(el,name,arrayData[1])
		end
	end
end

function sfm.BaseElement:GetName() return self.m_name end
function sfm.BaseElement:SetName(name) self.m_name = name end
function sfm.BaseElement:GetType() return self.m_type end

function sfm.BaseElement:GetCachedElement(dmxEl,name) return self:GetProject():GetCachedElement(dmxEl,name) end
function sfm.BaseElement:CacheElement(dmxEl,el,name) self:GetProject():CacheElement(dmxEl,el,name) end
function sfm.BaseElement:CreatePropertyFromDMXElement(dmxEl,class,parent) return self:GetProject():CreatePropertyFromDMXElement(dmxEl,class,parent) end

function sfm.BaseElement:LoadAttributeValue(el,name,default)
	local elVal = el:GetAttrV(name)

	if(type(elVal) == "userdata") then
		local cachedElement = self:GetCachedElement(el,name)
		if(cachedElement ~= nil) then return cachedElement end
		self:CacheElement(el,elVal,name)
	end

	return elVal or default
end

function sfm.BaseElement:LoadProperty(el,name,class)
	local attr = el:GetAttribute(name)
	local elVal = el:GetAttributeValue(name)
	if(elVal == nil) then return end
	return self:CreatePropertyFromDMXElement(elVal,class,self)
end

function sfm.BaseElement:LoadArrayValue(attr,class)
	local elChild = attr:GetValue()
	local o
	if(type(elChild) == "userdata") then o = self:CreatePropertyFromDMXElement(elChild,class,self)
	else o = elChild end
	return o
end

function sfm.BaseElement:LoadArray(el,name,class)
	local t = {}
	local attr = el:GetAttrV(name)
	if(attr == nil) then return t end

	local project = self:GetProject()
	for _,attr in ipairs(attr) do
		table.insert(t,self:LoadArrayValue(attr,class))
	end
	return t
end

local g_registeredTypes = {}
sfm.register_element_type = function(name)
	if(sfm[name] ~= nil) then return end
	util.register_class("sfm." .. name,sfm.BaseElement)
	local class = sfm[name]
	function class:__init(project,...)
		if(util.get_type_name(project) ~= "Project") then
			error("Expected SFM project as argument for element of type '" .. name .. "', got " .. util.get_type_name(project) .. "!")
		end
		self.m_project = project

		sfm.BaseElement.__init(self,class)
		self:Initialize(...)
	end
	function class:GetProject() return self.m_project end
	g_registeredTypes[name] = class
end

local g_linkedTypes = {}
sfm.link_dmx_type = function(dmxType,elementType)
	g_linkedTypes[dmxType] = elementType
end

sfm.get_dmx_element_type = function(dmxType)
	return g_linkedTypes[dmxType]
end

sfm.get_type_data = function(name)
	return g_registeredTypes[name]
end

sfm.create_element = function(project,elType,...)
	return project:CreateElement(elType,...)
end
