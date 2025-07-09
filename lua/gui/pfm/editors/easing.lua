-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}

function pfm.util.easing_back_ease_in(time, begin, change, duration, overshoot)
	time = time / duration
	return change * time * time * ((overshoot + 1) * time - overshoot) + begin
end

function pfm.util.easing_back_ease_out(time, begin, change, duration, overshoot)
	time = time / duration - 1
	return change * (time * time * ((overshoot + 1) * time + overshoot) + 1) + begin
end

function pfm.util.easing_back_ease_in_out(time, begin, change, duration, overshoot)
	overshoot = overshoot * 1.525
	time = time / (duration / 2)
	if time < 1.0 then
		return change / 2 * (time * time * ((overshoot + 1) * time - overshoot)) + begin
	end
	time = time - 2.0
	return change / 2 * (time * time * ((overshoot + 1) * time + overshoot) + 2) + begin
end

function pfm.util.easing_bounce_ease_out(time, begin, change, duration)
	time = time / duration
	if time < (1 / 2.75) then
		return change * (7.5625 * time * time) + begin
	end
	if time < (2 / 2.75) then
		time = time - (1.5 / 2.75)
		return change * ((7.5625 * time) * time + 0.75) + begin
	end
	if time < (2.5 / 2.75) then
		time = time - (2.25 / 2.75)
		return change * ((7.5625 * time) * time + 0.9375) + begin
	end
	time = time - (2.625 / 2.75)
	return change * ((7.5625 * time) * time + 0.984375) + begin
end

function pfm.util.easing_bounce_ease_in(time, begin, change, duration)
	return change - pfm.util.easing_bounce_ease_out(duration - time, 0, change, duration) + begin
end

function pfm.util.easing_bounce_ease_in_out(time, begin, change, duration)
	if time < duration / 2 then
		return pfm.util.easing_bounce_ease_in(time * 2, 0, change, duration) * 0.5 + begin
	end
	return pfm.util.easing_bounce_ease_out(time * 2 - duration, 0, change, duration) * 0.5 + change * 0.5 + begin
end

function pfm.util.easing_circ_ease_in(time, begin, change, duration)
	time = time / duration
	return -change * (math.sqrt(1 - time * time) - 1) + begin
end

function pfm.util.easing_circ_ease_out(time, begin, change, duration)
	time = time / duration - 1
	return change * math.sqrt(1 - time * time) + begin
end

function pfm.util.easing_circ_ease_in_out(time, begin, change, duration)
	time = time / (duration / 2)
	if time < 1.0 then
		return -change / 2 * (math.sqrt(1 - time * time) - 1) + begin
	end
	time = time - 2.0
	return change / 2 * (math.sqrt(1 - time * time) + 1) + begin
end

function pfm.util.easing_cubic_ease_in(time, begin, change, duration)
	time = time / duration
	return change * time * time * time + begin
end

function pfm.util.easing_cubic_ease_out(time, begin, change, duration)
	time = time / duration - 1
	return change * (time * time * time + 1) + begin
end

function pfm.util.easing_cubic_ease_in_out(time, begin, change, duration)
	time = time / (duration / 2)
	if time < 1.0 then
		return change / 2 * time * time * time + begin
	end
	time = time - 2.0
	return change / 2 * (time * time * time + 2) + begin
end

local function elastic_blend(time, change, duration, amplitude, s, f)
	if change then
		--[[ Looks like a magic number,
		* but this is a part of the sine curve we need to blend from ]]
		local t = math.abs(s)
		if amplitude then
			f = f * (amplitude / math.abs(change))
		else
			f = 0.0
		end

		if math.abs(time * duration) < t then
			local l = math.abs(time * duration) / t
			f = (f * l) + (1.0 - l)
		end
	end

	return f
end

function pfm.util.easing_elastic_ease_in(time, begin, change, duration, amplitude, period)
	local s
	local f = 1.0

	if time == 0.0 then
		return begin
	end

	time = time / duration
	if time == 1.0 then
		return begin + change
	end
	time = time - 1.0
	if period == 0.0 then
		period = duration * 0.3
	end
	if amplitude == 0.0 or amplitude < math.abs(change) then
		s = period / 4

		f = elastic_blend(time, change, duration, amplitude, s, f)

		amplitude = change
	else
		s = period / (2 * math.pi) * math.asin(change / amplitude)
	end

	return (-f * (amplitude * math.pow(2, 10 * time) * math.sin((time * duration - s) * (2 * math.pi) / period)))
		+ begin
end

function pfm.util.easing_elastic_ease_out(time, begin, change, duration, amplitude, period)
	local s
	local f = 1.0

	if time == 0.0 then
		return begin
	end
	time = time / duration
	if time == 1.0 then
		return begin + change
	end
	time = -time
	if period == 0.0 then
		period = duration * 0.3
	end
	if amplitude == 0.0 or amplitude < math.abs(change) then
		s = period / 4

		f = elastic_blend(time, change, duration, amplitude, s, f)

		amplitude = change
	else
		s = period / (2 * math.pi) * math.asin(change / amplitude)
	end

	return (f * (amplitude * math.pow(2, 10 * time) * math.sin((time * duration - s) * (2 * math.pi) / period)))
		+ change
		+ begin
end

function pfm.util.easing_elastic_ease_in_out(time, begin, change, duration, amplitude, period)
	local s
	local f = 1.0

	if time == 0.0 then
		return begin
	end
	time = time / (duration / 2)
	if time == 2.0 then
		return begin + change
	end
	time = time - 1.0
	if period == 0.0 then
		period = duration * (0.3 * 1.5)
	end
	if amplitude == 0.0 or amplitude < math.abs(change) then
		s = period / 4

		f = elastic_blend(time, change, duration, amplitude, s, f)

		amplitude = change
	else
		s = period / (2 * math.pi) * math.asin(change / amplitude)
	end

	if time < 0.0 then
		f = f * -0.5
		return (f * (amplitude * math.pow(2, 10 * time) * math.sin((time * duration - s) * (2 * math.pi) / period)))
			+ begin
	end

	time = -time
	f = f * 0.5
	return (f * (amplitude * math.pow(2, 10 * time) * math.sin((time * duration - s) * (2 * math.pi) / period)))
		+ change
		+ begin
end

local pow_min = 0.0009765625 --[[ = 2^(-10) ]]
local pow_scale = 1.0 / (1.0 - 0.0009765625)

function pfm.util.easing_expo_ease_in(time, begin, change, duration)
	if time == 0.0 then
		return begin
	end
	return change * (math.pow(2, 10 * (time / duration - 1)) - pow_min) * pow_scale + begin
end

function pfm.util.easing_expo_ease_out(time, begin, change, duration)
	if time == 0.0 then
		return begin
	end
	return change * (1 - (math.pow(2, -10 * time / duration) - pow_min) * pow_scale) + begin
end

function pfm.util.easing_expo_ease_in_out(time, begin, change, duration)
	local duration_half = duration / 2.0
	local change_half = change / 2.0
	if time <= duration_half then
		return pfm.util.easing_expo_ease_in(time, begin, change_half, duration_half)
	end
	return pfm.util.easing_expo_ease_out(time - duration_half, begin + change_half, change_half, duration_half)
end

function pfm.util.easing_linear_ease(time, begin, change, duration)
	return change * time / duration + begin
end

function pfm.util.easing_quad_ease_in(time, begin, change, duration)
	time = time / duration
	return change * time * time + begin
end

function pfm.util.easing_quad_ease_out(time, begin, change, duration)
	time = time / duration
	return -change * time * (time - 2) + begin
end

function pfm.util.easing_quad_ease_in_out(time, begin, change, duration)
	time = time / (duration / 2)
	if time < 1.0 then
		return change / 2 * time * time + begin
	end
	time = time - 1.0
	return -change / 2 * (time * (time - 2) - 1) + begin
end

function pfm.util.easing_quart_ease_in(time, begin, change, duration)
	time = time / duration
	return change * time * time * time * time + begin
end

function pfm.util.easing_quart_ease_out(time, begin, change, duration)
	time = time / duration - 1
	return -change * (time * time * time * time - 1) + begin
end

function pfm.util.easing_quart_ease_in_out(time, begin, change, duration)
	time = time / (duration / 2)
	if time < 1.0 then
		return change / 2 * time * time * time * time + begin
	end
	time = time - 2.0
	return -change / 2 * (time * time * time * time - 2) + begin
end

function pfm.util.easing_quint_ease_in(time, begin, change, duration)
	time = time / duration
	return change * time * time * time * time * time + begin
end
function pfm.util.easing_quint_ease_out(time, begin, change, duration)
	time = time / duration - 1
	return change * (time * time * time * time * time + 1) + begin
end
function pfm.util.easing_quint_ease_in_out(time, begin, change, duration)
	time = time / (duration / 2)
	if time < 1.0 then
		return change / 2 * time * time * time * time * time + begin
	end
	time = time - 2.0
	return change / 2 * (time * time * time * time * time + 2) + begin
end

local M_PI_2 = math.pi / 2.0
function pfm.util.easing_sine_ease_in(time, begin, change, duration)
	return -change * math.cos(time / duration * M_PI_2) + change + begin
end

function pfm.util.easing_sine_ease_out(time, begin, change, duration)
	return change * math.sin(time / duration * M_PI_2) + begin
end

function pfm.util.easing_sine_ease_in_out(time, begin, change, duration)
	return -change / 2 * (math.cos(math.pi * time / duration) - 1) + begin
end

function pfm.util.get_easing_method(interpMethod, easingMode)
	if interpMethod == pfm.udm.INTERPOLATION_BACK then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_back_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_back_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_back_ease_in_out
		else
			return pfm.util.easing_back_ease_out
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_BOUNCE then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_bounce_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_bounce_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_bounce_ease_in_out
		else
			return pfm.util.easing_bounce_ease_out
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_CIRC then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_circ_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_circ_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_circ_ease_in_out
		else
			return pfm.util.easing_circ_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_CUBIC then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_cubic_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_cubic_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_cubic_ease_in_out
		else
			return pfm.util.easing_cubic_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_ELASTIC then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_elastic_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_elastic_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_elastic_ease_in_out
		else
			return pfm.util.easing_elastic_ease_out
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_EXPO then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_expo_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_expo_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_expo_ease_in_out
		else
			return pfm.util.easing_expo_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_QUAD then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_quad_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_quad_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_quad_ease_in_out
		else
			return pfm.util.easing_quad_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_QUART then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_quart_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_quart_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_quart_ease_in_out
		else
			return pfm.util.easing_quart_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_QUINT then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_quint_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_quint_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_quint_ease_in_out
		else
			return pfm.util.easing_quint_ease_in
		end
	elseif interpMethod == pfm.udm.INTERPOLATION_SINE then
		if easingMode == pfm.udm.EASING_MODE_IN then
			return pfm.util.easing_sine_ease_in
		elseif easingMode == pfm.udm.EASING_MODE_OUT then
			return pfm.util.easing_sine_ease_out
		elseif easingMode == pfm.udm.EASING_MODE_IN_OUT then
			return pfm.util.easing_sine_ease_in_out
		else
			return pfm.util.easing_sine_ease_in
		end
	end
end
