--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.KeyframeMarker", gui.Base)
Element.STATE_STATIC = 0
Element.STATE_ANIMATED = 1
Element.STATE_ANIMATED_FRAME = 2
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(12, 12)

	local el = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	el:SetMaterial("gui/pfm/keyframe_marker")
	self.m_elTexture = el

	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HAND)
	el:GetColorProperty():Link(self:GetColorProperty())

	self:SetKeyframeState(Element.STATE_STATIC)
end
function Element:GetKeyframeState()
	return self.m_keyframeState
end
function Element:SetKeyframeState(state)
	if self.m_keyframeState == state then
		return
	end
	self.m_keyframeState = state
	local mat = "gui/pfm/keyframe_marker"
	self:RemoveStyleClass("keyframe_marker_static")
	self:RemoveStyleClass("keyframe_marker_animated")
	self:RemoveStyleClass("keyframe_marker_animated_frame")
	if state == Element.STATE_STATIC then
		mat = "gui/pfm/keyframe_marker_static"
		self:SetTooltip(locale.get_text("pfm_animate_property"))
		self:AddStyleClass("keyframe_marker_static")
	elseif state == Element.STATE_ANIMATED then
		self:SetTooltip(locale.get_text("pfm_add_keyframe"))
		self:AddStyleClass("keyframe_marker_animated")
	elseif state == Element.STATE_ANIMATED_FRAME then
		self:SetTooltip(locale.get_text("pfm_remove_keyframe"))
		self:AddStyleClass("keyframe_marker_animated_frame")
	end
	self:RefreshSkin()
	self.m_elTexture:SetMaterial(mat)
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:CallCallbacks("OnClicked")
		end
		return util.EVENT_REPLY_HANDLED
	end
end
gui.register("WIKeyframeMarker", Element)

local KFMManager = util.register_class("gui.KeyframeMarkerManager")
function KFMManager:__init()
	self.m_markers = {}
	self.m_actorPropertyToMarker = {}

	local pm = tool.get_filmmaker()
	local animManager = pm:GetAnimationManager()
	self.m_cbChannelAdded = animManager:AddEventCallback(
		ents.PFMAnimationManager.EVENT_ON_CHANNEL_ADDED,
		function(actor, path)
			self:UpdateMarker(actor, path)
		end
	)
	self.m_cbChannelRemoved = animManager:AddEventCallback(
		ents.PFMAnimationManager.EVENT_ON_CHANNEL_REMOVED,
		function(actor, path)
			self:UpdateMarker(actor, path)
		end
	)
	self.m_cbTimeOffsetChanged = pfm.add_event_listener("OnTimeOffsetChanged", function(timeOffset)
		self:UpdateMarkers()
	end)
	self.m_cbKeyframePropertyChanged = pfm.add_event_listener("OnKeyframePropertyChanged", function(actor, property)
		self:UpdateMarker(actor, property)
	end)
end
function KFMManager:Clear()
	util.remove(self.m_cbChannelAdded)
	util.remove(self.m_cbChannelRemoved)
	util.remove(self.m_cbTimeOffsetChanged)
	util.remove(self.m_cbKeyframePropertyChanged)
end
function KFMManager:UpdateMarker(actor, property)
	local marker = self:GetMarkersByActorProperty(actor, property)
	if util.is_valid(marker) == false then
		return
	end
	local state = self:GetPropertyAnimationState(actor, property)
	marker:SetKeyframeState(state)
end
function KFMManager:UpdateMarkers()
	for _, markerData in ipairs(self.m_markers) do
		self:UpdateMarker(markerData.actor, markerData.property)
	end
end
function KFMManager:AddMarker(marker, actor, property, type)
	table.insert(self.m_markers, {
		marker = marker,
		actor = actor,
		property = property,
	})
	self.m_actorPropertyToMarker[tostring(actor:GetUniqueId()) .. property] = marker

	marker:AddCallback("OnClicked", function()
		if marker:IsValid() then
			self:ToggleMarkerKeyframe(actor, property, type, marker)
		end
		return util.EVENT_REPLY_HANDLED
	end)
end
function KFMManager:ToggleMarkerKeyframe(actor, property, type, marker)
	local state = marker:GetKeyframeState()
	local pm = tool.get_filmmaker()
	if state == Element.STATE_ANIMATED_FRAME then
		local animManager = pm:GetAnimationManager()
		local time = pm:GetTimeOffset()

		-- Delete existing keyframe
		local cmd = pfm.create_command("composition")

		local hasKeyframe = false
		local hasOnlyOneKeyframe = true
		-- Typically where can only be 4 keyframes per property (e.g. vec4),
		-- but we'll check 16 to be on the safe side for the future (e.g. mat4)
		for i = 0, 15 do
			local exists, editorChannel, keyIdx = pfm.CommandCreateKeyframe.does_keyframe_exist(
				animManager,
				tostring(actor:GetUniqueId()),
				property,
				time,
				i
			)
			if exists then
				local res, subCmd =
					cmd:AddSubCommand("keyframe_property_composition", tostring(actor:GetUniqueId()), property, i)
				subCmd:AddSubCommand("delete_keyframe", tostring(actor:GetUniqueId()), property, time, i)
				hasKeyframe = true

				if editorChannel:GetGraphCurve():GetKey(i):GetTimeCount() > 1 then
					hasOnlyOneKeyframe = false
				end
			end
		end
		if hasKeyframe then
			if hasOnlyOneKeyframe then
				-- There's only one keyframe, delete the whole channel
				local res, subCmd = cmd:AddSubCommand("delete_animation_channel", actor, property, type)
				if res == pfm.Command.RESULT_SUCCESS then
					subCmd:AddSubCommand("delete_editor_channel", actor, property, type)
				end
				pfm.undoredo.push("delete_animation_channel", cmd)()
			else
				pfm.undoredo.push("delete_keyframe", cmd)()
			end
		end
	else
		local n = udm.get_numeric_component_count(type)
		local cmd = pfm.create_command("composition")
		for baseIndex = 0, n - 1 do
			local res, subCmd =
				cmd:AddSubCommand("keyframe_property_composition", tostring(actor:GetUniqueId()), property, baseIndex)
			pm:ChangeActorPropertyKeyframeValue(actor, property, type, nil, nil, baseIndex, true, subCmd)
		end
		pfm.undoredo.push("add_keyframe", cmd)()
	end
end
function KFMManager:GetMarkersByActorProperty(actor, property)
	return self.m_actorPropertyToMarker[tostring(actor:GetUniqueId()) .. property]
end
function KFMManager:GetPropertyAnimationState(actor, property)
	local state = Element.STATE_STATIC
	local pm = tool.get_filmmaker()
	local animManager = pm:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, property)
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(property)
		if editorChannel ~= nil then
			state = Element.STATE_ANIMATED
			local keyIdx = editorChannel:FindKeyIndexByTime(pm:GetTimeOffset(), 0)
			if keyIdx ~= nil then
				state = Element.STATE_ANIMATED_FRAME
			end
		end
	end
	return state
end
