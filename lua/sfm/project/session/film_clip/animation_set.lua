--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("animation_set")

sfm.register_element_type("AnimationSet")
sfm.link_dmx_type("DmeAnimationSet",sfm.AnimationSet)

sfm.BaseElement.RegisterProperty(sfm.AnimationSet,"gameModel",sfm.GameModel,nil,sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)
sfm.BaseElement.RegisterProperty(sfm.AnimationSet,"camera",sfm.Camera,nil,sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)

function sfm.AnimationSet:Initialize()
	self.m_controls = {}
	self.m_transformControls = {}
end

function sfm.AnimationSet:Load(el)
	sfm.BaseElement.Load(self,el)
	
	local elControls = el:GetAttrV("controls")
	if(elControls ~= nil) then
		for _,attr in ipairs(elControls) do
			local elChild = attr:GetValue()
			if(elChild:GetType() == "DmeTransformControl") then
				table.insert(self.m_transformControls,self:LoadArrayValue(attr,sfm.TransformControl))
			else
				table.insert(self.m_controls,self:LoadArrayValue(attr,sfm.Control))
			end
		end
	end
end

function sfm.AnimationSet:GetControls() return self.m_controls end
function sfm.AnimationSet:GetTransformControls() return self.m_transformControls end
