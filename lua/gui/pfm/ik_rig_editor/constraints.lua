--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.IkRigEditor
function Element:AddConstraint(item,boneName,type,constraint)
	local ent = self.m_modelView:GetEntity(1)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(boneName)
	local bone = skel:GetBone(boneId)
	local parent = bone:GetParent()
	self:AddBone(boneName)
	self:AddBone(parent:GetName())

	local child = item:AddItem(locale.get_text("pfm_" .. string.camel_case_to_snake_case(type) .. "_constraint"))
	child:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext)) then
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem("Remove",function()
					self.m_ikRig:RemoveConstraint(constraint)
					child:RemoveSafely()
					item:ScheduleUpdate()
					self:ReloadIkRig()
				end)
				pContext:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)
	child.__jointType = type
	local icon = child:AddIcon("gui/pfm/icon_item_visible_off")
	local visualize = false
	icon:SetMouseInputEnabled(true)
	icon:SetCursor(gui.CURSOR_SHAPE_HAND)
	icon:SetTooltip(locale.get_text("pfm_rig_editor_visualize_constraint"))
	icon:AddCallback("OnMouseEvent",function(icon,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
			if(visualize) then
				visualize = false
				icon:SetMaterial("gui/pfm/icon_item_visible_off")
				child.__visualizationEnabled = visualize
				self:UpdateDebugVisualization()
			else
				visualize = true
				icon:SetMaterial("gui/pfm/icon_item_visible_on")
				child.__visualizationEnabled = visualize
				self:UpdateDebugVisualization()
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	local ctrlsParent = child:AddItem("")
	local ctrl = gui.create("WIPFMControlsMenu",ctrlsParent,0,0,ctrlsParent:GetWidth(),ctrlsParent:GetHeight())
	ctrl:SetAutoAlignToParent(true,false)
	ctrl:SetAutoFillContentsToHeight(false)

	local singleAxis
	local minLimits,maxLimits
	local useUnidirectionalSpan = false
	local includeUnidirectionalLimit = false
	local twistAxis = math.AXIS_Z
	if(type == "ballSocket") then twistAxis = ents.IkSolverComponent.find_forward_axis(mdl,parent:GetID(),boneId) or twistAxis end
	local function add_rotation_axis_slider(ctrl,name,id,axisId,min,defVal)
		return ctrl:AddSliderControl(locale.get_text(name),id,defVal,-180.0,180.0,function(el,value)
			local animatedC = ent:GetComponent(ents.COMPONENT_ANIMATED)
			if(animatedC ~= nil) then
				local ref = mdl:GetReferencePose()
				local pose = ref:GetBonePose(parent:GetID()):GetInverse() *ref:GetBonePose(boneId)
				local rot = pose:GetRotation()
				local tAxisId = singleAxis or axisId
				local localRot = EulerAngles()
				localRot:Set(tAxisId,value)
				if(useUnidirectionalSpan) then
					if(includeUnidirectionalLimit) then
						if(min) then localRot = minLimits
						else localRot = maxLimits end
					else
						localRot = (minLimits +maxLimits) *0.5
					end
				end

				if(twistAxis == math.AXIS_X) then
					localRot = EulerAngles(localRot.y,localRot.r,localRot.p)
				elseif(twistAxis == math.AXIS_Y) then
					localRot = EulerAngles(localRot.r,localRot.p,localRot.y)
				elseif(twistAxis == math.AXIS_Z) then
					
				end
				localRot = localRot:ToQuaternion()

				rot = rot *localRot
				pose:SetRotation(rot)
				-- ent:RemoveComponent(ents.COMPONENT_IK_SOLVER)
				-- ent:RemoveComponent(ents.COMPONENT_PFM_FBIK)

				util.remove(self.m_cbOnAnimsUpdated)
				self.m_cbOnAnimsUpdated = ent:GetComponent(ents.COMPONENT_ANIMATED):AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
					animatedC:SetBonePose(boneId,pose)
				end)

				self.m_mdlView:Render()

				if(min) then minLimits:Set(singleAxis and 0 or tAxisId,value)
				else maxLimits:Set(singleAxis and 0 or tAxisId,value) end
				constraint.minLimits = minLimits
				constraint.maxLimits = maxLimits

				self:UpdateDebugVisualization()
			end
		end,1.0)
	end

	local getDefaultLimits
	if(constraint == nil) then
		pfm.log("Adding " .. type .. " constraint from bone '" .. parent:GetName() .. "' to '" .. bone:GetName() .. "' of actor with model '" .. mdl:GetName() .. "'...",pfm.LOG_CATEGORY_PFM)
		if(type == "fixed") then constraint = self.m_ikRig:AddFixedConstraint(parent:GetName(),bone:GetName())
		elseif(type == "hinge") then constraint = self.m_ikRig:AddHingeConstraint(parent:GetName(),bone:GetName(),-45.0,45.0,Quaternion())
		elseif(type == "ballSocket") then
			getDefaultLimits = function()
				local limits = EulerAngles(45,45,45)
				-- Set the rotation around the twist axis to -1/1
				if(twistAxis == math.AXIS_X) then
					limits.y = 1
				elseif(twistAxis == math.AXIS_Y) then
					limits.p = 1
				else
					limits.r = 1
				end
				return limits
			end
			local limits = getDefaultLimits()
			constraint = self.m_ikRig:AddBallSocketConstraint(parent:GetName(),bone:GetName(),-limits,limits)
		end
	end
	minLimits = constraint.minLimits
	maxLimits = constraint.maxLimits

	local function add_rotation_axis(ctrl,name,axisId,defMin,defMax)
		local minSlider = add_rotation_axis_slider(ctrl,"pfm_ik_rot_" .. name .. "_min",name .. " min",axisId,true,defMin)
		local maxSlider = add_rotation_axis_slider(ctrl,"pfm_ik_rot_" .. name .. "_max",name .. " max",axisId,false,defMax)
		return minSlider,maxSlider
	end
	if(type == "ballSocket") then
		local minP,maxP
		local minY,maxY
		local minR,maxR

		local axes
		local function update_axes()
			if(twistAxis == math.AXIS_X) then
				axes = {math.AXIS_X,math.AXIS_Z,math.AXIS_Y}
			elseif(twistAxis == math.AXIS_Y) then
				axes = {math.AXIS_Z,math.AXIS_Y,math.AXIS_X}
			else
				axes = {math.AXIS_X,math.AXIS_Y,math.AXIS_Z}
			end
			local limits = getDefaultLimits()
			minP:SetValue(-limits.p)
			maxP:SetValue(limits.p)
			minY:SetValue(-limits.y)
			maxY:SetValue(limits.y)
			minR:SetValue(-limits.r)
			maxR:SetValue(limits.r)
		end

		ctrl:AddDropDownMenu(locale.get_text("pfm_ik_twist_axis"),"twist_axis",{
			{tostring(math.AXIS_X),"X"},
			{tostring(math.AXIS_Y),"Y"},
			{tostring(math.AXIS_Z),"Z"}
		},twistAxis,function(el,option)
			local axis = el:GetOptionValue(el:GetSelectedOption())
			twistAxis = tonumber(axis)
			constraint.axis = twistAxis
			update_axes()
			self:UpdateDebugVisualization()
		end)

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
		subSeparate = ctrl:AddSubMenu()
		--subUnidirectional = ctrl:AddSubMenu()

		minP,maxP = add_rotation_axis(subSeparate,"pitch",0,minLimits.p,maxLimits.p)
		minY,maxY = add_rotation_axis(subSeparate,"yaw",1,minLimits.y,maxLimits.y)
		minR,maxR = add_rotation_axis(subSeparate,"roll",2,minLimits.r,maxLimits.r)
		local pairs = {
			{minP,maxP},
			{minY,maxY},
			{minR,maxR}
		}
		for _,p in ipairs(pairs) do
			p[1]:AddCallback("OnLeftValueChanged",function()
				if(input.is_shift_key_down()) then
					p[2]:SetValue(-p[1]:GetValue())
				end
			end)
			p[2]:AddCallback("OnLeftValueChanged",function()
				if(input.is_shift_key_down()) then
					p[1]:SetValue(-p[2]:GetValue())
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
	elseif(type == "hinge") then
		singleAxis = 0
		ctrl:AddDropDownMenu(locale.get_text("pfm_ik_axis"),"axis",{
			{"x","X"},
			{"y","Y"},
			{"z","Z"}
		},0,function(el,option)
			singleAxis = el:GetSelectedOption()
			constraint.axis = singleAxis
			self:UpdateDebugVisualization()
		end)
		add_rotation_axis(ctrl,"angle",nil,minLimits.p,maxLimits.p)
	end
	ctrl:ResetControls()
	ctrl:Update()
	ctrl:SizeToContents()

	self:ReloadIkRig()
	return constraint
end
function Element:AddBallSocketConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"ballSocket",c)
end
function Element:AddHingeConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"hinge",c)
end
function Element:AddFixedConstraint(item,boneName,c)
	return self:AddConstraint(item,boneName,"fixed",c)
end