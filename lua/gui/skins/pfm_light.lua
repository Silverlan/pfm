include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(245, 245, 245, 255) -- very light gray
t.background.secondary = Color(230, 230, 230, 255) -- light gray
t.background.tertiary = Color(255, 255, 255, 255) -- white
t.background.selected = Color(215, 215, 215, 255) -- medium light gray

-- Buttons
t.button = {}
t.button.background = Color(255, 255, 255, 255) -- default button fill
t.button.background_unpressed = Color.White:Copy() -- matches primary bg
t.button.background_pressed = Color(200, 200, 200, 255) -- darker on press
t.button.icon = Color(80, 80, 80, 255) -- dark icon

-- Slider
t.slider = {}
t.slider.color = Color.RoyalBlue

-- Text
t.text = {}
t.text.body = Color(50, 50, 50, 255) -- dark gray
t.text.tab = Color.Black:Copy() -- pure black
t.text.title = Color.Black:Copy()
t.text.highlight = Color(30, 144, 255, 255)

-- Misc icons & outlines
t.icon = Color.Black:Copy()
t.outline = {}
t.outline.color = Color(200, 200, 200, 255) -- subtle border
t.outline.focus = Color.DodgerBlue:Copy() -- blue focus ring

-- Overlay (e.g. modal backgrounds, scrims)
t.overlay = {}
t.overlay.color = Color.Black:Copy() -- semi-transparent black if you adjust alpha elsewhere

-- Graphs
t.graph = {}
t.graph.line = Color(0, 0, 0, 255) -- black graph lines

-- Timeline
t.timeline = {}
t.timeline.text = Color.Black:Copy()
t.timeline.background = Color(220, 220, 220, 255)

-- Actor Editor
t.actor_editor = {}
t.actor_editor.collection = Color(150, 150, 150, 255) -- mid gray
t.actor_editor.actor = Color(70, 130, 180, 255) -- steel blue
t.actor_editor.component = Color(46, 139, 87, 255) -- sea green
t.actor_editor.property = Color(80, 80, 80, 255) -- dark gray

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
