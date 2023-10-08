--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:UpdateKeyframe(actor, targetPath, panimaChannel, keyIdx, time, value, baseIndex)
	local animManager = self:GetAnimationManager()
	animManager:UpdateKeyframe(actor, targetPath, panimaChannel, keyIdx, time, value, baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:UpdateActorProperty(actor, targetPath)
	end
end
function Element:MakeActorPropertyAnimated(actor, targetPath, valueType, makeAnimated, pushUndo)
	if makeAnimated == nil then
		makeAnimated = true
	end
	if pushUndo == nil then
		pushUndo = true
	end
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
	if componentName == nil then
		return
	end

	local cmd = pfm.create_command("composition")

	if makeAnimated == false then
		local res, subCmd = cmd:AddSubCommand("delete_animation_channel", actor, targetPath, valueType)
		if res == pfm.Command.RESULT_SUCCESS then
			subCmd:AddSubCommand("delete_editor_channel", actor, targetPath, valueType)
		end
	else
		local res, subCmd = cmd:AddSubCommand("add_editor_channel", actor, targetPath, valueType)
		if res == pfm.Command.RESULT_SUCCESS then
			subCmd:AddSubCommand("add_animation_channel", actor, targetPath, valueType)
		end
	end

	if pushUndo then
		pfm.undoredo.push(makeAnimated and "make_property_animated" or "clear_property_animation", cmd)()
	else
		cmd:Execute()
	end

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:SetPropertyAnimationOverlaysDirty()
	end
end
function Element:SetActorAnimationComponentProperty(actor, targetPath, time, value, valueType, baseIndex, addKey)
	local animManager = self:GetAnimationManager()
	animManager:SetChannelValue(actor, targetPath, time, value, valueType, addKey, baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:UpdateActorProperty(actor, targetPath)
	end
end

function Element:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) -- For internal use only
	--[[local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return true
	end
	return actorEditor:UpdateAnimationChannelValue(actorData, targetPath, nil, value)]]
end
function Element:SetActorGenericProperty(actor, targetPath, value, udmType)
	local actorData = actor:GetActorData()
	if actorData == nil then
		return
	end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if util.is_valid(rt) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local function applyControllerTarget() -- TODO: Obsolete?
		local memberInfo = pfm.get_member_info(targetPath, actor:GetEntity())
		if memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_CONTROLLER_BIT) and memberInfo.metaData ~= nil then
			local meta = memberInfo.metaData
			local controllerTarget = meta:GetValue("controllerTarget")
			local applyResult = false
			if controllerTarget ~= nil then
				local memberInfoTarget = pfm.get_member_info(controllerTarget, actor:GetEntity())
				if memberInfoTarget ~= nil then
					local targetValue = actor:GetEntity():GetMemberValue(controllerTarget)
					if targetValue ~= nil then
						applyResult =
							self:SetActorGenericProperty(actor, controllerTarget, targetValue, memberInfoTarget.type)
					end
				end
			end
			return true, applyResult
		end
		return false
	end

	if self:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) == false then
		return
	end

	self:GetAnimationManager():SetAnimationDirty(actorData)
	local res
	if udmType ~= udm.TYPE_ELEMENT then
		res = actor:GetEntity():SetMemberValue(targetPath, value)
	else
		res = true
	end
	local hasControlTarget, ctResult = applyControllerTarget()
	if udmType ~= nil then
		local componentName, memberName =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
		if componentName ~= nil then
			local c = actorData:AddComponentType(componentName)
			c:SetMemberValue(memberName:GetString(), udmType, value)
		end
	end
	self:GetActorEditor():UpdateActorProperty(actorData, targetPath)
	self:TagRenderSceneAsDirty()
	if hasControlTarget then
		return ctResult
	end
	return res
end
function Element:SetActorTransformProperty(actor, propType, value, applyUdmValue)
	local actorData = actor:GetActorData()
	if actorData == nil then
		return
	end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if util.is_valid(rt) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local actorEditor = self:GetActorEditor()
	local targetPath = "ec/pfm_actor/" .. propType

	if self:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) == false then
		return
	end

	local transform = actorData:GetTransform()
	if propType == "position" then
		transform:SetOrigin(value)
	elseif propType == "rotation" then
		transform:SetRotation(value)
	elseif propType == "scale" then
		transform:SetScale(value)
	end
	actorData:SetTransform(transform)
	self:TagRenderSceneAsDirty()

	self:GetAnimationManager():SetAnimationDirty(actorData)
	actor:GetEntity():SetMemberValue(targetPath, value)
	self:GetActorEditor():UpdateActorProperty(actorData, targetPath)
end
function Element:SetActorBoneTransformProperty(actor, propType, value, udmType) -- TODO: Obsolete?
	self:SetActorGenericProperty(actor, "ec/animated/bone/" .. propType, value, udmType)
end
function Element:IsInAnimationMode()
	return self:GetTimelineMode() == gui.PFMTimeline.EDITOR_GRAPH
end
function Element:GetAnimatedPropertyData(actor, path)
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
function Element:ToChannelValue(value, valueType)
	return pfm.to_editor_channel_value(value, valueType)
end

-- For internal use only.
-- This function will change the value of the property of an actor. The value will be assigned differently depending on various factors:
-- 1) If the filmmaker is in animation mode, the value will always be assigned as an animated value
-- 2) Else:
--    2.1) If there is no animation channel for the property, the value will be assigned as the base value
--    2.2) Else:
--       2.2.1) If there is only one value present in the animation channel, that value will be overwritten
--       2.2.2) If there is more than one value present, this function will not do anything (in this case this function should never be called)
-- If the value is assigned as animated value, and no animation channel or keyframe exists for the current timestamp, they will be created.
-- In some cases the value may be changed continuously (e.g. by slider manipulation). In this case no undo/redo command is pushed onto
-- the stack until 'final' is set to true, which indicates that the manipulation has ended. The 'oldValue' in this case is the value from before the
-- manipulation has started.
function Element:ChangeActorPropertyValue(
	actor,
	targetPath,
	udmType,
	oldValue,
	value,
	baseIndex,
	final,
	parentCmd,
	cmdKeyframe
)
	local fm = tool.get_filmmaker()
	local isInAnimMode = self:IsInAnimationMode()
	local animManager = fm:GetAnimationManager()
	local anim, channel = animManager:FindAnimationChannel(actor, targetPath, false)
	if isInAnimMode or (channel ~= nil and channel:GetValueCount() < 2) then
		if isInAnimMode then
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
		if isInAnimMode == false then
			time = (channel:GetValueCount() > 0) and channel:GetTime(0) or 0.0
		end
		time = time or fm:GetTimeOffset()

		local actorUuid = tostring(actor:GetUniqueId())

		local animData, propData = self:GetAnimatedPropertyData(actor, targetPath, time)
		local oldValueChannel, valueTypeChannel = self:ToChannelValue(oldValue, animData.valueType)
		local newValueChannel = self:ToChannelValue(value, animData.valueType)
		local underlyingType = udm.get_underlying_numeric_type(valueTypeChannel)
		local function set_keyframe_value(cmd, oldVal, newVal)
			local n = baseIndex or (udm.get_numeric_component_count(valueTypeChannel) - 1)
			for i = 0, n do
				cmd:AddSubCommand(
					"set_keyframe_value",
					actorUuid,
					targetPath,
					time,
					underlyingType,
					(oldVal ~= nil) and udm.get_numeric_component(oldVal, i) or nil,
					udm.get_numeric_component(newVal, i),
					i
				)
			end
		end

		local newCmdKeyframe
		if cmdKeyframe == nil then
			if animData ~= false then
				-- We have to create the keyframe as a separate command. This is because if the value is changed
				-- using a slider, we need the keyframe immediately, even though the final undo/redo command for the value change
				-- isn't created until the user lets go of the slider.
				local cmd = pfm.create_command("keyframe_property_composition", actorUuid, targetPath, baseIndex)
				local res, o =
					cmd:AddSubCommand("create_keyframe", actorUuid, animData.path, valueTypeChannel, time, baseIndex)
				if res == pfm.Command.RESULT_SUCCESS and o ~= nil then
					set_keyframe_value(cmd, oldValueChannel, oldValueChannel) -- Required to restore value on redo
					cmd:Execute()
					newCmdKeyframe = cmd
				end
			else
				pfm.log(
					"Missing animation data for property path '" .. targetPath .. "'!",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_ERROR
				)
			end
		end
		local cmd = pfm.create_command("keyframe_property_composition", actorUuid, targetPath, baseIndex)
		if cmdKeyframe ~= nil then
			-- This is required so that the original property is restored properly on undo after the keyframe
			-- is removed
			cmd:AddSubCommand("set_actor_property", tostring(actor:GetUniqueId()), targetPath, oldValue, value, udmType)

			-- We need this to undo the keyframe that was created
			cmd:AddSubCommandObject(cmdKeyframe)
		end
		if not isInAnimMode then
			cmd:AddSubCommand("set_actor_property", tostring(actor:GetUniqueId()), targetPath, oldValue, value, udmType)
		end
		set_keyframe_value(cmd, oldValueChannel, newValueChannel)
		if final then
			pfm.undoredo.push("change_animation_value", cmd)()
		else
			cmd:Execute()
		end

		return newCmdKeyframe
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

	local cmd = pfm.create_command(
		parentCmd,
		"set_actor_property",
		tostring(actor:GetUniqueId()),
		targetPath,
		oldValue,
		value,
		udmType
	)
	if final then
		pfm.undoredo.push("property", cmd)()
	else
		cmd:Execute()
	end
end
