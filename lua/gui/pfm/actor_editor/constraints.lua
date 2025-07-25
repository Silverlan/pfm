-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}

function pfm.util.is_pose_property_type(type)
	return type == udm.TYPE_TRANSFORM or type == udm.TYPE_SCALED_TRANSFORM
end

function pfm.util.is_property_type_positional(type)
	return udm.is_convertible(type, udm.TYPE_VECTOR3) and udm.is_numeric_type(type) == false and type ~= udm.TYPE_STRING
end

function pfm.util.is_property_type_rotational(type)
	return type == udm.TYPE_EULER_ANGLES or type == udm.TYPE_QUATERNION
end

function pfm.util.find_property_pose_meta_info(ent, path)
	local memberInfo = pfm.get_member_info(path, ent)
	if memberInfo == nil then
		return
	end
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	local metaInfoPose = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
	if metaInfoPose ~= nil then
		return metaInfoPose, componentName, memberName:GetString()
	end
	local metaInfo = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE_COMPONENT)
	if metaInfo == nil or componentName == nil then
		return
	end
	local posePath = "ec/" .. componentName .. "/" .. metaInfo.poseProperty
	local memberInfoPose = pfm.get_member_info(posePath, ent)
	metaInfoPose = memberInfoPose:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
	return metaInfoPose, componentName, metaInfo.poseProperty
end

function pfm.util.get_actor_property_value(actor, memberInfo, propertyPath)
	if memberInfo == nil then
		return
	end
	local componentName, memberName =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath))
	assert(componentName ~= nil)
	local component = actor:FindComponent(componentName)
	assert(component ~= nil)
	return component:GetEffectiveMemberValue(memberInfo.name, memberInfo.type)
end

function pfm.util.get_transform_property_components(ent, memberInfo, propertyPath)
	local posMemberInfo
	local posPropertyPath
	local rotMemberInfo
	local rotPropertyPath
	if pfm.util.is_property_type_positional(memberInfo.type) then
		posMemberInfo = memberInfo
		posPropertyPath = propertyPath
	elseif pfm.util.is_property_type_rotational(memberInfo.type) then
		rotMemberInfo = memberInfo
		rotPropertyPath = propertyPath
	else
		local poseMetaInfo, component = pfm.util.find_property_pose_meta_info(ent, propertyPath)
		if poseMetaInfo == nil then
			pfm.log(
				"Unable to find pose meta info for property '" .. propertyPath .. "'!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
			return
		end
		posPropertyPath = "ec/" .. component .. "/" .. poseMetaInfo.posProperty
		rotPropertyPath = "ec/" .. component .. "/" .. poseMetaInfo.rotProperty
		posMemberInfo = pfm.get_member_info(posPropertyPath, ent)
		rotMemberInfo = pfm.get_member_info(rotPropertyPath, ent)
	end
	return posMemberInfo, posPropertyPath, rotMemberInfo, rotPropertyPath
end

function pfm.util.get_constraint_participant_poses(actor0, propertyPath0, actor1, propertyPath1, isConstrained)
	local ent0 = actor0:FindEntity()
	local memberInfo0 = util.is_valid(ent0) and pfm.get_member_info(propertyPath0, ent0) or nil
	if memberInfo0 == nil then
		return
	end
	local componentName0, memberName0 =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath0))
	local c0 = ent0:GetComponent(componentName0)
	local idx0 = (c0 ~= nil) and c0:GetMemberIndex(memberName0:GetString()) or nil
	if idx0 == nil then
		return
	end

	-- We need to put the property value into parent space
	local ent1 = actor1:FindEntity()
	local memberInfo1 = util.is_valid(ent1) and pfm.get_member_info(propertyPath1, ent1) or nil
	if memberInfo1 == nil then
		pfm.log(
			"Unable to find member info for property '" .. propertyPath1 .. "'!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	local componentName1, memberName1 =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath1))
	local c1 = ent1:GetComponent(componentName1)
	local idx1 = (c1 ~= nil) and c1:GetMemberIndex(memberName1:GetString()) or nil

	local component = actor1:FindComponent(componentName1)
	local parentPose = math.ScaledTransform()
	-- Get parent pose and convert it to world space
	if pfm.util.is_pose_property_type(memberInfo1.type) then
		parentPose = math.ScaledTransform(component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type))
		parentPose = c1:ConvertTransformMemberPoseToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, parentPose)
	elseif pfm.util.is_property_type_positional(memberInfo1.type) then
		local pos = component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type)
		pos = c1:ConvertTransformMemberPosToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, pos)
		parentPose:SetOrigin(pos)
	elseif pfm.util.is_property_type_rotational(memberInfo1.type) then
		local rot = component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type)
		rot = c1:ConvertTransformMemberRotToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, rot)
		parentPose:SetRotation(rot)
	end

	local posMemberInfo, posPropertyPath, rotMemberInfo, rotPropertyPath =
		pfm.util.get_transform_property_components(ent0, memberInfo0, propertyPath0)

	local childPose = math.ScaledTransform()
	local baseValuePos = pfm.util.get_actor_property_value(actor0, posMemberInfo, posPropertyPath)
	local baseValueRot = pfm.util.get_actor_property_value(actor0, rotMemberInfo, rotPropertyPath)
	if baseValuePos ~= nil then
		childPose:SetOrigin(baseValuePos)
	end
	if baseValueRot ~= nil then
		childPose:SetRotation(baseValueRot)
	end

	-- Convert child pose to world space
	if pfm.util.is_pose_property_type(memberInfo0.type) then
		childPose = math.ScaledTransform(
			c0:ConvertTransformMemberPoseToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, childPose)
		)
	elseif pfm.util.is_property_type_positional(memberInfo0.type) then
		local pos = childPose:GetOrigin()
		pos = c0:ConvertTransformMemberPosToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, pos)
		childPose:SetOrigin(pos)
	elseif pfm.util.is_property_type_rotational(memberInfo0.type) then
		local rot = childPose:GetRotation()
		rot = c0:ConvertTransformMemberRotToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, rot)
		childPose:SetRotation(rot)
	end
	if isConstrained then
		childPose = parentPose * childPose
	end

	return parentPose, childPose
end

function gui.PFMActorEditor:AddConstraint(type, actor0, propertyPath0, actor1, propertyPath1, parentCmd)
	local logMsg = "Adding constraint of type '" .. gui.PFMActorEditor.constraint_type_to_name(type) .. "'"
	if actor1 == nil then
		logMsg = logMsg .. " to "
	else
		logMsg = logMsg .. " from "
	end
	logMsg = logMsg .. "property '" .. propertyPath0 .. "' of actor '" .. actor0:GetName()
	if actor1 ~= nil then
		logMsg = logMsg .. "' to property '" .. propertyPath1 .. "' of actor '" .. actor1:GetName() .. "'"
	end
	logMsg = logMsg .. "..."
	self:LogInfo(logMsg)

	local ent0 = actor0:FindEntity()
	local memberInfo0 = util.is_valid(ent0) and pfm.get_member_info(propertyPath0, ent0) or nil
	if memberInfo0 == nil then
		self:LogWarn("Unable to find member info for property '" .. propertyPath0 .. "'!")
		return
	end

	if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT then
		if pfm.util.is_pose_property_type(memberInfo0.type) == false then
			local poseMetaInfo0, poseComponent0, posePropertyName0 =
				pfm.util.find_property_pose_meta_info(ent0, propertyPath0)
			if poseMetaInfo0 == nil then
				self:LogWarn("Unable to find pose meta info for property '" .. propertyPath0 .. "'!")
				return
			end
			return self:AddConstraint(
				type,
				actor0,
				"ec/" .. poseComponent0 .. "/" .. posePropertyName0,
				actor1,
				propertyPath1
			)
		end
	end

	local constraintActorName = "[" .. gui.PFMActorEditor.constraint_type_to_name(type) .. "]"

	if actor1 ~= nil then
		local ent1 = actor1:FindEntity()
		local memberInfo1 = util.is_valid(ent1) and pfm.get_member_info(propertyPath1, ent1) or nil
		if memberInfo1 ~= nil then
			constraintActorName = constraintActorName .. " > " .. actor1:GetName() .. "[" .. memberInfo1.name .. "]"
		end
	end
	local actor = self:CreatePresetActor(type, {
		["updateActorComponents"] = false,
		["name"] = constraintActorName,
	})
	local drivenSpace = math.COORDINATE_SPACE_WORLD
	if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		local coordMetaInfo = memberInfo0:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_COORDINATE)
		if coordMetaInfo ~= nil then
			drivenSpace = coordMetaInfo.space
		end
	end
	local ctC = actor:FindComponent("constraint")
	if ctC ~= nil then
		ctC:SetMemberValue("drivenObject", udm.TYPE_STRING, ents.create_uri(actor0:GetUniqueId(), propertyPath0))
		ctC:SetMemberValue("drivenObjectSpace", udm.TYPE_UINT8, drivenSpace)
		if actor1 ~= nil then
			ctC:SetMemberValue("driver", udm.TYPE_STRING, ents.create_uri(actor1:GetUniqueId(), propertyPath1))
		end

		local componentName, memberName =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath0))
		if componentName == "ik_solver" then
			-- The constraint target is an ik solver property.
			-- The IK solver is also handled as a constraint internally, so we'll have to make sure
			-- our new constraint is executed *before* the IK solver. To do so, we can use the order index.
			ctC:SetMemberValue("orderIndex", udm.TYPE_INT32, -1)
		end
		self:UpdateActorComponents(actor)
	end

	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager == nil then
		self:LogWarn("Animation Manager not found!")
		return
	end

	local cmd = parentCmd or pfm.create_command("composition")
	cmd:AddSubCommand("add_actor", self:GetFilmClip(), { actor })

	local posMemberInfo, posPropertyPath, rotMemberInfo, rotPropertyPath =
		pfm.util.get_transform_property_components(ent0, memberInfo0, propertyPath0)

	-- TODO: Check these for validity
	local componentName0, memberName0 =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath0))
	local c0 = ent0:GetComponent(componentName0)
	local idx0 = (c0 ~= nil) and c0:GetMemberIndex(memberName0:GetString()) or nil

	local idxPos
	if posPropertyPath ~= nil then
		local componentNamePos, memberNamePos =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(posPropertyPath))
		local cPos = ent0:GetComponent(componentNamePos)
		idxPos = (cPos ~= nil) and cPos:GetMemberIndex(memberNamePos:GetString()) or nil
	end

	local idxRot
	if rotPropertyPath ~= nil then
		local componentNameRot, memberNameRot =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(rotPropertyPath))
		local cRot = ent0:GetComponent(componentNameRot)
		idxRot = (cRot ~= nil) and cRot:GetMemberIndex(memberNameRot:GetString()) or nil
	end

	local baseValuePos = pfm.util.get_actor_property_value(actor0, posMemberInfo, posPropertyPath)
	local baseValueRot = pfm.util.get_actor_property_value(actor0, rotMemberInfo, rotPropertyPath)
	local cmdUpdatePose = pfm.create_command("composition")
	if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		local parentPose, childPose =
			pfm.util.get_constraint_participant_poses(actor0, propertyPath0, actor1, propertyPath1)
		-- Put child pose relative to parent pose
		childPose = parentPose:GetInverse() * childPose
		if baseValuePos ~= nil then
			baseValuePos = childPose:GetOrigin()
		end
		if baseValueRot ~= nil then
			baseValueRot = childPose:GetRotation()
		end
		-- Transform the animation channels if they exist
		if posPropertyPath ~= nil then
			cmdUpdatePose:AddSubCommand(
				"transform_animation_channel",
				tostring(actor0:GetUniqueId()),
				posPropertyPath,
				parentPose:GetInverse()
			)
			cmdUpdatePose:AddSubCommand(
				"fit_curve_keyframes_to_animation_curve",
				tostring(actor0:GetUniqueId()),
				posPropertyPath
			)
		end
		if rotPropertyPath ~= nil then
			cmdUpdatePose:AddSubCommand(
				"transform_animation_channel",
				tostring(actor0:GetUniqueId()),
				rotPropertyPath,
				parentPose:GetInverse()
			)
			cmdUpdatePose:AddSubCommand(
				"fit_curve_keyframes_to_animation_curve",
				tostring(actor0:GetUniqueId()),
				rotPropertyPath
			)
		end
	else
		if baseValuePos ~= nil then
			baseValuePos = c0:ConvertTransformMemberPosToTargetSpace(idxPos, math.COORDINATE_SPACE_WORLD, baseValuePos)
		end
		if baseValueRot ~= nil then
			baseValueRot = c0:ConvertTransformMemberRotToTargetSpace(idxRot, math.COORDINATE_SPACE_WORLD, baseValueRot)
		end
	end

	-- Constraints require there to be an animation channel with at least one animation value
	if posMemberInfo ~= nil then
		local pos = baseValuePos
		pos = c0:ConvertPosToMemberSpace(idxPos, drivenSpace, pos)
		pm:MakeActorPropertyAnimated(actor0, posPropertyPath, posMemberInfo.type, true, nil, cmdUpdatePose, pos)
	end
	if rotMemberInfo ~= nil then
		local rot = baseValueRot
		rot = c0:ConvertRotToMemberSpace(idxRot, drivenSpace, rot)
		pm:MakeActorPropertyAnimated(actor0, rotPropertyPath, rotMemberInfo.type, true, nil, cmdUpdatePose, rot)
	end
	cmdUpdatePose:Execute()
	cmd:AddSubCommand(cmdUpdatePose)
	if parentCmd ~= nil then
		return
	end
	pfm.undoredo.push("initialize_constraint", cmd)
end

local function is_constraint_type_applicable(type, memberInfo0, memberInfo1)
	if
		type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE
	then
		return memberInfo1 ~= nil
			and pfm.util.is_property_type_positional(memberInfo0.type)
			and pfm.util.is_property_type_positional(memberInfo1.type)
	elseif
		type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE
	then
		return memberInfo1 == nil and pfm.util.is_property_type_positional(memberInfo0.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION then
		return memberInfo1 == nil and pfm.util.is_property_type_rotational(memberInfo0.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION then
		return memberInfo1 ~= nil
			and pfm.util.is_property_type_rotational(memberInfo0.type)
			and pfm.util.is_property_type_rotational(memberInfo1.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT then
		if memberInfo1 == nil then
			return false
		end
		local metaInfoPoseComponent =
			memberInfo0:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE_COMPONENT)
		return (metaInfoPoseComponent ~= nil or pfm.util.is_pose_property_type(memberInfo0.type))
			and (
				pfm.util.is_property_type_positional(memberInfo1.type)
				or pfm.util.is_pose_property_type(memberInfo1.type)
			)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		if memberInfo1 == nil then
			return false
		end
		if pfm.util.is_property_type_positional(memberInfo0.type) then
			return pfm.util.is_property_type_positional(memberInfo1.type)
				or pfm.util.is_pose_property_type(memberInfo1.type)
		end
		if pfm.util.is_property_type_rotational(memberInfo0.type) then
			return pfm.util.is_property_type_rotational(memberInfo1.type)
				or pfm.util.is_pose_property_type(memberInfo1.type)
		end
		if pfm.util.is_pose_property_type(memberInfo0.type) then
			return pfm.util.is_property_type_positional(memberInfo1.type)
				or pfm.util.is_property_type_rotational(memberInfo1.type)
				or pfm.util.is_pose_property_type(memberInfo1.type)
		end
	end
	return false
end

function pfm.util.find_applicable_constraint_types(memberInfo0, actor1, propertyPath1)
	local t = {}
	if
		pfm.util.is_pose_property_type(memberInfo0.type) == false
		and pfm.util.is_property_type_positional(memberInfo0.type) == false
		and pfm.util.is_property_type_rotational(memberInfo0.type) == false
	then
		return t
	end

	local ent1 = (actor1 ~= nil) and actor1:FindEntity() or nil
	local memberInfo1 = util.is_valid(ent1) and pfm.get_member_info(propertyPath1, ent1) or nil
	if
		memberInfo1 ~= nil
		and pfm.util.is_pose_property_type(memberInfo1.type) == false
		and pfm.util.is_property_type_positional(memberInfo1.type) == false
		and pfm.util.is_property_type_rotational(memberInfo1.type) == false
	then
		return t
	end
	for type = gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_START, gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_END do
		if is_constraint_type_applicable(type, memberInfo0, memberInfo1) then
			table.insert(t, type)
		end
	end
	return t
end
