util.register_class("sfm.BaseElement")
function sfm.BaseElement:__init()
	self.m_name = ""
end

function sfm.BaseElement:Load(el)
  self.m_name = el:GetName()
end

function sfm.BaseElement:GetName() return self.m_name end

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
    o:Load(elChild)
    table.insert(t,o)
  end
	return t
end
