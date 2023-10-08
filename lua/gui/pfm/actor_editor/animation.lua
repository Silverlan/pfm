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
function gui.PFMActorEditor:UpdateAnimationChannelValue(
	actorData,
	targetPath,
	udmType,
	oldValue,
	value,
	baseIndex,
	final,
	parentCmd
) -- For internal use only
	return tool.get_filmmaker()
		:ChangeActorPropertyValue(actorData, targetPath, udmType, oldValue, value, baseIndex, final, parentCmd)
end
