--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:InitializeBindingLayers()
	local udmData, err = udm.load("cfg/pfm/keybindings.udm")
	local layers = {}
	if udmData ~= false then
		local loadedLayers = input.InputBindingLayer.load(udmData:GetAssetData())
		if loadedLayers ~= false then
			for _, layer in ipairs(loadedLayers) do
				layers[layer.identifier] = layer
			end
		end
	end

	-- Note: cfg/pfm/keybindings.udm has to be deleted or edited when these are changed
	if layers["pfm"] == nil then
		local bindingLayer = input.InputBindingLayer("pfm")
		bindingLayer:BindKey("space", "pfm_action toggle_play")
		bindingLayer:BindKey(",", "pfm_action previous_frame")
		bindingLayer:BindKey(".", "pfm_action next_frame")
		bindingLayer:BindKey("[", "pfm_action previous_bookmark")
		bindingLayer:BindKey("]", "pfm_action next_bookmark")
		bindingLayer:BindKey("m", "pfm_action create_bookmark")

		bindingLayer:BindKey("f2", "pfm_action select_editor clip")
		bindingLayer:BindKey("f3", "pfm_action select_editor motion")
		bindingLayer:BindKey("f4", "pfm_action select_editor graph")

		bindingLayer:BindKey("x", "pfm_action transform move x")
		bindingLayer:BindKey("y", "pfm_action transform move y")
		bindingLayer:BindKey("z", "pfm_action transform move z")

		bindingLayer:BindKey("q", "pfm_action transform select")
		bindingLayer:BindKey("t", "pfm_action transform translate")
		bindingLayer:BindKey("r", "pfm_action transform rotate")
		bindingLayer:BindKey("s", "pfm_action transform scale")

		bindingLayer:BindKey("del", "pfm_delete")

		layers["pfm"] = bindingLayer
	end
	if layers["pfm_graph_editor"] == nil then
		local bindingLayer = input.InputBindingLayer("pfm_graph_editor")
		bindingLayer:BindKey("m", "pfm_graph_editor_action bookmark")

		bindingLayer:BindKey("q", "pfm_graph_editor_action select select")
		bindingLayer:BindKey("w", "pfm_graph_editor_action select move")
		bindingLayer:BindKey("e", "pfm_graph_editor_action select pan")
		bindingLayer:BindKey("r", "pfm_graph_editor_action select scale")
		bindingLayer:BindKey("t", "pfm_graph_editor_action select zoom")

		bindingLayer:BindKey("1", "pfm_graph_editor_action select tangent_linear")
		bindingLayer:BindKey("2", "pfm_graph_editor_action select tangent_flat")
		bindingLayer:BindKey("3", "pfm_graph_editor_action select tangent_spline")
		bindingLayer:BindKey("4", "pfm_graph_editor_action select tangent_step")
		bindingLayer:BindKey("5", "pfm_graph_editor_action select tangent_unify")
		bindingLayer:BindKey("6", "pfm_graph_editor_action select tangent_equalize")
		bindingLayer:BindKey("7", "pfm_graph_editor_action select tangent_weighted")
		bindingLayer:BindKey("8", "pfm_graph_editor_action select tangent_unweighted")

		-- TODO: Enable these when modifier keybinds are implemented
		-- bindingLayer:BindKey("n","pfm_graph_editor_action select snap")
		-- bindingLayer:BindKey("r","pfm_graph_editor_action select snap_frame")

		-- bindingLayer:BindKey("m","pfm_graph_editor_action select mute")
		layers["pfm_graph_editor"] = bindingLayer
	end
	if layers["pfm_viewport"] == nil then
		local bindingLayer = input.InputBindingLayer("pfm_viewport")
		bindingLayer:BindKey("scrlup", "pfm_action zoom in")
		bindingLayer:BindKey("scrldn", "pfm_action zoom out")

		layers["pfm_viewport"] = bindingLayer
	end
	if layers["pfm_transform"] == nil then
		local bindingLayer = input.InputBindingLayer("pfm_transform")
		bindingLayer:BindKey("scrlup", "pfm_transform_distance in")
		bindingLayer:BindKey("scrldn", "pfm_transform_distance out")

		layers["pfm_transform"] = bindingLayer
	end
	layers["pfm"].priority = 1000
	layers["pfm_graph_editor"].priority = 2000
	layers["pfm_transform"].priority = 4000
	for _, layer in pairs(layers) do
		input.add_input_binding_layer(layer)
		input.set_binding_layer_enabled(layer.identifier, (layer.identifier == "pfm"))
	end
	self.m_inputBindingLayers = layers
	self:UpdateInputBindings()
end

function Element:KeyboardCallback(key, scanCode, state, mods)
	if input.is_ctrl_key_down() then
		if key == input.KEY_S then
			if state == input.STATE_PRESS then
				self:Save(nil, nil, nil, nil, function(res)
					if res then
						self:ResetEditState()
					end
				end)
			end
			return util.EVENT_REPLY_HANDLED
		elseif key == input.KEY_C then
			if state == input.STATE_PRESS then
				local actorEditor = self:GetActorEditor()
				if util.is_valid(actorEditor) then
					actorEditor:CopyToClipboard()
				end
			end
			return util.EVENT_REPLY_HANDLED
		elseif key == input.KEY_V then
			if state == input.STATE_PRESS then
				local actorEditor = self:GetActorEditor()
				if util.is_valid(actorEditor) then
					actorEditor:PasteFromClipboard()
				end
			end
			return util.EVENT_REPLY_HANDLED
		elseif key == input.KEY_Z then
			if state == input.STATE_PRESS then
				pfm.undo()
			end
			return util.EVENT_REPLY_HANDLED
		elseif key == input.KEY_Y then
			if state == input.STATE_PRESS then
				pfm.redo()
			end
			return util.EVENT_REPLY_HANDLED
		end
	else
		-- TODO: UNDO ME
		--[[local entGhost = ents.find_by_class("pfm_ghost")[1]
		if(util.is_valid(entGhost)) then
			local lightC = entGhost:GetComponent(ents.COMPONENT_LIGHT)
			lightC.colTemp = lightC.colTemp or light.get_average_color_temperature(light.NATURAL_LIGHT_TYPE_LED_LAMP)
			if(key == input.KEY_KP_ADD and state == input.STATE_PRESS) then
				lightC.colTemp = lightC.colTemp +500
			elseif(key == input.KEY_KP_SUBTRACT and state == input.STATE_PRESS) then
				lightC.colTemp = lightC.colTemp -500
			end
			lightC.colTemp = math.clamp(lightC.colTemp,965,12000)
			local colorC = entGhost:GetComponent(ents.COMPONENT_COLOR)
			colorC:SetColor(light.color_temperature_to_color(lightC.colTemp))
		end
		return util.EVENT_REPLY_HANDLED]]
	end
	--[[elseif(key == input.KEY_KP_ADD and state == input.STATE_PRESS) then
		ents.PFMGrid.decrease_grid_size()
		return util.EVENT_REPLY_HANDLED
	elseif(key == input.KEY_KP_SUBTRACT and state == input.STATE_PRESS) then
		ents.PFMGrid.increase_grid_size()
		return util.EVENT_REPLY_HANDLED
	end]]
	return util.EVENT_REPLY_UNHANDLED
end

function Element:AddInputBindingLayer(name, bindingLayer)
	self.m_inputBindingLayers[name] = bindingLayer

	input.add_input_binding_layer(bindingLayer)
	input.set_binding_layer_enabled(bindingLayer.identifier, true)
	input.update_effective_input_bindings()
end
function Element:RemoveInputBindingLayer(name)
	if self.m_inputBindingLayers[name] == nil then
		return
	end
	self.m_inputBindingLayers[name] = nil

	input.remove_input_binding_layer(name)
	input.update_effective_input_bindings()
end
function Element:GetInputBindingLayers()
	return self.m_inputBindingLayers
end
function Element:GetInputBindingLayer(id)
	return self.m_inputBindingLayers[id or "pfm"]
end
function Element:UpdateInputBindings()
	input.update_effective_input_bindings()
end
