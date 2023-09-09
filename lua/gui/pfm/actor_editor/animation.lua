--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMActorEditor:UpdateAnimatedPropertyOverlay(uuid, controlData)
	local pm = tool.get_filmmaker()
	local timeline = pm:GetTimeline()
	local inGraphEditor = (timeline:GetEditor() == gui.PFMTimeline.EDITOR_GRAPH)

	local filmClip = self:GetFilmClip()
	local actor = (filmClip ~= nil) and filmClip:FindActorByUniqueId(uuid) or nil
	local animManager = pm:GetAnimationManager()
	local anim, channel, animClip
	if actor ~= nil and animManager ~= nil then
		anim, channel, animClip = animManager:FindAnimationChannel(actor, controlData.controlData.path)
	end
	util.remove(controlData.animatedPropertyOverlay)
	if channel == nil then
		-- Property is not animated
		return
	end

	local ctrl = controlData.control
	if util.is_valid(ctrl) == false then
		return
	end

	controlData.animatedPropertyOverlay = nil
	local outlineParent = ctrl
	if channel:GetValueCount() >= 2 then -- Disable the field if there is more than one animation value
		if inGraphEditor == false then
			local elDisabled = gui.create("WIRect", ctrl, 0, 0, ctrl:GetWidth(), ctrl:GetHeight(), 0, 0, 1, 1)
			elDisabled:SetColor(Color(0, 0, 0, 200))
			elDisabled:SetZPos(10)
			elDisabled:SetMouseInputEnabled(true)
			elDisabled:SetCursor(gui.CURSOR_SHAPE_HAND)
			elDisabled:SetTooltip(locale.get_text("pfm_animated_property_tooltip"))
			elDisabled:AddCallback("OnMouseEvent", function(el, button, state, mods)
				if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
					-- We have to switch to the graph editor, but that changes the overlay state (which invalidates this callback),
					-- so we have to delay it
					local propertyName = controlData.controlData.name
					time.create_simple_timer(0.0, function()
						if self:IsValid() then
							self:ShowPropertyInGraphEditor(propertyName)
						end
					end)
					return util.EVENT_REPLY_HANDLED
				end
			end)
			controlData.animatedPropertyOverlay = elDisabled
			outlineParent = elDisabled
		end
	end

	local elOutline = gui.create(
		"WIOutlinedRect",
		outlineParent,
		0,
		0,
		outlineParent:GetWidth(),
		outlineParent:GetHeight(),
		0,
		0,
		1,
		1
	)
	elOutline:SetColor(pfm.get_color_scheme_color("orange"))
	controlData.animatedPropertyOverlay = controlData.animatedPropertyOverlay or elDisabled
end
function gui.PFMActorEditor:UpdateAnimatedPropertyOverlays()
	for uuid, controls in pairs(self.m_activeControls) do
		for path, ctrlData in pairs(controls) do
			self:UpdateAnimatedPropertyOverlay(uuid, ctrlData)
		end
	end
end
function gui.PFMActorEditor:SetPropertyAnimationOverlaysDirty()
	self.m_controlOverlayUpdateRequired = true
	self:EnableThinking()
end
function gui.PFMActorEditor:ClearPropertyExpression(actorData, controlData)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager == nil then
		return
	end
	animManager:SetValueExpression(actorData.actor, controlData.path)

	local anim, channel, animClip = animManager:FindAnimationChannel(actorData.actor, controlData.path)
	if animClip ~= nil then
		local channel = animClip:GetChannel(controlData.path)
		if channel ~= nil then
			channel:SetExpression()
		end
	end
	self:DoUpdatePropertyIcons(actorData, controlData)
end
function gui.PFMActorEditor:OpenPropertyExpressionWindow(actorData, controlData)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager == nil then
		return
	end
	local te
	local timer
	local p = pfm.open_entry_edit_window(locale.get_text("pfm_set_expression"), function(ok)
		util.remove(timer)
		if ok then
			pfm.undoredo.push(
				"set_property_expression",
				pfm.create_command(
					"set_property_expression",
					tostring(actorData.actor:GetUniqueId()),
					controlData.path,
					te:GetText(),
					controlData.type
				)
			)()
		end
	end)
	local expr = animManager:GetValueExpression(actorData.actor, controlData.path)
	te = p:AddTextField(locale.get_text("pfm_expression") .. ":", expr or "")
	te:GetTextElement():SetFont("pfm_medium")

	local tmpChannel
	local elMsg = p:AddText(locale.get_text("evaluation"), locale.get_text("pfm_no_error"))
	elMsg:SetColor(Color.Green)
	elMsg:SetFont("pfm_small")
	te:AddCallback("OnTextChanged", function()
		util.remove(timer)
		timer = time.create_timer(0.5, 0, function()
			if te:IsValid() == false then
				return
			end
			if tmpChannel == nil then
				-- Create temporary channel
				tmpChannel = panima.Channel()
				tmpChannel:GetValueArray():SetValueType(controlData.type)
			end
			local res = tmpChannel:TestValueExpression(te:GetText())
			local res, msg = res == true, (res ~= true) and res or nil
			if res then
				elMsg:SetText(locale.get_text("pfm_no_error"))
				elMsg:SetColor(Color.Green)
				elMsg:SizeToContents()
			else
				elMsg:SetText(msg)
				elMsg:SetColor(Color.Red)
				elMsg:SizeToContents()
			end
		end)
		timer:Start()
	end)

	p:SetWindowSize(Vector2i(800, 140))
	p:Update()
end
function gui.PFMActorEditor:GetAnimationChannel(actor, path, addIfNotExists)
	local filmClip = self:GetFilmClip()
	local track = filmClip:FindAnimationChannelTrack()

	local channelClip = track:FindActorAnimationClip(actor, addIfNotExists)
	if channelClip == nil then
		return
	end
	local path = panima.Channel.Path(path)
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(path)
	local componentId = componentName and ents.get_component_id(componentName)
	local componentInfo = componentId and ents.get_component_info(componentId)

	local entActor = actor:FindEntity()
	local memberInfo
	if memberName ~= nil and componentInfo ~= nil then
		if util.is_valid(entActor) then
			local c = entActor:GetComponent(componentId)
			if c ~= nil then
				local memberId = c:GetMemberIndex(memberName:GetString())
				if memberId ~= nil then
					memberInfo = c:GetMemberInfo(memberId)
				end
			end
		end
		memberInfo = memberInfo or componentInfo:GetMemberInfo(memberName:GetString())
	end
	if memberInfo == nil then
		return
	end

	local type = memberInfo.type
	path = path:ToUri(false)
	local varType = type
	-- if(memberName:GetString() == "color") then varType = util.VAR_TYPE_COLOR end -- TODO: How to handle this properly?
	local channel = channelClip:GetChannel(path, varType, addIfNotExists)
	return channel, channelClip
end
function gui.PFMActorEditor:UpdateAnimationChannelValue(actorData, targetPath, oldValue, value, baseIndex, final) -- For internal use only
	-- If the property is animated, we'll defer the assignment of the value to the animation manager.
	-- If the channel for the property only has a single animation value, and we're not in the graph editor, special behavior is triggered:
	-- In this case we will set both the base value of the property, as well as the animation value.
	-- This is for convenience, so that the user can quickly edit the value through the actor editor, even
	-- when they're not in the graph editor.
	local fm = tool.get_filmmaker()
	local inGraphEditor = (self:GetTimelineMode() == gui.PFMTimeline.EDITOR_GRAPH)
	local animManager = fm:GetAnimationManager()
	local anim, channel = animManager:FindAnimationChannel(actorData, targetPath, false)
	if inGraphEditor or (channel ~= nil and channel:GetValueCount() < 2) then
		if inGraphEditor then
			if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
				pfm.log(
					"Graph editor is active. Value "
						.. tostring(value)
						.. " of property '"
						.. targetPath
						.. "' will be assigned as animation value...",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_DEBUG
				)
			end
		else
			if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
				pfm.log(
					"Animation channel for property '"
						.. targetPath
						.. "' contains less than two values. Value "
						.. tostring(value)
						.. " will be assigned as animation value, as well as base value...",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_DEBUG
				)
			end
		end
		local time
		if inGraphEditor == false then
			time = (channel:GetValueCount() > 0) and channel:GetTime(0) or 0.0
		end
		time = time or fm:GetTimeOffset()

		local actorUuid = tostring(actorData:GetUniqueId())
		local cmd = pfm.create_command("keyframe_property_composition", actorUuid, targetPath, baseIndex)
		local animData, propData = self:GetAnimatedPropertyData(actorData, targetPath, time)
		if animData ~= false then
			if
				pfm.CommandCreateKeyframe.does_keyframe_exist(animManager, actorUuid, targetPath, time, baseIndex)
				== false
			then
				cmd:AddSubCommand("create_keyframe", actorUuid, animData.path, animData.valueType, time, baseIndex)
			end
		else
			-- TODO
			debug.print("ERROR")
		end

		cmd:AddSubCommand(
			"set_keyframe_value",
			actorUuid,
			targetPath,
			time,
			self:ToChannelValue(oldValue),
			self:ToChannelValue(value),
			baseIndex
		)
		if final then
			pfm.undoredo.push("change_animation_value", cmd)()
		else
			cmd:Execute()
		end

		-- TODO: Add main property action from return value
		--

		-- self:SetAnimationChannelValue(actorData, targetPath, value, baseIndex, time)
		if inGraphEditor then
			return false
		end
	else
		if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
			pfm.log(
				"Graph editor is not active. Value "
					.. tostring(value)
					.. " of property '"
					.. targetPath
					.. "' will be applied as base value only...",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_DEBUG
			)
		end
	end
	return true -- Returning true will ensure the base value will be changed
end
function gui.PFMActorEditor:ToChannelValue(value)
	local channelValue = value
	if util.get_type_name(channelValue) == "Color" then
		channelValue = channelValue:ToVector()
	end
	return channelValue
end
function gui.PFMActorEditor:GetAnimatedPropertyData(actor, path)
	local path = panima.Channel.Path(path)
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(path)
	local componentId = componentName and ents.get_component_id(componentName)
	local componentInfo = componentId and ents.get_component_info(componentId)

	local entActor = actor:FindEntity()
	local memberInfo
	if memberName ~= nil and componentInfo ~= nil then
		if util.is_valid(entActor) then
			local c = entActor:GetComponent(componentId)
			if c ~= nil then
				local memberId = c:GetMemberIndex(memberName:GetString())
				if memberId ~= nil then
					memberInfo = c:GetMemberInfo(memberId)
				end
			end
		end
		memberInfo = memberInfo or componentInfo:GetMemberInfo(memberName:GetString())
	end
	local propertyData = {
		path = path,
		componentName = componentName,
		componentId = componentId,
		memberName = memberName,
	}
	if memberInfo == nil then
		return false, propertyData
	end
	local type = memberInfo.type
	path = path:ToUri(false)

	return {
		path = path,
		valueType = type,
	}, propertyData
end
function gui.PFMActorEditor:SetAnimationChannelValue(actor, path, value, baseIndex, forceAtTime)
	local fm = tool.get_filmmaker()
	local animData, propData = self:GetAnimatedPropertyData(actor, path)

	local filmClip = self:GetFilmClip()
	local track = filmClip:FindAnimationChannelTrack()
	local channelClip = track:FindActorAnimationClip(actor, true)
	local localTime = channelClip:LocalizeOffsetAbs(forceAtTime or fm:GetTimeOffset())

	if animData == false then
		local baseMsg = "Unable to apply animation channel value with channel path '"
			.. propData.path:GetString()
			.. "': "
		if propData.componentName == nil then
			pfm.log(
				baseMsg .. "Unable to determine component type from animation channel path '" .. path .. "'!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
		elseif propData.componentId == nil then
			pfm.log(
				baseMsg .. "Component '" .. propData.componentName .. "' is unknown!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
		else
			pfm.log(
				baseMsg
					.. "Component '"
					.. propData.componentName
					.. "' has no known member '"
					.. propData.memberName:GetString()
					.. "'!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
		end
		return
	end
	local fm = tool.get_filmmaker()
	fm:SetActorAnimationComponentProperty(
		actor,
		animData.path,
		localTime,
		self:ToChannelValue(value),
		animData.valueType,
		baseIndex
	)
end
