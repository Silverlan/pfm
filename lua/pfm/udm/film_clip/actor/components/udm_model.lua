--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_global_flex_controller_operator.lua")
include("udm_bone.lua")
include("udm_material.lua")

udm.ELEMENT_TYPE_PFM_MODEL = udm.register_element("PFMModel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"modelName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"skin",udm.Int(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"bodyGroup",udm.Int(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"rootBones",udm.Array(udm.ELEMENT_TYPE_PFM_BONE))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"boneList",udm.Array(udm.ELEMENT_TYPE_PFM_BONE))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"flexWeights",udm.Array(udm.ATTRIBUTE_TYPE_FLOAT))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"flexControllerNames",udm.Array(udm.ATTRIBUTE_TYPE_STRING))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"globalFlexControllers",udm.Array(udm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"materialOverrides",udm.Array(udm.ELEMENT_TYPE_PFM_MATERIAL))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"flexControllerScale",udm.Float(1.0))

function udm.PFMModel:GetComponentName() return "pfm_model" end
function udm.PFMModel:GetIconMaterial() return "gui/pfm/icon_model_item" end

function udm.PFMModel:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_flex_controller_scale"),
		get = function(component)
			return self:GetFlexControllerScale()
		end,
		set = function(component,value)
			self:SetFlexControllerScale(value)
		end,
		min = 0.0,
		max = 8.0,
		default = 1.0
	})

	local mdl = game.load_model(self:GetModelName())
	local flexControls = {}
	for _,name in ipairs(self:GetFlexControllerNames():GetTable()) do
		name = name:GetValue()
		if(#name > 0) then
			local min = 0.0
			local max = 1.0
			if(mdl ~= nil) then
				local flexC = mdl:GetFlexController(name)
				if(flexC ~= nil) then
					-- TODO: What if left controller has different limits than right controller?
					min = flexC.min
					max = flexC.max
				end
			end

			local flexCId = mdl:LookupFlexController(name)
			local left = (name:sub(1,5) == "left_")
			local right = (name:sub(1,6) == "right_")
			if(left or right) then
				local postfixName = name:sub(left and 6 or 7)
				local data = flexControls[postfixName] or {}
				data.leftRight = true
				data.min = min
				data.max = max
				if(left) then data.leftFlexControllerId = flexCId
				else data.rightFlexControllerId = flexCId end
				flexControls[postfixName] = data
			else
				local flexC = mdl:GetFlexController(name)
				flexControls[name] = {
					min = min,
					max = max,
					flexControllerId = flexCId
				}
			end
		end
	end
	for name,data in pairs(flexControls) do
		if(data.leftRight) then
			actorEditor:AddControl(self,itemComponent,{
				name = name,
				dualChannel = true,
				getLeft = function(component)
					local weight = self:GetFlexWeights():Get(data.leftFlexControllerId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				getRight = function(component)
					local weight = self:GetFlexWeights():Get(data.rightFlexControllerId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				setLeft = function(component,value)
					local weight = self:GetFlexWeights():Get(data.leftFlexControllerId)
					if(weight == nil) then return end
					print("Set left ",value)
					weight:SetValue(value)
				end,
				setRight = function(component,value)
					local weight = self:GetFlexWeights():Get(data.rightFlexControllerId)
					if(weight == nil) then return end
					print("Set right ",value)
					weight:SetValue(value)
				end,
				min = 0.0,
				max = 1.0,
				default = 0.0
			})
		else
			actorEditor:AddControl(self,itemComponent,{
				name = name,
				get = function(component)
					local weight = self:GetFlexWeights():Get(data.flexControllerId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				set = function(component,value)
					local weight = self:GetFlexWeights():Get(data.flexControllerId)
					if(weight == nil) then return end
					weight:SetValue(value)
				end,
				min = 0.0,
				max = 1.0,
				default = 0.0
			})
		end
	end
end
