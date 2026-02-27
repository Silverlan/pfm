-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function gui.PFMActorEditor:AddSliderControl(component, controlData)
	if util.is_valid(self.m_animSetControls) == false then
		return
	end

	local slider = self.m_animSetControls:AddSliderControl(
		controlData.name,
		controlData.identifier,
		controlData.translateToInterface(controlData.default or 0.0),
		controlData.translateToInterface(controlData.min or 0.0),
		controlData.translateToInterface(controlData.max or 100),
		nil,
		nil,
		controlData.integer or controlData.boolean
	)
	if controlData.default ~= nil then
		slider:SetDefault(controlData.translateToInterface(controlData.default))
	end

	if controlData.getValue ~= nil then
		local val = controlData.getValue()
		if val ~= nil then
			slider:SetValue(controlData.translateToInterface(val))
		end
	end

	local callbacks = {}
	local skipCallbacks
	if controlData.type == "flexController" then
		if controlData.dualChannel == true then
			slider:GetLeftRightValueRatioProperty():Link(self.m_leftRightWeightSlider:GetFractionProperty())
		end
		if controlData.property ~= nil then
			slider:SetValue(controlData.translateToInterface(component:GetProperty(controlData.property):GetValue()))
		elseif controlData.get ~= nil then
			slider:SetValue(controlData.translateToInterface(controlData.get(component)))
			if controlData.getProperty ~= nil then
				local prop = controlData.getProperty(component)
				if prop ~= nil then
					local cb = prop:AddChangeListener(function(newValue)
						self:TagRenderSceneAsDirty()
						if skipCallbacks then
							return
						end
						skipCallbacks = true
						slider:SetValue(controlData.translateToInterface(newValue))
						skipCallbacks = nil
					end)
					table.insert(callbacks, cb)
				end
			end
		elseif controlData.dualChannel == true then
			if controlData.getLeft ~= nil then
				slider:SetLeftValue(controlData.translateToInterface(controlData.getLeft(component)))
				if controlData.getLeftProperty ~= nil then
					local prop = controlData.getLeftProperty(component)
					if prop ~= nil then
						local cb = prop:AddChangeListener(function(newValue)
							self:TagRenderSceneAsDirty()
							if skipCallbacks then
								return
							end
							skipCallbacks = true
							slider:SetLeftValue(controlData.translateToInterface(newValue))
							skipCallbacks = nil
						end)
						table.insert(callbacks, cb)
					end
				end
			end
			if controlData.getRight ~= nil then
				slider:SetRightValue(controlData.translateToInterface(controlData.getRight(component)))
				if controlData.getRightProperty ~= nil then
					local prop = controlData.getRightProperty(component)
					if prop ~= nil then
						local cb = prop:AddChangeListener(function(newValue)
							self:TagRenderSceneAsDirty()
							if skipCallbacks then
								return
							end
							skipCallbacks = true
							slider:SetRightValue(controlData.translateToInterface(newValue))
							skipCallbacks = nil
						end)
						table.insert(callbacks, cb)
					end
				end
			end
		end
	elseif controlData.property ~= nil then
		local prop = component:GetProperty(controlData.property)
		if prop ~= nil then
			local function get_numeric_value(val)
				if val == true then
					val = 1.0
				elseif val == false then
					val = 0.0
				end
				return val
			end
			local cb = prop:AddChangeListener(function(newValue)
				self:TagRenderSceneAsDirty()
				if skipCallbacks then
					return
				end
				skipCallbacks = true
				slider:SetValue(controlData.translateToInterface(get_numeric_value(newValue)))
				skipCallbacks = nil
			end)
			table.insert(callbacks, cb)
			slider:SetValue(controlData.translateToInterface(get_numeric_value(prop:GetValue())))
		end
	end
	if #callbacks > 0 then
		slider:AddCallback("OnRemove", function()
			for _, cb in ipairs(callbacks) do
				if cb:IsValid() then
					cb:Remove()
				end
			end
		end)
	end
	local inputData
	slider:AddCallback("OnUserInputStarted", function(el, value)
		inputData = {
			initialValue = value,
		}
	end)
	slider:AddCallback("OnUserInputEnded", function(el, value)
		if self.m_skipUpdateCallback then
			return
		end
		if controlData.boolean then
			value = toboolean(value)
		end
		if controlData.set ~= nil then
			controlData.set(component, value, nil, nil, true, inputData)
		end
		inputData = nil
	end)
	slider:AddCallback("OnLeftValueChanged", function(el, value)
		if self.m_skipUpdateCallback then
			return
		end
		if controlData.boolean then
			value = toboolean(value)
		end
		if controlData.set ~= nil then
			controlData.set(component, value, nil, nil, nil, inputData)
		end
		--[[if(controlData.property ~= nil) then
			component:GetProperty(controlData.property):SetValue(controlData.translateFromInterface(value))
		elseif(controlData.set ~= nil) then
			controlData.set(component,value)
		elseif(controlData.setLeft ~= nil) then
			controlData.setLeft(component,value)
		end
		applyComponentChannelValue(self,component,controlData,value)]]
	end)
	slider:AddCallback("OnRightValueChanged", function(el, value)
		if self.m_skipUpdateCallback then
			return
		end
		if controlData.boolean then
			value = toboolean(value)
		end
		if controlData.setRight ~= nil then
			controlData.setRight(component, value, nil, nil, nil, inputData)
		end
	end)
	--[[slider:AddCallback("PopulateContextMenu",function(el,pContext)
		pContext:AddItem("LOC: Set Math Expression",function()
			local parent = component:GetSceneParent()
			if(parent ~= nil and controlData.path ~= nil and parent:GetType() == fudm.ELEMENT_TYPE_PFM_ACTOR) then
				local channel = self:GetAnimationChannel(parent,controlData.path,true)
				if(channel ~= nil) then
					local expr = "abs(sin(time)) *20"
					debug.print("Set expression: ",expr)
					channel:SetExpression(expr)
					tool.get_filmmaker():GetAnimationManager():SetValueExpression(parent,controlData.path,expr)
				end
			end
		end)
		pContext:AddItem("LOC: Set Animation driver",function()
			local parent = component:GetSceneParent()
			if(parent ~= nil and controlData.path ~= nil and parent:GetType() == fudm.ELEMENT_TYPE_PFM_ACTOR) then
				local channel = self:GetAnimationChannel(parent,controlData.path,true)
				if(channel ~= nil) then
					--debug.print("Set expression!")
					--channel:SetExpression("sin(value)")
				end
			end
		end)
	end)]]
	table.insert(self.m_sliderControls, slider)
	return slider
end
