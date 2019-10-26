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
	self.m_cachedProperties = {}
	
	local classData = sfm.BaseElement.class_data[class]
	if(classData == nil) then return end
	if(classData.attributes ~= nil) then
		for name,attrData in pairs(classData.attributes) do
			self["m_" .. name] = attrData[1]
		end
	end
	if(classData.properties ~= nil) then
		for name,propData in pairs(classData.properties) do
			if(bit.band(propData[2],sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL) == 0) then
				self["m_" .. name] = propData[1]()
			end
		end
	end
	if(classData.arrays ~= nil) then
		for name,arrayData in pairs(classData.arrays) do
			self["m_" .. name] = {}
		end
	end
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
	if(class == nil) then
		console.print_warning("Attempted to register SFM property '" .. name .. "', but specified class does not exist!")
		return
	end
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].properties = classData[elClass].properties or {}
	
	classData[elClass].properties[name] = {class,flags or 0}
	
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
  self.m_name = el:GetName()
  self.m_type = el:GetType()

  local classData = sfm.BaseElement.class_data[self.m_class]
  if(classData == nil) then return end
  if(classData.attributes ~= nil) then
    for name,attrData in pairs(classData.attributes) do
      local v = el:GetAttrV(name)
      if(v ~= nil) then self["m_" .. name] = v
      else self["m_" .. name] = attrData[1] end
    end
  end
  if(classData.properties ~= nil) then
    for name,propData in pairs(classData.properties) do
      self["m_" .. name] = self:LoadProperty(el,name,propData[1])
      if(bit.band(propData[2],sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL) == 0 and self["m_" .. name] == nil) then
        self["m_" .. name] = propData[1]()
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

function sfm.BaseElement:LoadAttributeValue(el,name,default)
	return el:GetAttrV(name) or default
end

function sfm.BaseElement:LoadProperty(el,name,class)
	local attr = el:GetAttribute(name)
	local elVal = el:GetAttributeValue(name)
	if(elVal == nil) then return end
	local cacheId
	if(util.get_type_name(elVal) == "Element") then
		local guid = elVal:GetGUID()
		if(self.m_cachedProperties[guid] ~= nil) then return self.m_cachedProperties[guid] end
		cacheId = guid
	end

	local o = class()
	o:Load(elVal)
	if(cacheId ~= nil) then self.m_cachedProperties[cacheId] = o end
	return o
end

function sfm.BaseElement:LoadArray(el,name,class)
	local t = {}
	local attr = el:GetAttrV(name)
	if(attr == nil) then return t end
	for _,attr in ipairs(attr) do
		local elChild = attr:GetValue()
		local o = class()
		if(type(o) == "userdata") then o:Load(elChild) end
		if(cacheId ~= nil) then self.m_cachedProperties[cacheId] = o end
		table.insert(t,o)
	end
	return t
end
