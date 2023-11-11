--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/element_selection.lua")

local function is_pose_property_type(type)
	return type == udm.TYPE_TRANSFORM or type == udm.TYPE_SCALED_TRANSFORM
end

local function is_property_type_positional(type)
	return udm.is_convertible(type, udm.TYPE_VECTOR3) and udm.is_numeric_type(type) == false and type ~= udm.TYPE_STRING
end

local function is_property_type_rotational(type)
	return type == udm.TYPE_EULER_ANGLES or type == udm.TYPE_QUATERNION
end

local function is_constraint_type_applicable(type, memberInfo0, actor1, propertyPath1)
	local ent1 = actor1:FindEntity()
	local memberInfo1 = util.is_valid(ent1) and pfm.get_member_info(propertyPath1, ent1) or nil
	if
		type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE
	then
		return memberInfo1 ~= nil
			and is_property_type_positional(memberInfo0.type)
			and is_property_type_positional(memberInfo1.type)
	elseif
		type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION
		or type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE
	then
		return memberInfo1 == nil and is_property_type_positional(memberInfo0.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION then
		return memberInfo1 == nil and is_property_type_rotational(memberInfo0.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION then
		return memberInfo1 ~= nil
			and is_property_type_rotational(memberInfo0.type)
			and is_property_type_rotational(memberInfo1.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT then
		return memberInfo1 ~= nil
			and is_pose_property_type(memberInfo0.type)
			and is_property_type_positional(memberInfo1.type)
	elseif type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		if memberInfo1 == nil then
			return false
		end
		if is_property_type_positional(memberInfo0.type) then
			return is_property_type_positional(memberInfo1.type) or is_pose_property_type(memberInfo1.type)
		end
		if is_property_type_rotational(memberInfo0.type) then
			return is_property_type_rotational(memberInfo1.type) or is_pose_property_type(memberInfo1.type)
		end
		if is_pose_property_type(memberInfo0.type) then
			return is_property_type_positional(memberInfo1.type)
				or is_property_type_rotational(memberInfo1.type)
				or is_pose_property_type(memberInfo1.type)
		end
	end
	return false
end

local function get_applicable_constraint_types(memberInfo0, actor1, propertyPath1)
	local t = {}
	for type = gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_START, gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_END do
		if is_constraint_type_applicable(type, memberInfo0, actor1, propertyPath1) then
			table.insert(t, type)
		end
	end
	return t
end

local function find_pose_meta_info(ent, path)
	local memberInfo = pfm.get_member_info(path, ent)
	if memberInfo == nil then
		return
	end
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	local metaInfo = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE_COMPONENT)
	if metaInfo == nil or componentName == nil then
		return
	end
	local posePath = "ec/" .. componentName .. "/" .. metaInfo.poseProperty
	local memberInfoPose = pfm.get_member_info(posePath, ent)
	local metaInfoPose = memberInfoPose:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
	return metaInfoPose, componentName, metaInfo.poseProperty
end

function gui.PFMActorEditor:AddConstraint(type, actor0, propertyPath0, actor1, propertyPath1)
	local ent0 = actor0:FindEntity()
	local memberInfo0 = util.is_valid(ent0) and pfm.get_member_info(propertyPath0, ent0) or nil
	if memberInfo0 == nil then
		return
	end
	local actor = self:CreatePresetActor(type, {
		["updateActorComponents"] = false,
	})
	local ctC = actor:FindComponent("constraint")
	if ctC ~= nil then
		ctC:SetMemberValue("drivenObject", udm.TYPE_STRING, ents.create_uri(actor0:GetUniqueId(), propertyPath0))
		if actor1 ~= nil then
			ctC:SetMemberValue("driver", udm.TYPE_STRING, ents.create_uri(actor1:GetUniqueId(), propertyPath1))
		end
		self:UpdateActorComponents(actor)
	end

	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager == nil then
		return
	end

	local cmd = pfm.create_command("composition")

	local posMemberInfo
	local posPropertyPath
	local rotMemberInfo
	local rotPropertyPath
	if is_property_type_positional(memberInfo0.type) then
		posMemberInfo = memberInfo0
		posPropertyPath = propertyPath0
	elseif is_property_type_rotational(memberInfo0.type) then
		rotMemberInfo = memberInfo0
		rotPropertyPath = propertyPath0
	else
		local poseMetaInfo = find_pose_meta_info(ent0, propertyPath0)
		if poseMetaInfo == nil then
			return
		end
		posPropertyPath = poseMetaInfo.posProperty
		rotPropertyPath = poseMetaInfo.rotProperty
		posMemberInfo = pfm.get_member_info(poseMetaInfo.posProperty, ent0)
		rotMemberInfo = pfm.get_member_info(poseMetaInfo.rotProperty, ent0)
	end

	local baseValuePos
	if posMemberInfo ~= nil then
		local componentName, memberName =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(posPropertyPath))
		assert(componentName ~= nil)
		local component = actor0:FindComponent(componentName)
		assert(component ~= nil)
		baseValuePos = component:GetEffectiveMemberValue(posMemberInfo.name, posMemberInfo.type)
		assert(baseValuePos ~= nil)
	end
	local baseValueRot
	if rotMemberInfo ~= nil then
		local componentName, memberName =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(rotPropertyPath))
		assert(componentName ~= nil)
		local component = actor0:FindComponent(componentName)
		assert(component ~= nil)
		baseValueRot = component:GetEffectiveMemberValue(rotMemberInfo.name, rotMemberInfo.type)
		assert(baseValueRot ~= nil)
	end

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

	if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		-- We need to put the property value into parent space
		local ent1 = actor1:FindEntity()
		local memberInfo1 = util.is_valid(ent1) and pfm.get_member_info(propertyPath1, ent1) or nil
		if memberInfo1 == nil then
			return
		end

		local componentName1, memberName1 =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(propertyPath1))
		local c1 = ent1:GetComponent(componentName1)
		local idx1 = (c1 ~= nil) and c1:GetMemberIndex(memberName1:GetString()) or nil

		local component = actor1:FindComponent(componentName1)
		local parentPose = math.ScaledTransform()
		-- Get parent pose and convert it to world space
		if is_pose_property_type(memberInfo1.type) then
			parentPose = component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type)
			parentPose = c1:ConvertTransformMemberPoseToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, parentPose)
		elseif is_property_type_positional(memberInfo1.type) then
			local pos = component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type)
			pos = c1:ConvertTransformMemberPosToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, pos)
			parentPose:SetOrigin(pos)
		elseif is_property_type_rotational(memberInfo1.type) then
			local rot = component:GetEffectiveMemberValue(memberInfo1.name, memberInfo1.type)
			rot = c1:ConvertTransformMemberRotToTargetSpace(idx1, math.COORDINATE_SPACE_WORLD, rot)
			parentPose:SetRotation(rot)
		end

		local childPose = math.ScaledTransform()
		if baseValuePos ~= nil then
			childPose:SetOrigin(baseValuePos)
		end
		if baseValueRot ~= nil then
			childPose:SetRotation(baseValueRot)
		end

		-- Convert child pose to world space
		if is_pose_property_type(memberInfo0.type) then
			childPose = c0:ConvertTransformMemberPoseToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, childPose)
		elseif is_property_type_positional(memberInfo0.type) then
			local pos = childPose:GetOrigin()
			pos = c0:ConvertTransformMemberPosToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, pos)
			childPose:SetOrigin(pos)
		elseif is_property_type_rotational(memberInfo0.type) then
			local rot = childPose:GetRotation()
			rot = c0:ConvertTransformMemberRotToTargetSpace(idx0, math.COORDINATE_SPACE_WORLD, rot)
			childPose:SetRotation(rot)
		end

		-- Put child pose relative to parent pose
		childPose = parentPose:GetInverse() * childPose
		if baseValuePos ~= nil then
			baseValuePos = childPose:GetOrigin()
		end
		if baseValueRot ~= nil then
			baseValueRot = childPose:GetRotation()
		end
	end

	-- Constraints require there to be an animation channel with at least one animation value
	if posMemberInfo ~= nil then
		local pos = baseValuePos
		pos = c0:ConvertPosToMemberSpace(idxPos, math.COORDINATE_SPACE_WORLD, pos)
		pm:MakeActorPropertyAnimated(actor0, posPropertyPath, posMemberInfo.type, true, nil, cmd, pos)
	end
	if rotMemberInfo ~= nil then
		local rot = baseValueRot
		rot = c0:ConvertRotToMemberSpace(idxRot, math.COORDINATE_SPACE_WORLD, rot)
		pm:MakeActorPropertyAnimated(actor0, rotPropertyPath, rotMemberInfo.type, true, nil, cmd, rot)
	end
	pfm.undoredo.push("initialize_constraint", cmd)()
end

function gui.PFMActorEditor:StartConstraintDragAndDropMode(elItem, actor, propertyPath)
	propertyPath = propertyPath or "ec/pfm_actor/pose"
	self:EndConstraintDragAndDropMode()
	self.m_constraintDragAndDropItems = {}

	if propertyPath == nil then
		return
	end

	local ent = actor:FindEntity()
	local memberInfo = util.is_valid(ent) and pfm.get_member_info(propertyPath, ent) or nil
	if
		memberInfo == nil
		or (
			is_pose_property_type(memberInfo.type) == false
			and is_property_type_positional(memberInfo.type) == false
			and is_property_type_rotational(memberInfo.type) == false
		)
	then
		return
	end

	local elItemHeader = elItem:GetHeader()

	local p = gui.create("WIDragGhost")
	p:SetTargetElement(elItemHeader, elItemHeader:GetCursorPos(), "Constraint")
	table.insert(self.m_constraintDragAndDropItems, p)

	local callbacks = self.m_constraintDragAndDropItems
	local function initialize_drag()
		local elOutline = gui.create("WIElementSelectionOutline", self)
		table.insert(self.m_constraintDragAndDropItems, elOutline)
		elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MAJOR)
		elOutline:SetTargetElement({ elItemHeader })
		elOutline:Update()

		local tItems = {}
		local dropped = false
		table.insert(
			callbacks,
			p:AddEventListener("OnHoverElement", function(p, el)
				if tItems[el] ~= nil then
					return true
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragTargetHoverStart", function(p, el)
				local elOutline = tItems[el]
				elOutline = (elOutline ~= nil) and elOutline.outline or nil
				if util.is_valid(elOutline) then
					elOutline:SetFilledIn(Color(255, 255, 255, 60))
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragTargetHoverStop", function(p, el)
				if dropped then
					return
				end
				local elOutline = tItems[el]
				elOutline = (elOutline ~= nil) and elOutline.outline or nil
				if util.is_valid(elOutline) then
					elOutline:SetFilledIn(false)
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragDropped", function(p, el)
				local elData = tItems[el]
				if elData == nil then
					return
				end
				local pContext = gui.open_context_menu()
				if util.is_valid(pContext) == false then
					return
				end
				pContext:SetPos(input.get_cursor_pos())

				for _, type in ipairs(elData.constraintTypes) do
					local name = gui.PFMActorEditor.constraint_type_to_name(type)
					name = locale.get_text("c_constraint_" .. name)
					name = locale.get_text("pfm_add_constraint_type", { name })
					pContext:AddItem(name, function()
						if self:IsValid() then
							local actor1 = (elData.actorUuid ~= nil) and pfm.dereference(elData.actorUuid) or nil
							self:AddConstraint(type, actor, propertyPath, actor1, elData.propertyPath)
						end
					end)
				end
				pContext:Update()
				dropped = true
				for elHeader, elDataItem in pairs(tItems) do
					if elDataItem ~= elData then
						util.remove(elDataItem.outline)
					end
				end
				elData.outline:SetFilledIn(Color(255, 255, 255, 60))
				pContext:AddEventListener("OnRemove", function()
					if self:IsValid() then
						self:EndConstraintDragAndDropMode()
					end
				end)
				return util.EVENT_REPLY_HANDLED
			end)
		)
		table.insert(
			callbacks,
			elItemHeader:AddEventListener("OnDragStopped", function()
				if self:IsValid() then
					if dropped == false then
						self:EndConstraintDragAndDropMode()
					end
				end
			end)
		)

		for _, item in ipairs(self:GetActorItems()) do
			if item:IsValid() then
				local uuid = item:GetName()
				local actor = pfm.dereference(uuid)
				if actor ~= nil then
					local componentItems = self:GetActorComponentItems(actor)
					for _, cItem in ipairs(componentItems) do
						if cItem:IsValid() then
							local componentType = cItem:GetName()
							local propertyItems = self:GetPropertyEntries(uuid, componentType)
							for _, propItem in ipairs(propertyItems) do
								if propItem:IsValid() then
									local header = propItem:GetHeader()
									if util.is_valid(header) and propItem ~= elItem then
										local itemPropertyPath = propItem:GetIdentifier()
										local t = get_applicable_constraint_types(memberInfo, actor, itemPropertyPath)
										if #t > 0 then
											local elOutline = gui.create("WIElementSelectionOutline", self)
											table.insert(self.m_constraintDragAndDropItems, elOutline)
											elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MEDIUM)
											elOutline:SetTargetElement({ header })
											elOutline:Update()
											tItems[header] = {
												outline = elOutline,
												constraintTypes = t,
												actorUuid = uuid,
												propertyPath = itemPropertyPath,
											}
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	table.insert(
		callbacks,
		p:AddEventListener("OnDragStarted", function()
			if self:IsValid() then
				initialize_drag()
			end
		end)
	)
end

function gui.PFMActorEditor:EndConstraintDragAndDropMode()
	util.remove(self.m_constraintDragAndDropItems or {})
	self.m_constraintDragAndDropItems = nil
end
