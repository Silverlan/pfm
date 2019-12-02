--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("transform.lua")

sfm.register_element_type("Dag")
sfm.link_dmx_type("DmeDag",sfm.Dag)

sfm.BaseElement.RegisterProperty(sfm.Dag,"transform",sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.Dag,"overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.Dag,"overridePos")
sfm.BaseElement.RegisterAttribute(sfm.Dag,"overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.Dag,"visible",false,{
	getterName = "IsVisible"
})

function sfm.Dag:Initialize()
	self.m_children = {}
end

function sfm.Dag:Load(el)
	sfm.BaseElement.Load(self,el)
	
	for _,value in ipairs(el:GetAttrV("children") or {}) do
		local child = value:GetValue()
		local dmxType = child:GetType()
		local sfmType = sfm.get_dmx_element_type(dmxType)
		if(sfmType ~= nil) then
			local el = self:CreatePropertyFromDMXElement(child,sfmType,self)
			table.insert(self.m_children,el)
		else
			pfm.log("Unsupported DMX type '" .. dmxType .. "' ('" .. child:GetName() .. "') of element '" .. self:GetName() .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		end
	end
end

function sfm.Dag:GetChildren() return self.m_children end
