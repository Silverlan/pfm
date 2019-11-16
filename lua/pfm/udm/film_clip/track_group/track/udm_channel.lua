--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/actor/components/animation_set/udm_log.lua")

udm.ELEMENT_TYPE_PFM_CHANNEL = udm.register_element("PFMChannel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"log",udm.PFMLog())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"toAttribute",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"toElement",udm.ELEMENT_TYPE_ANY)

function udm.PFMChannel:SetPlaybackOffset(offset)
	local toElement = self:GetToElement()
	if(toElement == nil) then return end
	local toAttribute = self:GetToAttribute()
	local el = toElement:GetChild(toAttribute)
	if(el ~= nil) then
		local log = self:GetLog()
		local value = log:SetPlaybackOffset(offset)
		if(value ~= nil) then
			local property = toElement:GetProperty(toAttribute)
			if(property ~= nil) then
				-- print("Channel '" .. self:GetName() .. "': Changing value of attribute " .. toAttribute .. " of element " .. toElement:GetName() .. " (" .. toElement:GetTypeName() .. ") to " .. tostring(value))
				property:SetValue(value)
			end
		end
	else
		-- pfm.log("Invalid to-attribute '" .. toAttribute .. "' of element '" .. toElement:GetName() .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
	end
end
