include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(248, 248, 248, 255)
t.background.secondary = Color(255, 255, 255, 255)
t.background.selected = Color(228, 228, 228)

t.text = {}
t.text.body = Color(0, 0, 0)

t.BACKGROUND_COLOR_HOVER = Color(48, 48, 48, 255)
t.BACKGROUND_COLOR_OUTLINE = Color(228, 228, 228)

t.TIMELINE_BACKGROUND_COLOR = Color(200, 200, 200)
t.TIMELINE_LABEL_COLOR = Color(192, 192, 192)

t.ICON_CACHE = gui.PFMIconCache()

t.BUTTON_BACKGROUND_COLOR = Color(255, 255, 255)
t.BUTTON_BACKGROUND_COLOR_PRESSED = Color(225, 225, 225)
t.BUTTON_ICON_COLOR = Color(90, 90, 90)

t.SLIDER_FILL_COLOR = Color.RoyalBlue

t.STYLE_SHEETS = {}
t.STYLE_SHEETS[".stop-top"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}
t.STYLE_SHEETS[".stop-bottom"] = {
	["stop-color"] = "#" .. Color(230, 230, 230):ToHexColor(), --t.BUTTON_BACKGROUND_COLOR:ToHexColor(),
}
t.STYLE_SHEETS[".rect"] = {
	["stroke"] = "#" .. Color.White:ToHexColor(),
}

local skin = {}

gui.register_skin("pfm_light", t, skin, "pfm")
