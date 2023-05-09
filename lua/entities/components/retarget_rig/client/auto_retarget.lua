--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function find_common_substrings(names)
	local commonSubstrings = {}
	for i = 0, #names - 1 do
		local n0 = names[i + 1]
		for j = i + 1, #names - 1 do
			local n1 = names[j + 1]
			local startIdx, len, endIdx = string.find_longest_common_substring(n0, n1)
			if len > 0 then
				local sub = n0:sub(startIdx, len)
				commonSubstrings[sub] = commonSubstrings[sub] or 0
				commonSubstrings[sub] = commonSubstrings[sub] + 1
			end
		end
	end

	local sortedCommonSubstrings = {}
	for sub, _ in pairs(commonSubstrings) do
		table.insert(sortedCommonSubstrings, sub)
	end
	table.sort(sortedCommonSubstrings, function(a, b)
		return commonSubstrings[a] > commonSubstrings[b]
	end)
	return sortedCommonSubstrings
end

local function get_average_makeup_percentage(sub, names)
	local avgP = 0
	for _, name in ipairs(names) do
		if name:find(sub) and #name > 0 then
			local p = #sub / #name
			avgP = avgP + p
		end
	end
	avgP = avgP / #names
	return avgP
end

local function remove_substring(names, sub)
	for i, name in ipairs(names) do
		names[i] = string.replace(name, sub, "")
	end
end

local function strip_common_generic_substrings(names, threshold)
	local sortedCommonSubstrings = find_common_substrings(names)
	local sub = sortedCommonSubstrings[1]
	if sub ~= nil then
		-- We'll remove the most common substring (assuming its length is about the average threshold),
		-- as well as all common substrings that are substrings of the most common one (and also above the threshold).
		local i = 2
		while i <= #sortedCommonSubstrings do
			if
				#sortedCommonSubstrings[i] >= #sub
				or sub:find(sortedCommonSubstrings[i]) == nil
				or get_average_makeup_percentage(sortedCommonSubstrings[i], names) < 0.2
			then
				table.remove(sortedCommonSubstrings, i)
			else
				i = i + 1
			end
		end
		table.sort(sortedCommonSubstrings, function(a, b)
			return #a > #b
		end) -- We need to make sure to remove the longer matches first
	end
	for _, sub in ipairs(sortedCommonSubstrings) do
		remove_substring(names, sub)
	end
	local commonGenericSubstrings = { "ValveBiped." }
	for _, str in ipairs(commonGenericSubstrings) do
		remove_substring(names, str:lower())
	end
end

local function get_skeleton_bone_names(skeleton)
	local boneNames = {}
	for _, bone in ipairs(skeleton:GetBones()) do
		table.insert(boneNames, bone:GetName())
	end
	local normalizedNames = {}
	for i, name in ipairs(boneNames) do
		normalizedNames[i] = name:lower()
	end
	strip_common_generic_substrings(normalizedNames, 0.2)
	return normalizedNames, boneNames
end

local function calc_character_diff(str0, str1)
	str0 = str0:lower()
	str1 = str1:lower()

	local m0 = {}
	for i = 1, #str0 do
		local c0 = str0:sub(i, i)
		m0[c0] = (m0[c0] or 0) + 1
	end

	local m1 = {}
	for i = 1, #str1 do
		local c1 = str1:sub(i, i)
		m1[c1] = (m1[c1] or 0) + 1
	end

	local diff = 0
	for c, count in pairs(m0) do
		diff = diff + math.abs((m1[c] or 0) - count)
	end
	return 1.0 - (diff / #str0)
end

function ents.RetargetRig.autoretarget(names0, names1, threshold, origNames0, origNames1)
	origNames0 = origNames0 or names0
	origNames1 = origNames1 or names1
	local map = {}
	for i, name0 in ipairs(names0) do
		for j, name1 in ipairs(names1) do
			local sim = string.calc_levenshtein_similarity(name0, name1)
			map[j] = map[j] or {}
			map[j][i] = sim
		end
	end

	local r = {}
	for i, name0 in ipairs(names0) do
		local list = {}
		for j, d in pairs(map) do
			if d[i] ~= nil then
				table.insert(list, { j, d[i] })
			end
		end
		-- Sort by similarity
		table.sort(list, function(a, b)
			return a[2] > b[2]
		end)

		-- Only keep the ones with the highest similarity
		local j = 2
		while j <= #list do
			if list[j][2] ~= list[1][2] then
				table.remove(list, j)
			else
				j = j + 1
			end
		end

		for _, d in ipairs(list) do
			d[2] = d[2] * calc_character_diff(name0, names1[d[1]])
		end
		table.sort(list, function(a, b)
			return a[2] > b[2]
		end)
		-- Pick one that hasn't been used yet (or has a higher similarity than the previous one)
		for j = 1, #list do
			if r[list[j][1]] == nil or list[j][2] > r[list[j][1]][2] then
				r[list[j][1]] = { i, list[j][2] }
				break
			end
		end
	end

	--[[print("Mappings:")
	for j,i in pairs(r) do
		print(origNames0[i[1] ] .. " = " .. origNames1[j])
	end]]

	threshold = threshold or 0.27
	local mapped = {}
	for j, i in pairs(r) do
		if i[2] >= threshold then
			mapped[origNames0[i[1]]] = origNames1[j]
		end
	end
	return mapped
end

function ents.RetargetRig.autoretarget_skeleton(skeleton0, skeleton1, threshold)
	local names0, origNames0 = get_skeleton_bone_names(skeleton0)
	local names1, origNames1 = get_skeleton_bone_names(skeleton1)
	return ents.RetargetRig.autoretarget(names0, names1, threshold, origNames0, origNames1)
end
