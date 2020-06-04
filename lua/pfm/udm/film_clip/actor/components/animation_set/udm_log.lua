--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_log_list.lua")

udm.ELEMENT_TYPE_PFM_LOG = udm.register_element("PFMLog")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"useDefaultValue",udm.Bool(true),{
	getter = "ShouldUseDefaultValue"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"defaultValue",udm.ATTRIBUTE_TYPE_ANY)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"layers",udm.Array(udm.ELEMENT_TYPE_PFM_LOG_LIST))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"bookmarks",udm.Array(udm.ATTRIBUTE_TYPE_FLOAT))

function udm.PFMLog:AddLayer(layer)
	local logLayer = (type(layer) == "string") and self:CreateChild(udm.ELEMENT_TYPE_PFM_LOG_LIST,layer) or layer
	self:GetLayersAttr():PushBack(logLayer)
	return logLayer
end

function udm.PFMLog:SetPlaybackOffset(offset)
	-- TODO: I'm not sure why logs can even have multiple layers, I've yet to see a case where this actually applies.
	-- Maybe merge layers with the log?
	for _,layer in ipairs(self:GetLayers():GetTable()) do
		local value = layer:SetPlaybackOffset(offset)
		if(value ~= nil) then
			return value
		end
	end
	if(self:ShouldUseDefaultValue()) then return self:GetDefaultValue() end
end
