--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_model.lua")

fudm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR = fudm.register_element("PFMGlobalFlexControllerOperator")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR,"flexWeight",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR,"gameModel",fudm.PFMModel())

function fudm.PFMGlobalFlexControllerOperator:Initialize()
	local property = self:GetFlexWeightAttr()
	property:AddChangeListener(function(newValue)
		-- Inform the flex weight of the game model of the new value
		local mdlFlexWeight = self:FindModelFlexWeight()
		if(mdlFlexWeight == nil) then return end
		mdlFlexWeight:SetValue(newValue)
	end)
end

function fudm.PFMGlobalFlexControllerOperator:FindModelFlexWeight()
	local fcName = self:GetName()
	if(#fcName == 0) then return end
	local gameModel = self:GetGameModel()
	local fcNames = gameModel:GetFlexControllerNames():GetTable()
	-- We need to find the flex controller index inside the model,
	-- however since that requires iterating the entire array of flex controllers,
	-- we cache the index to speed up the lookup next time.
	local index
	if(self.m_lastModelLookupIndex ~= nil) then
		index = self.m_lastModelLookupIndex
		if(fcNames[index] == nil or fcNames[index]:GetValue() ~= fcName) then index = nil end -- Make sure the index is still correct
	end

	if(index == nil) then
		-- No valid cached index, do a normal lookup (slow)
		for i,name in ipairs(fcNames) do
			if(name:GetValue() == fcName) then
				index = i
				break
			end
		end
	end
	self.m_lastModelLookupIndex = index

	if(index == nil) then return end
	return gameModel:GetFlexWeights():Get(index)
end
