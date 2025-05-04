include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(253, 246, 227, 255) -- #fdf6e3 (base3)
t.background.secondary = Color(238, 232, 213, 255) -- #eee8d5 (base2)
t.background.tertiary = Color(147, 161, 161, 255) -- #93a1a1 (base1)
t.background.selected = Color(131, 148, 150, 255) -- #839496 (base0)

-- Buttons
t.button = {}
t.button.background = Color(238, 232, 213, 255) -- #eee8d5 (base2)
t.button.background_unpressed = Color.White:Copy() -- matches primary bg
t.button.background_pressed = Color(211, 203, 183, 255) -- #93a1a1 (base1)
t.button.icon = Color(101, 123, 131, 255) -- #657b83 (base00)

-- Slider
t.slider = {}
t.slider.color = Color(38, 139, 210, 255) -- #268bd2 (blue)

-- Text
t.text = {}
t.text.body = Color(101, 123, 131, 255) -- #657b83 (base00)
t.text.tab = Color(88, 110, 117, 255) -- #586e75 (base01)
t.text.title = Color(101, 123, 131, 255) -- #657b83 (base00)
t.text.highlight = Color(38, 139, 210, 255)

-- Icons & outlines
t.icon = Color(101, 123, 131, 255) -- #657b83 (base00)
t.outline = {}
t.outline.color = Color(238, 232, 213, 255) -- #eee8d5 (base2)
t.outline.focus = Color(181, 137, 0, 255) -- #b58900 (yellow)

-- Overlay (e.g. modal scrim)
t.overlay = {}
t.overlay.color = Color(0, 0, 0, 128) -- semi-transparent black

-- Graphs
t.graph = {}
t.graph.line = Color(88, 110, 117, 255) -- #586e75 (base01)

-- Timeline
t.timeline = {}
t.timeline.text = Color(7, 54, 66, 255) -- #073642 (base02)
t.timeline.background = Color(238, 232, 213, 255) -- #eee8d5 (base2)

-- Actor Editor
t.actor_editor = {}
t.actor_editor.collection = Color(147, 161, 161, 255) -- #93a1a1 (base1)
t.actor_editor.actor = Color(203, 75, 22, 255) -- #cb4b16 (orange)
t.actor_editor.component = Color(108, 113, 196, 255) -- #6c71c4 (violet)
t.actor_editor.property = Color(88, 110, 117, 255) -- #586e75 (base01)

t.ICON_CACHE = gui.PFMIconCache()

t.STYLE_SHEETS = {}
t.STYLE_SHEETS[".stop-top"] = {
	["stop-color"] = "#" .. t.background.primary:ToHexColor(),
}
t.STYLE_SHEETS[".stop-bottom"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}
t.STYLE_SHEETS[".rect"] = {
	["stroke"] = "#" .. t.background.secondary:ToHexColor(),
}

local skin = {}

gui.register_skin("pfm_solarized_light", t, skin, "pfm")
