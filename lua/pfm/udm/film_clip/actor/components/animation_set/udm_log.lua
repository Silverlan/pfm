--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_log_list.lua")

fudm.ELEMENT_TYPE_PFM_LOG = fudm.register_element("PFMLog")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_LOG,"useDefaultValue",fudm.Bool(true),{
	getter = "ShouldUseDefaultValue"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_LOG,"defaultValue",fudm.ATTRIBUTE_TYPE_ANY)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_LOG,"layers",fudm.Array(fudm.ELEMENT_TYPE_PFM_LOG_LIST))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_LOG,"bookmarks",fudm.Array(fudm.ATTRIBUTE_TYPE_FLOAT))

function fudm.PFMLog:AddLayer(layer)
	local logLayer = (type(layer) == "string") and self:CreateChild(fudm.ELEMENT_TYPE_PFM_LOG_LIST,layer) or layer
	self:GetLayersAttr():PushBack(logLayer)
	return logLayer
end

function fudm.PFMLog:SetPlaybackOffset(offset)
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
