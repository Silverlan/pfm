--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR = fudm.register_element("PFMExpressionOperator")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR,"result",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR,"expression",fudm.String(""))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_EXPRESSION_OPERATOR,"value",fudm.Float(0.0)) -- TODO: Can by Vector as well!

function fudm.PFMExpressionOperator:Initialize()
	local propValue = self:GetProperty("value")
	propValue:AddChangeListener(function(newValue)
		self:UpdateResult()
	end)
end

function fudm.PFMExpressionOperator:CalcResult()
	local expression = self:GetExpression()
	local f,err = loadstring("return function(self) return " .. expression .. " end")
	if(f == nil) then
		console.print_warning("Unable to evaluate math expression '" .. expression .. "': ",err)
		return
	end
	f = f()
	local status,res = pcall(f,self)
	if(status == false) then
		console.print_warning("Unable to run math expression '" .. expression .. "': ",res)
		return
	end
	if(type(res) ~= "number") then
		console.print_warning("Expected math expression '" .. expression .. "' to return a number, " .. type(res) .. " was returned instead!")
		return
	end
	if(self:GetName() == "focalDistance_rescale") then
		-- TODO: For testing purposes only, remove this!
		local ent = ents.find_by_name("camera91")[1]
		local camC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PFM_CAMERA) or nil
		if(camC ~= nil) then
			camC:GetCameraData():SetFocalDistance(res)
		end
	end
	return res
end

function fudm.PFMExpressionOperator:UpdateResult()
	local res = self:CalcResult()
	if(res == nil) then return end
	self:SetResult(res)
end
