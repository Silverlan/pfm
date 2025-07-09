-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(17, 17, 17, 255)
t.background.secondary = Color(33, 33, 33, 255)
t.background.selected = Color(50, 50, 50)

t.button = {}
t.button.background_pressed = Color(160, 160, 160)
t.button.icon = Color(180, 180, 180)

t.text = {}
t.text.body = Color(255, 153, 0)
t.text.highlight = Color(30, 144, 255, 255)

t.actor_editor = {}
t.actor_editor.collection = Color(204, 204, 204)
t.actor_editor.actor = Color(255, 140, 0, 255)
t.actor_editor.component = Color(160, 80, 226, 255)
t.actor_editor.property = Color(230, 230, 230)

t.outline = {}
t.outline.color = Color(17, 17, 17, 255)
t.outline.focus = Color.DodgerBlue:Copy()

t.ICON_CACHE = gui.PFMIconCache()

t.STYLE_SHEETS = {}
t.STYLE_SHEETS[".stop-top"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}
t.STYLE_SHEETS[".stop-bottom"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}
t.STYLE_SHEETS[".rect"] = {
	["stroke"] = "#" .. t.background.selected:ToHexColor(),
}

local skin = {}

gui.register_skin("pfm_halloween", t, skin, "pfm")
