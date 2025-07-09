-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

udm.util = udm.util or {}

local function find(udmData, targetVal, targetType, subString, path, t)
	path = path or ""
	t = t or {}
	for name, el in pairs(udmData:GetChildren()) do
		local elType = el:GetType()
		if elType == udm.TYPE_ELEMENT then
			local subPath = path .. name .. "/"
			find(el, targetVal, targetType, subString, subPath, t)
		elseif udm.is_array_type(elType) then
			local valueType = el:GetValueType()
			if valueType == udm.TYPE_ELEMENT then
				local values = el:GetArrayValues()
				for i, val in ipairs(values) do
					local subPath = path .. name .. "[" .. (i - 1) .. "]/"
					find(val, targetVal, targetType, subString, subPath, t)
				end
			elseif udm.is_convertible(elType, valueType) then
				local values = el:GetArrayValues()
				for i, val in ipairs(values) do
					if val == targetVal or (subString and tostring(val):find(targetVal) ~= nil) then
						table.insert(t, path .. name .. "[" .. (i - 1) .. "]")
					end
				end
			end
		elseif udm.is_convertible(elType, targetType) then
			local val = el:GetValue()
			if val == targetVal or (subString and tostring(val):find(targetVal) ~= nil) then
				table.insert(t, path .. name)
			end
		end
	end
	return t
end

udm.util.find_value_path = function(udmData, targetVal, targetType, subString)
	return find(udmData, targetVal, targetType, subString)
end
