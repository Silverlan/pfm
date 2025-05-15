include("/gui/icon_cache.lua")

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.background = {}
t.background.primary = Color(38, 38, 38, 255)
t.background.secondary = Color(54, 54, 54, 255)
t.background.tertiary = Color(20, 20, 20, 255)
t.background.selected = Color(58, 58, 58, 255)

t.button = {}
t.button.background = Color(90, 90, 90)
t.button.background_unpressed = Color.White:Copy()
t.button.background_pressed = Color(150, 150, 150)
t.button.icon = Color(147, 147, 147)

t.slider = {}
t.slider.color = Color.RoyalBlue

t.text = {}
t.text.body = Color(200, 200, 200)
t.text.tab = Color.White:Copy()
t.text.title = Color.White:Copy()
t.text.highlight = Color(30, 144, 255, 255)

t.icon = Color.White:Copy()

t.outline = {}
t.outline.color = Color(58, 58, 58, 255)
t.outline.focus = Color.DodgerBlue:Copy()

t.overlay = {}
t.overlay.color = Color.White:Copy()

t.graph = {}
t.graph.line = Color(255, 255, 255)

t.timeline = {}
t.timeline.text = Color.Black:Copy()
t.timeline.background = Color(80, 80, 80)

t.actor_editor = {}
t.actor_editor.collection = Color(204, 204, 204)
t.actor_editor.actor = Color(248, 128, 112)
t.actor_editor.component = Color(204, 167, 0)
t.actor_editor.property = Color(230, 230, 230)

t.misc = {}
t.misc.beta_info = Color.Red

t.shaderGraph = {
	NODE_BACKGROUND_COLOR_SELECTED = Color(124, 20, 222),
}

t.ICON_CACHE = gui.PFMIconCache()

t.STYLE_SHEETS = {}
t.STYLE_SHEETS[".stop-top"] = {
	["stop-color"] = "#" .. t.button.background:ToHexColor(),
}
t.STYLE_SHEETS[".stop-bottom"] = {
	["stop-color"] = "#" .. t.background.secondary:ToHexColor(),
}

t.ICONS = {}
local nineSlice = {
	leftInset = 10,
	rightInset = 10,
	topInset = 10,
	bottomInset = 10,
}
local buttonIconData = {
	nineSlice = nineSlice,
}
t.ICONS["button"] = {
	material = "gui/pfm/button",
	iconData = buttonIconData,
}
t.ICONS["button_left"] = {
	material = "gui/pfm/button_left",
	iconData = buttonIconData,
}
t.ICONS["button_right"] = {
	material = "gui/pfm/button_right",
	iconData = buttonIconData,
}
t.ICONS["button_middle"] = {
	material = "gui/pfm/button_middle",
	iconData = buttonIconData,
}
t.ICONS["button_tab_left"] = {
	material = "gui/pfm/button_tab_left",
	iconData = buttonIconData,
}
t.ICONS["button_tab_right"] = {
	material = "gui/pfm/button_tab_right",
	iconData = buttonIconData,
}
t.ICONS["button_tab_middle"] = {
	material = "gui/pfm/button_tab_middle",
	iconData = buttonIconData,
}
t.ICONS["button_tab"] = {
	material = "gui/pfm/button_tab",
	iconData = buttonIconData,
}

t.ICONS["theme-toggle-light"] = {
	material = "gui/pfm/icons/brightness-high-fill",
	iconData = {
		width = 12,
		height = 12,
	},
}
t.ICONS["theme-toggle-dark"] = {
	material = "gui/pfm/icons/moon-fill",
	iconData = {
		width = 12,
		height = 12,
	},
}
t.get_icon = function(GUI, name)
	return GUI.ICON_CACHE:Load(GUI.ICONS[name].material, GUI.ICONS[name].iconData, GUI.STYLE_SHEETS)
end

-------------------------------------------
------------- END OF SETTINGS -------------
-------------------------------------------

local function add_skin_element(pElement, el)
	if pElement.m_tSkinElements == nil then
		pElement.m_tSkinElements = {}
	end
	table.insert(pElement.m_tSkinElements, el)
end

local function clear_element(GUI, pElement)
	if pElement.m_tSkinElements ~= nil then
		for _, el in ipairs(pElement.m_tSkinElements) do
			if el:IsValid() then
				el:Remove()
			end
		end
		pElement.m_tSkinElements = nil
	end
end

local function set_icon_material()
	--
end

--[[t.BACKGROUND_GRADIENT = function(t)
	t._BACKGROUND_GRADIENT = t._BACKGROUND_GRADIENT or create_gradient(t.BACKGROUND_GRADIENT_START,t.BACKGROUND_GRADIENT_END)
	return t._BACKGROUND_GRADIENT
end]]

local skin = {}
------------ Timeline ------------
skin["timeline_clip_film"] = {
	Initialize = function(GUI, pElement)
		local elBg = pElement:FindChildByName("background")
		if elBg ~= nil then
			elBg:SetColor(Color(47, 47, 121))
		end
	end,
}
skin["timeline_clip_audio"] = {
	Initialize = function(GUI, pElement)
		local elBg = pElement:FindChildByName("background")
		if elBg ~= nil then
			elBg:SetColor(Color(50, 127, 50))
		end
	end,
}
skin["timeline_clip_overlay"] = {
	Initialize = function(GUI, pElement)
		local elBg = pElement:FindChildByName("background")
		if elBg ~= nil then
			elBg:SetColor(Color(122, 48, 48))
		end
	end,
}
-----------------------------------------
------------- WIProgressBar -------------
skin["wiprogressbar"] = {
	children = {
		["progressbar_label_overlay"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColorRGB(GUI.PROGRESS_BAR_LABEL_OVERLAY_COLOR)
			end,
		},
		["progressbar_label_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColorRGB(GUI.PROGRESS_BAR_LABEL_BACKGROUND_COLOR)
			end,
		},
	},
	Initialize = function(GUI, pElement) end,
}
skin["wislider"] = skin["wiprogressbar"]
-----------------------------------------
------------- WIFileDialog -------------
skin["wifiledialog"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["wislider"] = skin["wiprogressbar"]
-----------------------------------------
------------- WIText -------------
skin["witext"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.text.body)
	end,
}
-----------------------------------------
------------- WIScrollbar -------------
skin["wiscrollbar"] = {
	children = {
		["wibutton"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(Color.Red)
			end,
		},
	},
}
skin["wislider"] = skin["wiprogressbar"]
-----------------------------------------
------------ WIButton ------------
skin["wibutton"] = {
	Initialize = function(GUI, pElement)
		local bg = gui.create("WIRect", pElement)
		bg:SetColor(GUI.background.secondary)
		bg:SetName("background")
		bg:SetAutoAlignToParent(true)
		bg:SetZPos(-2)
		pElement.m_pBackground = bg
		add_skin_element(pElement, bg)

		local fcCursorEntered = function()
			pElement.m_bMouseOver = true
			if pElement.m_bPressed == true then
				return
			end
			if pElement.m_pBackground == nil or not pElement.m_pBackground:IsValid() then
				return
			end
			pElement.m_pBackground:SetColor(GUI.background.secondary)
		end
		local cbCursorEntered = pElement:AddCallback("OnCursorEntered", fcCursorEntered)
		add_skin_element(pElement, cbCursorEntered)
		local cbCursorExited = pElement:AddCallback("OnCursorExited", function()
			pElement.m_bMouseOver = false
			if pElement.m_bPressed == true then
				return
			end
			if pElement.m_pBackground == nil or not pElement.m_pBackground:IsValid() then
				return
			end
			pElement.m_pBackground:SetColor(GUI.background.secondary)
		end)
		add_skin_element(pElement, cbCursorExited)
		local cbMousePressed = pElement:AddCallback("OnMousePressed", function()
			pElement.m_bPressed = true
			if pElement.m_pBackground == nil or not pElement.m_pBackground:IsValid() then
				return
			end
			local gradient = GUI:BUTTON_BACKGROUND_GRADIENT_SELECTED()
			if gradient == nil then
				return
			end
			pElement.m_pBackground:SetColor(GUI.background.secondary)
		end)
		add_skin_element(pElement, cbMousePressed)
		local cbMouseReleased = pElement:AddCallback("OnMouseReleased", function()
			pElement.m_bPressed = false
			if pElement.m_bMouseOver == true then
				fcCursorEntered()
				return
			end
			if pElement.m_pBackground == nil or not pElement.m_pBackground:IsValid() then
				return
			end
			local gradient = GUI:BACKGROUND_GRADIENT()
			if gradient == nil then
				return
			end
			pElement.m_pBackground:SetColor(GUI.background.secondary)
		end)
		add_skin_element(pElement, cbMouseReleased)

		local fcSetSize = function()
			local pText = pElement:GetFirstChild("witext")
			if pText ~= nil and pText:IsValid() then
				pText:SetPos(
					pElement:GetWidth() * 0.5 - pText:GetWidth() * 0.5,
					pElement:GetHeight() * 0.5 - pText:GetHeight() * 0.5
				)
			end
		end
		local cbSetSize = pElement:AddCallback("SetSize", fcSetSize)
		fcSetSize()
		add_skin_element(pElement, cbSetSize)
	end,
	Release = clear_element,
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				local cbSetSize = pElement:AddCallback("SetSize", function()
					local p = pElement:GetParent()
					if not p:IsValid() then
						return
					end
					pElement:SetPos(
						p:GetWidth() * 0.5 - pElement:GetWidth() * 0.5,
						p:GetHeight() * 0.5 - pElement:GetHeight() * 0.5
					)
				end)
				add_skin_element(pElement, cbSetSize)

				pElement:SetColorRGB(Color(255, 255, 255, 255))
				pElement:SetText(pElement:GetText():upper())
				pElement:SizeToContents()
			end,
			Release = clear_element,
		},
	},
}
-----------------------------------------
------------- WITooltip -------------
skin["witooltip"] = {
	Initialize = function(GUI, pElement)
		local pText = pElement:GetFirstChild("witext")
		if pText == nil then
			return
		end
		pText:SetColorRGB(GUI.text.body)
		local pRect = gui.create("WIRect", pElement)
		pRect:SetColor(GUI.background.primary)
		pRect:SetAutoAlignToParent(true)
		pRect:SetZPos(0)

		local pRectOutline = gui.create("WIOutlinedRect", pElement)
		pRectOutline:SetColor(GUI.outline.color)
		pRectOutline:SetAutoAlignToParent(true)
		pRectOutline:SetZPos(0)

		pText:SetZPos(1)

		local cbSize = pText:AddCallback("SetSize", function(pText)
			local sz = pText:GetSize()
			pText:SetPos(10, 5)

			pElement:SetSize(sz.x + 20, sz.y + 10)

			local szWindow = gui.get_window_size()
			if pElement:GetRight() >= szWindow.x then
				pElement:SetX(szWindow.x - pElement:GetWidth())
			end
			if pElement:GetBottom() >= szWindow.y then
				pElement:SetY(szWindow.y - pElement:GetHeight())
			end
		end)
		add_skin_element(pElement, pRect)
		add_skin_element(pElement, pRectOutline)
		add_skin_element(pElement, cbSize)
	end,
	Release = clear_element,
}
-----------------------------------------
------------ Input fields ------------
skin["input_field"] = {
	Initialize = function(GUI, pElement)
		local bg = gui.create("WIRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		bg:SetColor(GUI.background.primary)
		bg:SetZPos(-10000)
		bg:SetBackgroundElement(true)
		bg:SetName("background")
		pElement.bg = bg

		local outline =
			gui.create("WIOutlinedRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		outline:SetColor(GUI.background.secondary)
		outline:SetZPos(-9000)
		outline:SetBackgroundElement(true)
		outline:SetName("outline")
	end,
	Release = function(GUI, pElement)
		local bg = pElement:FindChildByName("background")
		if bg ~= nil then
			bg:Remove()
		end

		local outline = pElement:FindChildByName("outline")
		if outline ~= nil then
			outline:Remove()
		end
	end,
}
skin["input_field_category"] = {
	Initialize = function(GUI, pElement)
		local bg = pElement:FindChildByName("background")
		if bg ~= nil then
			bg:SetColor(Color(64, 64, 64))
		end
	end,
}
skin["input_field_outline"] = {
	Initialize = function(GUI, pElement)
		local outline =
			gui.create("WIOutlinedRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		outline:SetColor(Color(57, 57, 57))
		outline:SetZPos(-9000)
		outline:SetBackgroundElement(true)
		outline:SetName("outline")
	end,
	Release = function(GUI, pElement)
		local bg = pElement:FindChildByName("background")
		if bg ~= nil then
			bg:Remove()
		end
	end,
}
skin["input_field_text"] = {
	Initialize = function(GUI, pElement)
		pElement:SetFont("pfm_medium")
	end,
}
skin["input_field_overlay"] = {
	Initialize = function(GUI, pElement)
		local bg = gui.create("WIRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		bg:SetColor(Color(50, 50, 50))
		bg:SetZPos(-10000)
		bg:SetBackgroundElement(true)
		bg:SetName("background")
		pElement.bg = bg

		local outline =
			gui.create("WIOutlinedRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		outline:SetColor(Color(80, 80, 80))
		outline:SetZPos(-9000)
		outline:SetBackgroundElement(true)
		outline:SetName("outline")
	end,
	Release = function(GUI, pElement)
		local bg = pElement:FindChildByName("background")
		if bg ~= nil then
			bg:Remove()
		end

		local outline = pElement:FindChildByName("outline")
		if outline ~= nil then
			outline:Remove()
		end
	end,
}
skin["infobox"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["menu_item"] = {
	children = {
		["menu_item_selected_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.background.selected)
			end,
		},
		["menu_item_selected_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.text.body)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["selection"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.background.selected)
	end,
}
skin["context_menu"] = {
	children = {
		["context_menu_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.background.primary)
			end,
		},
		["context_menu_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
	},
}
skin["menu_bar"] = {
	Initialize = function(GUI, pElement)
		gui.get_primary_window():SetTitleBarColor(GUI.background.primary)
	end,
	children = {
		["menu_bar_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.background.primary)
			end,
		},
		["menu_item"] = {
			children = {
				["witext"] = {
					Initialize = function(GUI, pElement)
						local el = pElement:FindAncestorByClass("wimenubar")
						if el ~= nil then
							el:ScheduleUpdate()
						end
					end,
				},
			},
		},
	},
}
skin["context_menu_arrow"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.text.body)
	end,
}
skin["witable"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.text.body)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["image_icon"] = {
	children = {
		["label"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.text.body)
			end,
		},
		["label_background"] = {
			Initialize = function(GUI, pElement)
				local col = GUI.background.primary:Copy()
				col.a = 240
				pElement:SetColor(col)
			end,
		},
	},
}
skin["outline"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.outline.focus)
	end,
}
skin["slider_filled"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.slider.color)
	end,
}
skin["frame_titlebar"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.text.body)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["background"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.background.primary)
	end,
}
skin["wishadergraph"] = {
	children = {
		["node_background_selected"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.shaderGraph.NODE_BACKGROUND_COLOR_SELECTED)
			end,
		},
	},
}
skin["background2"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.background.secondary)
	end,
}
skin["background3"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.background.tertiary)
	end,
}
skin["keyframe_marker_static"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(Color.White)
	end,
}
skin["keyframe_marker_animated"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(Color.White)
	end,
}
skin["keyframe_marker_animated_frame"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(Color(230, 75, 61))
	end,
}
skin["theme_toggle"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("theme-toggle-light"))
		pElement:SetColor(GUI.icon)
	end,
}
skin["theme_toggle_light"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("theme-toggle-light"))
		pElement:SetColor(GUI.icon)
	end,
}
skin["theme_toggle_dark"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("theme-toggle-dark"))
		pElement:SetColor(GUI.icon)
	end,
}
skin["button"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button"))
	end,
}
skin["button_left"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_left"))
	end,
}
skin["button_right"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_right"))
	end,
}
skin["button_middle"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_middle"))
	end,
}
skin["button_tab_left"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_tab_left"))
	end,
}
skin["button_tab_right"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_tab_right"))
	end,
}
skin["button_tab_middle"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_tab_middle"))
	end,
}
skin["button_tab"] = {
	Initialize = function(GUI, pElement)
		pElement:SetMaterial(GUI:get_icon("button_tab"))
	end,
}
skin["button_background_unpressed"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.button.background_unpressed)
	end,
}
skin["button_background_pressed"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.button.background_pressed)
	end,
}
skin["button_icon"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.button.icon)
	end,
}
skin["timeline_background"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.timeline.background)
	end,
}
skin["timeline_label"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.timeline.text)
	end,
}
skin["graph_line"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.graph.line)
	end,
}
skin["overlay"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.overlay.color)
	end,
}
skin["act_ed_collection"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.actor_editor.collection)
			end,
		},
	},
}
skin["act_ed_actor"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.actor_editor.actor)
			end,
		},
	},
}
skin["act_ed_component"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.actor_editor.component)
			end,
		},
	},
}
skin["act_ed_property"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.actor_editor.property)
			end,
		},
	},
}
skin["tab_title"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.text.tab)
	end,
}
skin["beta_info"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.misc.beta_info)
	end,
}
skin["text_highlight"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.text.highlight)
	end,
}
------------- InfoBox -------------
skin["infobox"] = {
	children = {
		["bg_info"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.background.primary)
			end,
		},
		["fg_info"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.text.body)
			end,
		},
	},
}
-----------------------------------
gui.register_skin("pfm", t, skin, "default")
