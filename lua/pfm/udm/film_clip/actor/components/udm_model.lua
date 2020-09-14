--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")
include("udm_global_flex_controller_operator.lua")
include("udm_bone.lua")
include("udm_material.lua")
include("/gui/fileentry.lua")
include("/gui/wimodeldialog.lua")

udm.ELEMENT_TYPE_PFM_MODEL = udm.register_type("PFMModel",{udm.PFMEntityComponent},true)
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

function udm.PFMModel:GetSceneChildren() return self:GetRootBones():GetTable() end

function udm.PFMModel:GetModel()
	local mdlName = self:GetModelName()
	if(#mdlName == 0) then return end
	if(self.m_mdlCache ~= nil and self.m_mdlCache[1] == mdlName) then return self.m_mdlCache[2] end
	local mdl = game.load_model(mdlName)
	self.m_mdlCache = {mdlName,mdl}
	return mdl
end

function udm.PFMModel:FindFlexControllerWeight(name)
	for i,fcName in ipairs(self:GetFlexControllerNames():GetTable()) do
		if(fcName:GetValue() == name) then return self:GetFlexWeights():Get(i) end
	end
end

function udm.PFMModel:FindBone(name)
	for _,bone in ipairs(self:GetBoneList():GetTable()) do
		if(bone:GetTarget():GetName() == name) then return bone end
	end
end

function udm.PFMModel:CalcBonePose(track,boneName,t)
	local bone = (type(boneName) == "string") and self:FindBone(boneName) or self:GetBoneList():Get(boneName)
	if(bone == nil) then return phys.ScaledTransform() end
	bone = bone:GetTarget()
	local transform = bone:GetTransform()
	--[[local elSlave = transform:FindParent(function(el) return el:GetType() == udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE end)
	if(elSlave ~= nil) then

	end]]
	return track:CalcBonePose(transform,t)
end

function udm.PFMModel:SetupFlexControllerControls(actorEditor,itemComponent)
	local filmClip = actorEditor:GetFilmClip()
	local mdl = self:GetModel()
	if(mdl == nil) then return end
	local flexControls = {}
	for i,name in ipairs(self:GetFlexControllerNames():GetTable()) do
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
				if(left) then
					data.leftFlexControllerId = flexCId
					data.leftFlexControllerDataId = i
				else
					data.rightFlexControllerId = flexCId
					data.rightFlexControllerDataId = i
				end
				flexControls[postfixName] = data
			else
				local flexC = mdl:GetFlexController(name)
				flexControls[name] = {
					min = min,
					max = max,
					flexControllerId = flexCId,
					flexControllerDataId = i
				}
			end
		end
	end
	for name,data in pairs(flexControls) do
		if(data.leftRight) then
			actorEditor:AddControl(self,itemComponent,{
				name = name,
				type = "flexController",
				dualChannel = true,
				getLeftProperty = function(component)
					return self:GetFlexWeights():Get(data.leftFlexControllerDataId)
				end,
				getLeft = function(component)
					local weight = self:GetFlexWeights():Get(data.leftFlexControllerDataId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				getRightProperty = function(component)
					return self:GetFlexWeights():Get(data.rightFlexControllerDataId)
				end,
				getRight = function(component)
					local weight = self:GetFlexWeights():Get(data.rightFlexControllerDataId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				setLeft = function(component,value)
					local weight = self:GetFlexWeights():Get(data.leftFlexControllerDataId)
					if(weight == nil) then return end
					weight:SetValue(value)
				end,
				setRight = function(component,value)
					local weight = self:GetFlexWeights():Get(data.rightFlexControllerDataId)
					if(weight == nil) then return end
					weight:SetValue(value)
				end,
				min = 0.0,
				max = 1.0,
				default = 0.0
			})
		else
			actorEditor:AddControl(self,itemComponent,{
				name = name,
				type = "flexController",
				getProperty = function(component)
					return self:GetFlexWeights():Get(data.flexControllerDataId)
				end,
				get = function(component)
					local weight = self:GetFlexWeights():Get(data.flexControllerDataId)
					return (weight ~= nil) and weight:GetValue() or 0.0
				end,
				set = function(component,value)
					local weight = self:GetFlexWeights():Get(data.flexControllerDataId)
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

function udm.PFMModel:SetupBoneControls(actorEditor,itemComponent)
	local itemBones = itemComponent:AddItem(locale.get_text("skeleton"))
	for _,bone in ipairs(self:GetBoneList():GetTable()) do
		bone = bone:GetTarget()
		actorEditor:AddControl(self,itemComponent,{
			name = bone:GetName(),
			type = "bone",
			bone = bone,
			min = 0.0,
			max = 1.0,
			default = 0.0
		})
	end
end

function udm.PFMModel:SetupControls(actorEditor,itemComponent)
	local itemFlexControllers = itemComponent:AddItem(locale.get_text("flex_controllers"))
	self:SetupFlexControllerControls(actorEditor,itemFlexControllers)
	
	local itemBones = itemComponent:AddItem(locale.get_text("skeleton"))
	self:SetupBoneControls(actorEditor,itemBones)

	local itemBaseProps = itemComponent:AddItem(locale.get_text("pfm_base_properties"))
	actorEditor:AddControl(self,itemBaseProps,{
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

	-- Properties
	actorEditor:AddProperty(locale.get_text("model"),itemBaseProps,function(parent)
		local el = gui.create("WIFileEntry",parent)
		el:SetValue(self:GetModelName())
		el:SetBrowseHandler(function(resultHandler)
			gui.open_model_dialog(function(dialogResult,mdlName)
				if(dialogResult ~= gui.DIALOG_RESULT_OK) then return end
				resultHandler(mdlName)
			end)
		end)
		el:AddCallback("OnValueChanged",function(el,value)
			self:SetModelName(value)
		end)
		return el
	end)

	actorEditor:AddProperty(locale.get_text("skin"),itemBaseProps,function(parent)
		local slider = gui.create("WIPFMSlider",parent)
		slider:SetText(locale.get_text("skin"))
		slider:SetInteger(true)
		slider:SetRange(0,10,0) -- TODO: Change depending on model!
		slider:SetValue(self:GetSkin())
		slider:AddCallback("OnLeftValueChanged",function(el,value)
			self:SetSkin(value)
		end)
		return slider
	end)
end
