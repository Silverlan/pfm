--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/util_rig_helper.lua")

local Element = gui.IkRigEditor
function Element:RemoveConstraint(constraint)
	self.m_ikRig:RemoveConstraint(constraint)

	local item = self:GetConstraintItem(constraint)
	if item ~= nil then
		local parent = item:GetParentItem()
		item:RemoveSafely()
		if util.is_valid(parent) then
			parent:ScheduleUpdate()
		end
	end

	if self:IsMirrored() then
		local mirrorConstraint = self:DetermineMirroredBoneSiblingConstraint(constraint)
		if mirrorConstraint ~= nil then
			self:SetMirrored(false)
			self:RemoveConstraint(mirrorConstraint)
			self:SetMirrored(true)
			return
		end
	end
	self:ScheduleReloadIkRig()
end
function Element:DetermineMirroredBoneSiblingConstraint(constraint)
	local bone = constraint.bone1
	local sibling = self:DetermineMirroredBoneSibling(bone)
	if sibling == nil then
		return
	end
	local siblingConstraint
	for _, c in ipairs(self.m_ikRig:GetConstraints()) do
		if c.bone1 == sibling and c.type == constraint.type then
			siblingConstraint = c
			break
		end
	end
	return siblingConstraint
end
function Element:GetMirroredBoneSiblingConstraintControl(constraint, controlName)
	local mirrorConstraint = self:DetermineMirroredBoneSiblingConstraint(constraint)
	if mirrorConstraint == nil then
		return
	end
	return self:GetConstraintControl(mirrorConstraint, controlName)
end
function Element:GetConstraintItem(constraint)
	local item = self:FindBoneItem(constraint.bone1)
	for _, child in ipairs(item:GetItems()) do
		if child:IsValid() and child.__jointType == constraint.type then
			return child
		end
	end
end
function Element:GetConstraintControl(constraint, controlName)
	local item = self:FindBoneItem(constraint.bone1)
	for _, child in ipairs(item:GetItems()) do
		if child:IsValid() and child.__jointType == constraint.type then
			return child.__sliders[controlName]
		end
	end
end
function Element:ShouldFlipAxis(boneName, axis)
	local ent = self.m_modelView:GetEntity(1)
	if util.is_valid(ent) == false then
		return false
	end
	local mdl = ent:GetModel()
	if mdl == nil then
		return false
	end
	local mirrorName = self:DetermineMirroredBoneSibling(boneName)
	if mirrorName == nil then
		return false
	end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(boneName)
	local mirrorBoneId = skel:LookupBone(mirrorName)
	if boneId == -1 or mirrorBoneId == -1 then
		return false
	end
	local flipFactors = util.rig.determine_mirrored_bone_flip_factors(mdl, boneName, mirrorName)
	if flipFactors == nil then
		return false
	end
	return (flipFactors:Get(axis) < 0.0) and true or false
end
function Element:AddConstraint(item, boneName, type)
	local ent = self.m_modelView:GetEntity(1)
	if util.is_valid(ent) == false then
		return
	end
	local mdl = ent:GetModel()
	if mdl == nil then
		return
	end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(boneName)
	local bone = skel:GetBone(boneId)
	local parent = bone:GetParent()
	self:AddBone(boneName)
	self:AddBone(parent:GetName())

	local constraint
	local child = item:AddItem(locale.get_text("pfm_" .. string.camel_case_to_snake_case(type) .. "_constraint"))
	child:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) then
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem("Remove", function()
					self:RemoveConstraint(constraint)
				end)
				pContext:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)
	local icon = child:AddIcon("gui/pfm/icon_item_visible_off")
	local visualize = false
	icon:SetMouseInputEnabled(true)
	icon:SetCursor(gui.CURSOR_SHAPE_HAND)
	icon:SetTooltip(locale.get_text("pfm_rig_editor_visualize_constraint"))
	local function toggle_constraint_visualization()
		if visualize then
			visualize = false
			icon:SetMaterial("gui/pfm/icon_item_visible_off")
			child.__visualizationEnabled = visualize
			self:ScheduleUpdateDebugVisualization()
		else
			visualize = true
			icon:SetMaterial("gui/pfm/icon_item_visible_on")
			child.__visualizationEnabled = visualize
			self:ScheduleUpdateDebugVisualization()
		end
	end
	icon:AddCallback("OnMouseEvent", function(icon, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			toggle_constraint_visualization()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	local ctrlsParent = child:AddItem("")
	local ctrl = gui.create("WIPFMControlsMenu", ctrlsParent, 0, 0, ctrlsParent:GetWidth(), ctrlsParent:GetHeight())
	ctrl:SetAutoAlignToParent(true, false)
	ctrl:SetAutoFillContentsToHeight(false)

	local singleAxis
	local minLimits, maxLimits
	local useUnidirectionalSpan = false
	local includeUnidirectionalLimit = false
	local twistAxis = math.AXIS_Z
	if type == "ballSocket" then
		twistAxis = mdl:FindBoneTwistAxis(boneId) or twistAxis
	end
	local function add_rotation_axis_slider(ctrl, name, id, axisId, min, defVal)
		return ctrl:AddSliderControl(locale.get_text(name), id, defVal, -180.0, 180.0, function(el, value)
			local animatedC = ent:GetComponent(ents.COMPONENT_ANIMATED)
			if animatedC ~= nil then
				local ref = mdl:GetReferencePose()
				local pose = ref:GetBonePose(parent:GetID()):GetInverse() * ref:GetBonePose(boneId)
				local rot = pose:GetRotation()
				local tAxisId = singleAxis or axisId
				local localRot = EulerAngles()
				localRot:Set(tAxisId, value)
				if useUnidirectionalSpan then
					if includeUnidirectionalLimit then
						if min then
							localRot = minLimits
						else
							localRot = maxLimits
						end
					else
						localRot = (minLimits + maxLimits) * 0.5
					end
				end
				localRot = localRot:ToQuaternion()

				rot = rot * localRot
				pose:SetRotation(rot)
				-- ent:RemoveComponent(ents.COMPONENT_IK_SOLVER)
				-- ent:RemoveComponent(ents.COMPONENT_PFM_FBIK)

				if self.m_dontClearAnimCallbacks ~= true then
					util.remove(self.m_cbOnAnimsUpdated)
					self.m_cbOnAnimsUpdated = {}
				end
				table.insert(
					self.m_cbOnAnimsUpdated,
					ent:GetComponent(ents.COMPONENT_ANIMATED)
						:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED, function()
							animatedC:SetBonePose(boneId, pose)
						end)
				)

				self.m_mdlView:Render()

				if min then
					minLimits:Set(singleAxis and 0 or tAxisId, value)
				else
					maxLimits:Set(singleAxis and 0 or tAxisId, value)
				end
				constraint.minLimits = minLimits
				constraint.maxLimits = maxLimits

				self:ScheduleUpdateDebugVisualization()

				local fbIk = ent:GetComponent(ents.COMPONENT_PFM_FBIK)
				if fbIk ~= nil then
					fbIk:SetEnabled(false)
				end
			end
		end, 1.0)
	end

	local getDefaultLimits = function()
		local limits = EulerAngles(45, 45, 45)
		-- Set the rotation around the twist axis to -1/1
		if twistAxis == math.AXIS_X or twistAxis == math.AXIS_SIGNED_X then
			limits.y = 1
		elseif twistAxis == math.AXIS_Y or twistAxis == math.AXIS_SIGNED_Y then
			limits.p = 1
		else
			limits.r = 1
		end
		return limits
	end

	pfm.log(
		"Adding "
			.. type
			.. " constraint from bone '"
			.. parent:GetName()
			.. "' to '"
			.. bone:GetName()
			.. "' of actor with model '"
			.. mdl:GetName()
			.. "'...",
		pfm.LOG_CATEGORY_PFM
	)
	if type == "fixed" then
		constraint = self.m_ikRig:AddFixedConstraint(parent:GetName(), bone:GetName())
	elseif type == "hinge" then
		constraint = self.m_ikRig:AddHingeConstraint(parent:GetName(), bone:GetName(), -45.0, 45.0, Quaternion())
	elseif type == "ballSocket" then
		local limits = getDefaultLimits()
		constraint = self.m_ikRig:AddBallSocketConstraint(parent:GetName(), bone:GetName(), -limits, limits)
	end

	child.__jointType = constraint.type
	minLimits = constraint.minLimits
	maxLimits = constraint.maxLimits

	local function add_rotation_axis(ctrl, name, axisId, defMin, defMax)
		local minSlider =
			add_rotation_axis_slider(ctrl, "pfm_ik_rot_" .. name .. "_min", name .. "_min", axisId, true, defMin)
		local maxSlider =
			add_rotation_axis_slider(ctrl, "pfm_ik_rot_" .. name .. "_max", name .. "_max", axisId, false, defMax)
		return minSlider, maxSlider
	end
	child.__sliders = {}
	if type == "ballSocket" then
		local minP, maxP
		local minY, maxY
		local minR, maxR

		local axes
		local function update_axes()
			if twistAxis == math.AXIS_X or twistAxis == math.AXIS_SIGNED_X then
				axes = { math.AXIS_Z, math.AXIS_X, math.AXIS_Y }
			elseif twistAxis == math.AXIS_Y or twistAxis == math.AXIS_SIGNED_Y then
				axes = { math.AXIS_Z, math.AXIS_Y, math.AXIS_X }
			else
				axes = { math.AXIS_X, math.AXIS_Y, math.AXIS_Z }
			end
			local limits = getDefaultLimits()
			minP:SetValue(-limits.p)
			maxP:SetValue(limits.p)
			minY:SetValue(-limits.y)
			maxY:SetValue(limits.y)
			minR:SetValue(-limits.r)
			maxR:SetValue(limits.r)
		end

		local axisMenu
		axisMenu = ctrl:AddDropDownMenu(
			locale.get_text("pfm_ik_twist_axis"),
			"twist_axis",
			{
				{ tostring(math.AXIS_X), "X" },
				{ tostring(math.AXIS_Y), "Y" },
				{ tostring(math.AXIS_Z), "Z" },
				{ tostring(math.AXIS_SIGNED_X), "-X" },
				{ tostring(math.AXIS_SIGNED_Y), "-Y" },
				{ tostring(math.AXIS_SIGNED_Z), "-Z" },
			},
			twistAxis,
			function(el, option)
				local axis = el:GetOptionValue(el:GetSelectedOption())
				twistAxis = tonumber(axis)
				constraint.axis = twistAxis
				update_axes()
				self:ScheduleUpdateDebugVisualization()

				if self:IsMirrored() then
					local mirrorAxisMenu = self:GetMirroredBoneSiblingConstraintControl(constraint, "axis")
					if util.is_valid(mirrorAxisMenu) then
						self:SetMirrored(false)
						mirrorAxisMenu:SelectOption(axisMenu:GetSelectedOption())
						self:SetMirrored(true)
					end
				end
			end
		)
		child.__sliders["axis"] = axisMenu

		local subSeparate
		--[[local subUnidirectional
		local unidirectionalSwingSpan = ((math.abs(maxLimits:Get(axes[1]) -minLimits:Get(axes[1])) -math.abs(maxLimits:Get(axes[2]) -minLimits:Get(axes[2]))) < 0.01)
		ctrl:AddToggleControl(locale.get_text("pfm_ik_unidirectional_span_limit"),"unidirectional_span_limit",unidirectionalSwingSpan,function(el,checked)
			subSeparate:SetVisible(not checked)
			subUnidirectional:SetVisible(checked)
			ctrl:Update()
			ctrl:SizeToContents()

			useUnidirectionalSpan = checked
		end)]]
		subSeparate = ctrl:AddSubMenu("rotation_axes")
		--subUnidirectional = ctrl:AddSubMenu()

		minP, maxP = add_rotation_axis(subSeparate, "pitch", 0, minLimits.p, maxLimits.p)
		minY, maxY = add_rotation_axis(subSeparate, "yaw", 1, minLimits.y, maxLimits.y)
		minR, maxR = add_rotation_axis(subSeparate, "roll", 2, minLimits.r, maxLimits.r)
		local pairs = {
			{ { "p_min", minP }, { "p_max", maxP } },
			{ { "y_min", minY }, { "y_max", maxY } },
			{ { "r_min", minR }, { "r_max", maxR } },
		}

		for i, pdata in ipairs(pairs) do
			local minId = pdata[1][1]
			local minEl = pdata[1][2]
			local maxId = pdata[2][1]
			local maxEl = pdata[2][2]
			child.__sliders[minId] = minEl
			child.__sliders[maxId] = maxEl
			minEl:AddCallback("OnLeftValueChanged", function(el, value)
				if input.is_shift_key_down() then
					maxEl:SetValue(-minEl:GetValue())
				end

				if self:IsMirrored() then
					local flipAxis = self:ShouldFlipAxis(constraint.bone1, axes[i])
					local flipFactor = flipAxis and -1.0 or 1.0
					local mirrorSlider =
						self:GetMirroredBoneSiblingConstraintControl(constraint, flipAxis and maxId or minId)
					if util.is_valid(mirrorSlider) then
						self:SetMirrored(false)
						self.m_dontClearAnimCallbacks = true
						mirrorSlider:SetValue(value * flipFactor)
						self.m_dontClearAnimCallbacks = nil
						self:SetMirrored(true)
					end
				end
			end)
			maxEl:AddCallback("OnLeftValueChanged", function(el, value)
				if input.is_shift_key_down() then
					minEl:SetValue(-maxEl:GetValue())
				end

				if self:IsMirrored() then
					local flipAxis = self:ShouldFlipAxis(constraint.bone1, axes[i])
					local flipFactor = flipAxis and -1.0 or 1.0
					local mirrorSlider =
						self:GetMirroredBoneSiblingConstraintControl(constraint, flipAxis and minId or maxId)
					if util.is_valid(mirrorSlider) then
						self:SetMirrored(false)
						self.m_dontClearAnimCallbacks = true
						mirrorSlider:SetValue(value * flipFactor)
						self.m_dontClearAnimCallbacks = nil
						self:SetMirrored(true)
					end
				end
			end)
		end
		update_axes()

		--[[local function get_min_slider(axis)
			if(axis == math.AXIS_X) then return minP end
			if(axis == math.AXIS_Y) then return minY end
			if(axis == math.AXIS_Z) then return minR end
		end
		local function get_max_slider(axis)
			if(axis == math.AXIS_X) then return maxP end
			if(axis == math.AXIS_Y) then return maxY end
			if(axis == math.AXIS_Z) then return maxR end
		end

		local xOffset,yOffset,spanLimit,twistLimit

		local function update_x_span(includeUniLimit)
			if(includeUniLimit == nil) then includeUniLimit = false end
			local xOffsetVal = xOffset:GetValue()
			local spanLimitVal = spanLimit:GetValue()
			local min = xOffsetVal -spanLimitVal *0.5
			local max = xOffsetVal +spanLimitVal *0.5
			includeUnidirectionalLimit = includeUniLimit
			get_min_slider(axes[1]):SetValue(min)
			includeUnidirectionalLimit = includeUniLimit
			get_max_slider(axes[1]):SetValue(max)
		end
		local function update_y_span(includeUniLimit)
			if(includeUniLimit == nil) then includeUniLimit = false end
			local yOffsetVal = yOffset:GetValue()
			local spanLimitVal = spanLimit:GetValue()
			local min = yOffsetVal -spanLimitVal *0.5
			local max = yOffsetVal +spanLimitVal *0.5
			includeUnidirectionalLimit = includeUniLimit
			get_min_slider(axes[2]):SetValue(min)
			includeUnidirectionalLimit = includeUniLimit
			get_max_slider(axes[2]):SetValue(max)
		end
		local function update_twist_span()
			get_min_slider(axes[3]):SetValue(-twistLimit:GetValue())
			get_max_slider(axes[3]):SetValue(twistLimit:GetValue())
		end

		xOffset = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_x_offset"),"rot_x_offset",0,-180.0,180.0,function(el,value)
			update_x_span()
		end)
		yOffset = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_y_offset"),"rot_y_offset",0,-180.0,180.0,function(el,value)
			update_y_span()
		end)
		twistLimit = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_twist_limit"),"rot_twist_limit",0.5,-90.0,90.0,function(el,value)
			update_twist_span()
		end)
		spanLimit = subUnidirectional:AddSliderControl(locale.get_text("pfm_ik_rot_span_limit"),"rot_span_limit",90,0.0,90.0,function(el,value)
			update_x_span(true)
			update_y_span(true)
		end)

		subUnidirectional:Update()
		subUnidirectional:SizeToContents()]]
		subSeparate:Update()
		subSeparate:SizeToContents()
	elseif type == "hinge" then
		singleAxis = singleAxis or 0
		local axisMenu
		axisMenu = ctrl:AddDropDownMenu(
			locale.get_text("pfm_ik_axis"),
			"axis",
			{
				{ "x", "X" },
				{ "y", "Y" },
				{ "z", "Z" },
			},
			singleAxis,
			function(el, option)
				singleAxis = el:GetSelectedOption()
				constraint.axis = singleAxis
				self:ScheduleUpdateDebugVisualization()

				if self:IsMirrored() then
					local mirrorAxisMenu = self:GetMirroredBoneSiblingConstraintControl(constraint, "axis")
					if util.is_valid(mirrorAxisMenu) then
						self:SetMirrored(false)
						mirrorAxisMenu:SelectOption(axisMenu:GetSelectedOption())
						self:SetMirrored(true)
					end
				end
			end
		)
		local angleSliderMin, angleSliderMax = add_rotation_axis(ctrl, "angle", nil, minLimits.p, maxLimits.p)
		child.__sliders["axis"] = axisMenu
		child.__sliders["minAngle"] = angleSliderMin
		child.__sliders["maxAngle"] = angleSliderMax
		angleSliderMin:AddCallback("OnLeftValueChanged", function(el, value)
			if self:IsMirrored() then
				local flipAxis = self:ShouldFlipAxis(constraint.bone1, singleAxis)
				local flipFactor = flipAxis and -1.0 or 1.0
				local mirrorMinAngle =
					self:GetMirroredBoneSiblingConstraintControl(constraint, flipAxis and "maxAngle" or "minAngle")
				if util.is_valid(mirrorMinAngle) then
					self:SetMirrored(false)
					self.m_dontClearAnimCallbacks = true
					mirrorMinAngle:SetValue(value * flipFactor)
					self.m_dontClearAnimCallbacks = nil
					self:SetMirrored(true)
				end
			end
		end)
		angleSliderMax:AddCallback("OnLeftValueChanged", function(el, value)
			if self:IsMirrored() then
				local flipAxis = self:ShouldFlipAxis(constraint.bone1, singleAxis)
				local flipFactor = flipAxis and -1.0 or 1.0
				local mirrorMaxAngle =
					self:GetMirroredBoneSiblingConstraintControl(constraint, flipAxis and "minAngle" or "maxAngle")
				if util.is_valid(mirrorMaxAngle) then
					self:SetMirrored(false)
					self.m_dontClearAnimCallbacks = true
					mirrorMaxAngle:SetValue(value * flipFactor)
					self.m_dontClearAnimCallbacks = nil
					self:SetMirrored(true)
				end
			end
		end)
	end
	ctrl:ResetControls()
	ctrl:Update()
	ctrl:SizeToContents()

	self:ScheduleReloadIkRig()
	toggle_constraint_visualization()
	item:Expand()
	child:ExpandAll()

	if self:IsMirrored() then
		local mirrorName = self:DetermineMirroredBoneSibling(boneName)
		local mirrorItem = (mirrorName ~= nil) and self:FindBoneItem(mirrorName) or nil
		if mirrorItem ~= nil then
			self:SetMirrored(false)
			self:AddConstraint(mirrorItem, mirrorName, type, nil, false)
			self:SetMirrored(true)
		end
	end

	return constraint, ctrl
end
function Element:AddBallSocketConstraint(item, boneName, c)
	return self:AddConstraint(item, boneName, "ballSocket", c)
end
function Element:AddHingeConstraint(item, boneName, c)
	return self:AddConstraint(item, boneName, "hinge", c)
end
function Element:AddFixedConstraint(item, boneName, c)
	return self:AddConstraint(item, boneName, "fixed", c)
end
