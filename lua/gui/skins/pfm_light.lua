-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(245, 245, 245, 255)
t.background.secondary = Color(230, 230, 230, 255)
t.background.tertiary = Color(255, 255, 255, 255)
t.background.selected = Color(215, 215, 215, 255)
t.background.selected_hover = Color(200, 200, 200, 255)
t.background.hover = Color(230, 230, 230, 255)

t.button = {}
t.button.background = Color(255, 255, 255, 255)
t.button.background_unpressed = Color.White:Copy()
t.button.background_pressed = Color(200, 200, 200, 255)
t.button.icon = Color(120, 120, 120, 255)

t.slider = {}
t.slider.color = Color.RoyalBlue

t.text = {}
t.text.body = Color(50, 50, 50, 255)
t.text.tab = Color.Black:Copy()
t.text.title = Color.Black:Copy()
t.text.highlight = Color(30, 144, 255, 255)

t.icon = Color.Black:Copy()
t.outline = {}
t.outline.color = Color(200, 200, 200, 255)
t.outline.color_secondary = Color(200, 200, 200, 255)
t.outline.focus = Color.DodgerBlue:Copy()

t.overlay = {}
t.overlay.color = Color.Black:Copy()

t.graph = {}
t.graph.line = Color(0, 0, 0, 255)

t.timeline = {}
t.timeline.text = Color.Black:Copy()
t.timeline.background = Color(220, 220, 220, 255)

t.timeline.film_strip = {}
t.timeline.film_strip.background = Color(62, 62, 107)
t.timeline.film_strip.dots = Color(46, 46, 54, 255)

t.actor_editor = {}
t.actor_editor.collection = Color(150, 150, 150, 255)
t.actor_editor.actor = Color(70, 130, 180, 255)
t.actor_editor.component = Color(46, 139, 87, 255)
t.actor_editor.property = Color(80, 80, 80, 255)

t.ICON_CACHE = gui.PFMIconCache()

t.STYLE_SHEETS = {}
t.STYLE_SHEETS[".stop-top"] = {
	["stop-color"] = "#" .. t.button.background:ToHexColor(),
}
t.STYLE_SHEETS[".stop-bottom"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}
t.STYLE_SHEETS[".rect"] = {
	["stroke"] = "#" .. t.background.secondary:ToHexColor(),
}

local skin = {}

gui.register_skin("pfm_light", t, skin, "pfm")
