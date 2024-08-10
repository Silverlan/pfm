if gui.skin_exists("pfm") == true then
	return
end

-------------------------------------------
------------ START OF SETTINGS ------------
-------------------------------------------

local t = {}
t.BACKGROUND_COLOR_DEFAULT = Color(38, 38, 38, 255)
t.BACKGROUND_COLOR_HOVER = Color(48, 48, 48, 255)
t.BACKGROUND_COLOR_SELECTED = Color(58, 58, 58, 255)
t.TEXT_COLOR = Color(200, 200, 200)

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

local function create_gradient(colStart, colEnd)
	return prosper.create_gradient_texture(128, 64, prosper.FORMAT_R8G8B8A8_UNORM, Vector2(0, -1), {
		{ offset = 0.0, color = colStart },
		{ offset = 1.0, color = colEnd },
	})
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
------------ Input fields ------------
skin["input_field"] = {
	Initialize = function(GUI, pElement)
		local bg = gui.create("WIRect", pElement, 0, 0, pElement:GetWidth(), pElement:GetHeight(), 0, 0, 1, 1)
		bg:SetColor(Color(38, 38, 38))
		bg:SetZPos(-10000)
		bg:SetBackgroundElement(true)
		bg:SetName("background")
		pElement.bg = bg

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
		pElement:SetColor(Color(182, 182, 182))
		pElement:SetFont("pfm_medium")
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
				pElement:SetColor(t.BACKGROUND_COLOR_SELECTED)
			end,
		},
		["menu_item_selected_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(t.TEXT_COLOR)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
skin["context_menu"] = {
	children = {
		["context_menu_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(t.BACKGROUND_COLOR_DEFAULT)
			end,
		},
		["context_menu_outline"] = {
			Initialize = function(GUI, pElement) end,
		},
	},
}
skin["menu_bar"] = {
	children = {
		["menu_bar_background"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(t.BACKGROUND_COLOR_DEFAULT)
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
		pElement:SetColor(t.TEXT_COLOR)
	end,
}
skin["witable"] = {
	children = {
		["witext"] = {
			Initialize = function(GUI, pElement)
				pElement:SetColor(t.TEXT_COLOR)
				pElement:SetFont("pfm_medium")
				pElement:SizeToContents()
			end,
		},
	},
}
gui.register_skin("pfm", t, skin, "default")
