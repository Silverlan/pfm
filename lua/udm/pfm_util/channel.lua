--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Channel:OnInitialize() end

function pfm.udm.Channel:GetAnimation()
	return self:GetParent()
end

function pfm.udm.Channel:GetPanimaChannel()
	return self:GetAnimation():GetAnimationClip():GetPanimaAnimation():FindChannel(self:GetTargetPath())
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

function pfm.udm.Channel:CalculateCurveFittingKeyframes(tStart, tEnd, baseIndex)
	if math.abs(tEnd - tStart) <= panima.VALUE_EPSILON then
		return
	end
	local n = self:GetValueCount()
	local panimaChannel = self:GetPanimaChannel()

	local times, values = panimaChannel:GetDataInRange(tStart, tEnd)
	local valueType = panimaChannel:GetValueType()
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
