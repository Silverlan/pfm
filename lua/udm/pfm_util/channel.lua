-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.Channel:OnInitialize() end

function pfm.udm.Channel:GetAnimation()
	return self:GetParent()
end

function pfm.udm.Channel:Optimize()
	self:GetPanimaChannel():Optimize()
end

function pfm.udm.Channel:GetPanimaAnimation()
	return self:GetAnimation():GetAnimationClip():GetPanimaAnimation()
end

function pfm.udm.Channel:GetPanimaChannel()
	return self:GetPanimaAnimation():FindChannel(self:GetTargetPath())
end

function pfm.udm.Channel:ChangeExpression(expr)
	local oldExpr = self:GetExpression()
	self:SetExpression(expr)

	local animationClip = self:GetAnimation():GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners("OnAnimationChannelMathExpressionChanged", track, animationClip, self, oldExpr, expr)
end

function pfm.udm.Channel.calculate_curve_fitting_keyframes(times, values)
	local error = 8
	local t = {}
	-- Curve fitting algorithm expects a table of Vector2 values
	for i = 1, #times do
		local v = Vector2(times[i], values[i])
		table.insert(t, v)
	end

	-- The curve fitting algorithm only works properly in large value ranges, so we temporarily remap
	local remapScale = 100.0
	local minTime = math.huge
	local maxTime = -math.huge
	local minVal = math.huge
	local maxVal = -math.huge
	for _, v in ipairs(t) do
		minTime = math.min(minTime, v.x)
		maxTime = math.max(maxTime, v.x)
		minVal = math.min(minVal, v.y)
		maxVal = math.max(maxVal, v.y)
	end
	for i, v in ipairs(t) do
		v.x = math.remap(v.x, minTime, maxTime, 0.0, remapScale)
		v.y = math.remap(v.y, minVal, maxVal, 0.0, remapScale)
	end

	local keyframes = math.fit_bezier_curve(t, error)
	-- Map the generated keyframes back to the original scale
	for i, bc in ipairs(keyframes) do
		for j = 1, 4 do
			bc[j].x = math.remap(bc[j].x, 0.0, remapScale, minTime, maxTime)
			bc[j].y = math.remap(bc[j].y, 0.0, remapScale, minVal, maxVal)
		end
	end

	return keyframes
end

function pfm.udm.Channel:ApplyCurveFittingToRange(actorUuid, propertyPath, baseIndex, tStart, tEnd, cmd)
	local keyframes = self:CalculateCurveFittingKeyframes(tStart, tEnd, baseIndex)
	if keyframes == nil then
		return
	end
	local panimaChannel = self:GetPanimaChannel()
	local hasParentCmd = (cmd ~= nil)
	cmd = cmd or pfm.create_command("keyframe_property_composition", actorUuid, propertyPath, baseIndex)
	cmd:AddSubCommand(
		"apply_curve_fitting",
		actorUuid,
		propertyPath,
		keyframes,
		panimaChannel:GetValueType(),
		baseIndex
	)
	if hasParentCmd == false then
		pfm.undoredo.push("apply_curve_fitting", cmd)()
	end
end

function pfm.udm.Channel:CalculateCurveFittingKeyframes(tStart, tEnd, baseIndex)
	if math.abs(tEnd - tStart) <= panima.VALUE_EPSILON then
		return
	end
	local n = self:GetValueCount()
	local panimaChannel = self:GetPanimaChannel()

	local times, values = panimaChannel:GetDataInRange(tStart, tEnd)
	local valueType = panimaChannel:GetValueType()

	local editorValueType = pfm.to_editor_channel_type(valueType)
	if editorValueType ~= valueType then
		local tmpValues = {}
		for _, v in ipairs(values) do
			local newVal = pfm.to_editor_channel_value(v, valueType)
			table.insert(tmpValues, newVal)
		end
		values = tmpValues
		valueType = editorValueType
	end

	local n = udm.get_numeric_component_count(valueType)
	if n > 1 then
		local tmpValues = {}
		for _, v in ipairs(values) do
			table.insert(tmpValues, udm.get_numeric_component(v, baseIndex, valueType))
		end
		values = tmpValues
	end
	return pfm.udm.Channel.calculate_curve_fitting_keyframes(times, values)
end
