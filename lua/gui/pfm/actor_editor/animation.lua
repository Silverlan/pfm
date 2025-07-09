-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/keyframe_marker.lua")

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
