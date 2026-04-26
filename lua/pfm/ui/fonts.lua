-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}

pfm.font_sets = pfm.font_sets or {}
pfm.register_font_set = function(identifier, baseFontSet, fontSizes)
	fontSizes = fontSizes or {}
	local function initialize_font()
		local baseIdentifier = "pfm_" .. identifier
		local fontFeatures = bit.bor(engine.FONT_FEATURE_FLAG_SANS_BIT, engine.FONT_FEATURE_FLAG_MONO_BIT)
		engine.create_font(baseIdentifier .. "_small", baseFontSet, fontFeatures, fontSizes["small"] or 10)
		engine.create_font(baseIdentifier .. "_medium", baseFontSet, fontFeatures, fontSizes["medium"] or 12)
		engine.create_font(baseIdentifier .. "_large", baseFontSet, fontFeatures, fontSizes["large"] or 20)
	end
	pfm.font_sets[identifier] = {
		initialize = initialize_font
	}
end

pfm.initialize_font_set = function(identifier)
	if(pfm.font_sets[identifier] == nil or pfm.font_sets[identifier].initialize == nil) then return end
	pfm.font_sets[identifier].initialize()
	pfm.font_sets[identifier].initialize = nil
end

pfm.get_font_sets = function()
	local fontSets = {}
	for identifier, _ in pairs(pfm.font_sets) do
		table.insert(fontSets, identifier)
	end
	table.sort(fontSets)
	return fontSets
end

pfm.set_active_font_set = function(fontSet)
	console.run("pfm_font", fontSet)
end

pfm.get_active_font_set = function()
	return console.get_convar_string("pfm_font")
end

pfm.get_font = function(fontType)
	local fontSet = pfm.get_active_font_set()
	pfm.initialize_font_set(fontSet)
	return "pfm_" .. fontSet .. "_" .. fontType
end

pfm.is_valid_font_set = function(identifier) return pfm.font_sets[identifier] ~= nil end

pfm.register_font_set("dejavu", "dejavu")
pfm.register_font_set("opensans", "opensans")
pfm.register_font_set("source-han-sans", "source-han-sans")
pfm.register_font_set("ubuntu", "ubuntu")
