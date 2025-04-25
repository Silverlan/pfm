if gui.skin_exists("pfm") == true then
	return
end

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.BACKGROUND_COLOR_DEFAULT = Color(38, 38, 38, 255)
t.BACKGROUND_COLOR = t.BACKGROUND_COLOR_DEFAULT:Copy()
t.BACKGROUND_COLOR2 = Color(20, 20, 20, 255)
t.BACKGROUND_COLOR3 = Color(54, 54, 54, 255)
t.BACKGROUND_COLOR_HOVER = Color(48, 48, 48, 255)
t.BACKGROUND_COLOR_SELECTED = Color(58, 58, 58, 255)
t.BACKGROUND_COLOR_OUTLINE = Color(58, 58, 58, 255)

t.TIMELINE_BACKGROUND_COLOR = Color(80, 80, 80)
t.TIMELINE_LABEL_COLOR = Color.Black:Copy()

t.BUTTON_BACKGROUND_COLOR = Color(90, 90, 90)
t.BUTTON_BACKGROUND_COLOR_PRESSED = Color(60, 60, 60)
t.BUTTON_ICON_COLOR = Color(147, 147, 147)

t.OVERLAY_COLOR = Color(255, 255, 255)

t.SLIDER_FILL_COLOR = Color.RoyalBlue
t.TEXT_COLOR = Color(200, 200, 200)
t.shaderGraph = {
	NODE_BACKGROUND_COLOR_SELECTED = Color(124, 20, 222),
}

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
		pElement:SetColor(GUI.TEXT_COLOR)
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
		bg:SetColor(GUI.BACKGROUND_COLOR3)
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
			pElement.m_pBackground:SetColor(GUI.BACKGROUND_COLOR3)
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
			pElement.m_pBackground:SetColor(GUI.BACKGROUND_COLOR3)
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
			pElement.m_pBackground:SetColor(GUI.BACKGROUND_COLOR3)
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
			pElement.m_pBackground:SetColor(GUI.BACKGROUND_COLOR3)
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
		pText:SetColorRGB(GUI.TEXT_COLOR)
		local pRect = gui.create("WIRect", pElement)
		pRect:SetColor(GUI.BACKGROUND_COLOR)
		pRect:SetAutoAlignToParent(true)
		pRect:SetZPos(0)

		local pRectOutline = gui.create("WIOutlinedRect", pElement)
		pRectOutline:SetColor(GUI.BACKGROUND_COLOR_OUTLINE)
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
		bg:SetColor(GUI.BACKGROUND_COLOR_DEFAULT)
		bg:SetZPos(-10000)
		bg:SetBackgroundElement(true)
		bg:SetName("background")
		pElement.bg = bg

		local outline =
			gui.create("WIOutlinedRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		outline:SetColor(GUI.BACKGROUND_COLOR3)
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
				pElement:SetColor(GUI.BACKGROUND_COLOR_SELECTED)
			end,
		},
		["menu_item_selected_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.TEXT_COLOR)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["selection"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BACKGROUND_COLOR_SELECTED)
	end,
}
skin["context_menu"] = {
	children = {
		["context_menu_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.BACKGROUND_COLOR_DEFAULT)
			end,
		},
		["context_menu_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
	},
}
skin["menu_bar"] = {
	Initialize = function(GUI, pElement)
		gui.get_primary_window():SetTitleBarColor(GUI.BACKGROUND_COLOR)
	end,
	children = {
		["menu_bar_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.BACKGROUND_COLOR_DEFAULT)
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
		pElement:SetColor(GUI.TEXT_COLOR)
	end,
}
skin["witable"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.TEXT_COLOR)
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
				pElement:SetColor(GUI.TEXT_COLOR)
			end,
		},
		["label_background"] = {
			Initialize = function(GUI, pElement)
				local col = GUI.BACKGROUND_COLOR:Copy()
				col.a = 240
				pElement:SetColor(col)
			end,
		},
	},
}
skin["outline"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BACKGROUND_COLOR)
	end,
}
skin["slider_filled"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.SLIDER_FILL_COLOR)
	end,
}
skin["frame_titlebar"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(GUI.TEXT_COLOR)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["background"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BACKGROUND_COLOR_DEFAULT)
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
		pElement:SetColor(GUI.BACKGROUND_COLOR2)
	end,
}
skin["background3"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BACKGROUND_COLOR3)
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
skin["button_background"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BUTTON_BACKGROUND_COLOR)
	end,
}
skin["button_background_pressed"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BUTTON_BACKGROUND_COLOR_PRESSED)
	end,
}
skin["button_icon"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.BUTTON_ICON_COLOR)
	end,
}
skin["timeline_background"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.TIMELINE_BACKGROUND_COLOR)
	end,
}
skin["timeline_label"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.TIMELINE_LABEL_COLOR)
	end,
}
skin["overlay"] = {
	Initialize = function(GUI, pElement)
		pElement:SetColor(GUI.OVERLAY_COLOR)
	end,
}
gui.register_skin("pfm", t, skin, "default")
