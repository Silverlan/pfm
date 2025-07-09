-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("transform.lua")

sfm.register_element_type("Dag")
sfm.link_dmx_type("DmeDag", sfm.Dag)

sfm.BaseElement.RegisterProperty(sfm.Dag, "transform", sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.Dag, "overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.Dag, "overridePos")
sfm.BaseElement.RegisterAttribute(sfm.Dag, "overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.Dag, "visible", false, {
	getterName = "IsVisible",
})

function sfm.Dag:Initialize()
	self.m_children = {}
end

function sfm.Dag:Load(el)
	sfm.BaseElement.Load(self, el)

	for _, value in ipairs(el:GetAttrV("children") or {}) do
		local child = value:GetValue()
		if child == nil then
			pfm.log(
				"Dag '" .. self:GetName() .. "' has invalid child reference! Ignoring...",
				pfm.LOG_CATEGORY_SFM,
				pfm.LOG_SEVERITY_WARNING
			)
		else
			local dmxType = child:GetType()
			local sfmType = sfm.get_dmx_element_type(dmxType)
			if sfmType ~= nil then
				local el = self:CreatePropertyFromDMXElement(child, sfmType, self)
				table.insert(self.m_children, el)
			else
				pfm.log(
					"Unsupported DMX type '"
						.. dmxType
						.. "' ('"
						.. child:GetName()
						.. "') of element '"
						.. self:GetName()
						.. "'!",
					pfm.LOG_CATEGORY_SFM,
					pfm.LOG_SEVERITY_WARNING
				)
			end
		end
	end
end

function sfm.Dag:GetChildren()
	return self.m_children
end
