if gui.skin_exists("pfm_light") == true then
	return
end

include("pfm.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.BACKGROUND_COLOR_DEFAULT = Color(248, 248, 248, 255)
t.BACKGROUND_COLOR2 = Color(220, 220, 220, 255)
t.BACKGROUND_COLOR3 = Color(220, 220, 220, 255)
t.BACKGROUND_COLOR_HOVER = Color(48, 48, 48, 255)
t.BACKGROUND_COLOR_SELECTED = Color(58, 58, 58, 255)
t.SLIDER_FILL_COLOR = Color.RoyalBlue
t.TEXT_COLOR = Color(158, 158, 158)

local skin = {}

gui.register_skin("pfm_light", t, skin, "pfm")
