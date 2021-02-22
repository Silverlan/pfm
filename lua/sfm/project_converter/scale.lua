--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function find_scale_channels(channels)
	local scaleChannels = {}
	for _,channel in ipairs(channels) do
		if(channel:GetToAttribute() == "scale") then
			scaleChannels[channel] = true
			local fromElement = channel:GetFromElement()
			for _,channelOther in ipairs(channels) do
				local toElement = channelOther:GetToElement()
				if(util.is_same_object(fromElement,toElement)) then
					scaleChannels[channelOther] = true
				end
			end
		end
	end

	local scaleChannelList = {}
	for channel in pairs(scaleChannels) do table.insert(scaleChannelList,channel) end
	return scaleChannelList
end

local function search_and_replace(curEl,searchAndReplaceTable,traversed)
	-- Replace all instances of the search-element in the tree with the replace element
	traversed = traversed or {}
	if(traversed[curEl] ~= nil or curEl:IsElement() == false) then return end
	traversed[curEl] = true
	local children = curEl:GetChildren()
	for name,child in pairs(curEl:GetChildren()) do
		if(searchAndReplaceTable[child] ~= nil) then
			local replace = searchAndReplaceTable[child]
			curEl:RemoveChild(name)
			curEl:AddChild(replace,name)
		end
	end

	for name,child in pairs(curEl:GetChildren()) do
		search_and_replace(child,searchAndReplaceTable,traversed)
	end
end

sfm.convert_scale_factors_to_vectors = function(project)
	local root = project:GetUDMRootNode()
	local channels = {}
	root:FindElementsByType(fudm.ELEMENT_TYPE_PFM_CHANNEL,channels)

	local scaleChannels = find_scale_channels(channels)
	local modifiedElements = {}
	local searchAndReplaceTable = {}
	local function sfm_to_pfm_scale_expression_operator(op)
		if(modifiedElements[op] ~= nil) then return end
		modifiedElements[op] = true

		local attrs = {"value","lo","hi","result"}
		for _,attr in ipairs(attrs) do
			local prop = op:GetProperty(attr)
			if(prop ~= nil) then
				local value = prop:GetValue()
				local newProp = fudm.Vector3(Vector(value,value,value))
				searchAndReplaceTable[prop] = newProp
			end
		end
	end
	for _,channel in ipairs(scaleChannels) do
		local log = channel:GetLog()
		for _,layer in ipairs(log:GetLayers():GetTable()) do
			local values = layer:GetValues()
			values:Clear()
			values:SetValueType(util.VAR_TYPE_VECTOR)

			for i=1,#values do
				local val = values:Get(i)
				values:PushBack(Vector(val,val,val))
			end
		end

		local fromElement = channel:GetFromElement()
		if(fromElement ~= nil and fromElement:GetType() == fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR) then sfm_to_pfm_scale_expression_operator(fromElement) end

		local toElement = channel:GetToElement()
		if(toElement ~= nil and toElement:GetType() == fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR) then sfm_to_pfm_scale_expression_operator(toElement) end

		local defaultValueAttr = log:GetDefaultValueAttr()
		if(defaultValueAttr ~= nil) then
			local defaultValue = defaultValueAttr:GetValue()
			local newDefaultValueAttr = fudm.Vector3(Vector(defaultValue,defaultValue,defaultValue))
			searchAndReplaceTable[defaultValueAttr] = newDefaultValueAttr
		end
	end
	search_and_replace(root,searchAndReplaceTable)
end
