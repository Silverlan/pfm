--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/actor/components/animation_set/udm_log.lua")
include("/pfm/udm/film_clip/actor/components/animation_set/udm_graph_curve.lua")
udm.ELEMENT_TYPE_PFM_CHANNEL = udm.register_element("PFMChannel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"log",udm.PFMLog())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"fromAttribute",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"fromElement",udm.ELEMENT_TYPE_ANY)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"toAttribute",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"toElement",udm.ELEMENT_TYPE_ANY)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL,"graphCurve",udm.PFMGraphCurve())

function udm.PFMChannel:SetPlaybackOffset(offset)
	-- Note: This function will grab the appropriate value from the log
	-- and assign it to the 'toElement'. If no log values exist, the
	-- 'fromAttribute' value of the 'fromElement' element will be used instead.

	local toElement = self:GetToElement()
	if(toElement == nil) then return end
	local toAttribute = self:GetToAttribute()
	local el = toElement:GetChild(toAttribute)
	if(el ~= nil) then
		local log = self:GetLog()
		local value = log:SetPlaybackOffset(offset)
		local property = toElement:GetProperty(toAttribute)
		if(property ~= nil) then
			if(value ~= nil) then
				-- print("Channel '" .. self:GetName() .. "': Changing value of attribute " .. toAttribute .. " of element " .. toElement:GetName() .. " (" .. toElement:GetTypeName() .. ") to " .. tostring(value))
				property:SetValue(value)
				-- TODO: Also set 'time' property of toElement if it exists? (e.g. for expression operator)
			else
				local fromElement = self:GetFromElement()
				local fromProperty = (fromElement ~= nil) and fromElement:GetProperty(self:GetFromAttribute()) or nil
				if(fromProperty ~= nil) then
					property:SetValue(fromProperty:GetValue())
				end
			end
		end
	else
		-- pfm.log("Invalid to-attribute '" .. toAttribute .. "' of element '" .. toElement:GetName() .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
	end
end
