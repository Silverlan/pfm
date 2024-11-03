--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.util = pfm.util or {}
pfm.util.impl = pfm.util.impl or {}
function pfm.util.register_game_shader(name)
	pfm.util.impl.game_shaders = pfm.util.impl.game_shaders or {}
	pfm.util.impl.game_shader_map = pfm.util.impl.game_shader_map or {}
	if pfm.util.impl.game_shader_map[name] ~= nil then
		return
	end
	pfm.util.impl.game_shader_map[name] = true
	table.insert(pfm.util.impl.game_shaders, name)
end

function pfm.util.get_game_shaders()
	return pfm.util.impl.game_shaders or {}
end

-- Base game shaders

pfm.util.register_game_shader("pbr")
pfm.util.register_game_shader("pbr_blend")
pfm.util.register_game_shader("eye")
pfm.util.register_game_shader("eye_legacy")
pfm.util.register_game_shader("unlit")
pfm.util.register_game_shader("wireframe")
pfm.util.register_game_shader("toon")
pfm.util.register_game_shader("bw")
