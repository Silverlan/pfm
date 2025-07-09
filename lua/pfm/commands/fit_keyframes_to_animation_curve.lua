-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("base_transform_animation_channel.lua")
include("util/keyframe.lua")

local Command = util.register_class("pfm.CommandFitKeyframesToAnimationCurve", pfm.BaseCommandTransformAnimationChannel)
function Command:Initialize(actorUuid, propertyPath, baseIndex)
	local result = pfm.BaseCommandTransformAnimationChannel.Initialize(self, actorUuid, propertyPath)
	if result ~= pfm.Command.RESULT_SUCCESS then
		return result
	end

	local actor = pfm.dereference(actorUuid)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath)
	if channel == nil then
		return pfm.Command.RESULT_NO_OP
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = (animClip ~= nil) and editorData:FindChannel(propertyPath) or nil
	local graphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
	if graphCurve == nil then
		return pfm.Command.RESULT_NO_OP
	end

	local key = graphCurve:GetKey(baseIndex)
	if key == nil then
		return pfm.Command.RESULT_NO_OP
	end
	local data = self:GetData()
	pfm.util.store_keyframe_data(data, key)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoApplyTransform(undo, data, actor, propertyPath, anim, channel)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath)
	if channel == nil then
		return
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()

	if undo then
		-- Restore original keyframe values
		local baseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)
		local key = graphCurve:GetKey(baseIndex)
		pfm.util.restore_keyframe_data(data, key)
		return
	end

	-- Try to map the keyframes to the animation curve
	local keys = graphCurve:GetKeys()
	for keyIdx, key in ipairs(keys) do
		local n = key:GetValueCount()
		for i = 0, n - 1 do
			local t = key:GetTime(i)
			local value = channel:GetInterpolatedValue(t, false)
			value = udm.get_numeric_component(value, keyIdx - 1)
			key:SetValue(i, value)
		end

		local function get_curve_value(i)
			local t = key:GetTime(i)
			local v = key:GetValue(i)
			if t == nil then
				return
			end
			return Vector2(t, v)
		end
		for i = 0, n - 2 do
			local v0, v1, v2, v3 =
				get_curve_value(i - 1), get_curve_value(i), get_curve_value(i + 1), get_curve_value(i + 2)
			if i == 0 then
				-- Implicit point
				v0 = v1 + (v1 - v2) * 0.0001
			elseif i == n - 2 then
				-- Implicit point
				v3 = v2 + (v2 - v1) * 0.0001
			end

			local t0, t1 = math.calc_four_point_cubic_bezier(v0, v1, v2, v3)
			t0 = t0 - v1
			t1 = t1 - v2

			key:SetOutTime(i, t0.x)
			key:SetOutDelta(i, t0.y)
			key:SetOutHandleType(i, pfm.udm.KEYFRAME_HANDLE_TYPE_FREE)

			key:SetInTime(i + 1, t1.x)
			key:SetInDelta(i + 1, t1.y)
			key:SetInHandleType(i + 1, pfm.udm.KEYFRAME_HANDLE_TYPE_FREE)
		end
	end
end
pfm.register_command("fit_keyframes_to_animation_curve", Command)

local Command = util.register_class("pfm.CommandFitCurveKeyframesToAnimationCurve", pfm.Command)
function Command:Initialize(actorUuid, propertyPath)
	local actor = pfm.dereference(actorUuid)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath)
	if channel == nil then
		return pfm.Command.RESULT_NO_OP
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = (animClip ~= nil) and editorData:FindChannel(propertyPath) or nil
	local graphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
	if graphCurve == nil then
		return pfm.Command.RESULT_NO_OP
	end
	local numKeys = graphCurve:GetKeyCount()
	for i = 0, numKeys - 1 do
		self:AddSubCommand("fit_keyframes_to_animation_curve", actor, propertyPath, i)
	end
	return pfm.Command.RESULT_SUCCESS
end
pfm.register_command("fit_curve_keyframes_to_animation_curve", Command)
