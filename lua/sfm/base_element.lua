util.register_class("sfm.BaseElement")
sfm.BaseElement.class_data = {}
function sfm.BaseElement:__init(class)
	self.m_name = ""
	self.m_type = ""
	self.m_class = class
	
	local classData = sfm.BaseElement.class_data[class]
	if(classData == nil) then return end
	if(classData.attributes ~= nil) then
		for name,attrData in pairs(classData.attributes) do
			self["m_" .. name] = attrData[1]
		end
	end
	if(classData.properties ~= nil) then
		for name,propData in pairs(classData.properties) do
			self["m_" .. name] = propData[1]()
		end
	end
	if(classData.arrays ~= nil) then
		for name,arrayData in pairs(classData.arrays) do
			self["m_" .. name] = {}
		end
	end
end

function sfm.BaseElement.RegisterGetter(elClass,name,getterName)
	if(getterName == nil) then
		getterName = "Get" .. name:sub(1,1):upper() .. name:sub(2)
	end
	elClass[getterName] = function(el) return el["m_" .. name] end
end

function sfm.BaseElement.RegisterAttribute(elClass,name,default,getterName)
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].attributes = classData[elClass].attributes or {}
	
	classData[elClass].attributes[name] = {default}
	
	sfm.BaseElement.RegisterGetter(elClass,name,getterName)
end

function sfm.BaseElement.RegisterProperty(elClass,name,class,getterName)
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].properties = classData[elClass].properties or {}
	
	classData[elClass].properties[name] = {class}
	
	sfm.BaseElement.RegisterGetter(elClass,name,getterName)
end

function sfm.BaseElement.RegisterArray(elClass,name,class,getterName)
	local classData = sfm.BaseElement.class_data
	classData[elClass] = classData[elClass] or {}
	classData[elClass].arrays = classData[elClass].arrays or {}
	
	classData[elClass].arrays[name] = {class}
	
	sfm.BaseElement.RegisterGetter(elClass,name,getterName)
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
		end
	end
	if(classData.arrays ~= nil) then
		for name,arrayData in pairs(classData.arrays) do
			self["m_" .. name] = self:LoadArray(el,name,arrayData[1])
		end
	end
end

function sfm.BaseElement:GetName() return self.m_name end
function sfm.BaseElement:GetType() return self.m_type end

function sfm.BaseElement:LoadAttributeValue(el,name,default)
	return el:GetAttrV(name) or default
end

function sfm.BaseElement:LoadProperty(el,name,class)
  local elVal = el:GetAttributeValue(name)
	local o = class()
	if(elVal ~= nil) then o:Load(elVal) end
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
    table.insert(t,o)
  end
	return t
end
