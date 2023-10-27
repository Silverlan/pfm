--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("element_connector_line.lua")
include("element_selection.lua")
include("modal_overlay.lua")

local Element = util.register_class("gui.TutorialSlide", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_highlights = {}
	self.m_highlightItems = {}
	self.m_namedHighlights = {}
	self.m_messageBoxes = {}
	self.m_viewportTargets = {}
	self:SetSize(64, 64)

	self.m_cbAudioEnabled = console.add_change_callback("pfm_tutorial_audio_enabled", function(old, new)
		self:UpdateAudio()
	end)
	self:SetThinkingEnabled(true)
end
function Element:OnThink()
	if self.m_lastNextUiElementIndex ~= gui.get_next_gui_element_index() then
		self.m_lastNextUiElementIndex = gui.get_next_gui_element_index()
		for _, data in ipairs(self.m_namedHighlights) do
			local els = {}
			local elsPaths = {}
			local elRoot = gui.get_base_element()
			data.targetElements = data.targetElements or {}
			for i, path in ipairs(data.els) do
				local te = data.targetElements[i]
				if te ~= nil and te.element:IsValid() then
					-- if te.element:IsHidden() == false then
					table.insert(els, te.element)
					table.insert(elsPaths, te.path)
				-- end
				else
					local el = self:FindElementByPath(path, elRoot, true)
					if el == nil or el == elRoot then
						break
					end
					table.insert(els, el)
					table.insert(elsPaths, path)
					data.targetElements[i] = {
						element = el,
						path = path,
					}
				end
			end
			if #els == #data.els then
				local valid = true
				if data.prevEls == nil or #els ~= #data.prevEls then
					valid = false
				else
					for i = 1, #els do
						if util.is_same_object(els[i], data.prevEls[i]) == false then
							valid = false
							break
						end
					end
				end
				if valid == false then
					util.remove(data.elOutline)
				end
				if util.is_valid(data.elOutline) == false then
					local elOutline = gui.create("WIElementSelectionOutline", self:DetermineHighlightItemParent(els))
					elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MEDIUM)
					elOutline:SetTargetElement(els)
					elOutline:Update()
					table.insert(self.m_highlightItems, elOutline)
					data.elOutline = elOutline
					data.prevEls = els
					if elsPaths[#els] == self.m_primaryHighlightItemIdentifier then
						self:SetPrimaryHighlightItem(self.m_primaryHighlightItemIdentifier, elOutline)
					end
				end
			else
				util.remove(data.elOutline)
			end
		end

		if
			self.m_arrowTarget ~= nil
			and type(self.m_arrowTarget) == "string"
			and util.is_valid(self.m_arrowTargetElement) == false
		then
			local elRoot = gui.get_base_element()
			local el = self:FindElementByPath(self.m_arrowTarget, elRoot)
			if util.is_valid(el) and util.is_same_object(el, elRoot) then
				el = nil
			end
			self.m_arrowTargetElement = el
		end
	end
	self:UpdateConnectorLine()
end
function Element:OnRemove()
	if self.m_sound ~= nil then
		self.m_sound:Stop()
	end
	util.remove(self.m_cbAudioEnabled)
	util.remove(self.m_highlightItems)

	for _, t in ipairs(self.m_viewportTargets) do
		util.remove(t.resources)
	end

	for _, data in ipairs(self.m_namedHighlights) do
		util.remove(data.elOutline)
	end
end
-- If the target element(s) are attached to the same root (e.g. the filmmaker) as the tutorial slide, we can just use the slide as the parent.
-- However in some cases the target element(s) may have a different root, e.g. if the target element is a context menu, in which case we need to create the highlight item
-- without a parent, because otherwise it will be rendered behind the target element(s) and therefore be invisible.
function Element:DetermineHighlightItemParent(els)
	if type(els) ~= "table" then
		els = { els }
	end
	if util.is_valid(self.m_tutorial) == false then
		return
	end
	local root = self.m_tutorial:GetParent()
	if root == nil then
		return
	end
	local allSharesParent = true
	for _, el in ipairs(els) do
		if el:IsValid() then
			local sharesParent = false
			local p = el:GetParent()
			while p ~= nil do
				if util.is_same_object(p, root) then
					sharesParent = true
					break
				end
				p = p:GetParent()
			end
			if sharesParent == false then
				allSharesParent = false
				break
			end
		end
	end

	if allSharesParent then
		return self
	end
	return nil
end
function Element:AddViewportTarget(pos, fGetSourcePos, successDistance)
	local ent = ents.create("env_sprite")
	ent:SetKeyValue("texture", "effects/target_indicator")
	ent:SetKeyValue("scale", "2.0")
	ent:SetKeyValue("bloom_scale", "1.0")
	ent:SetKeyValue("color", "255 255 255 255")
	ent:SetPos(pos)
	ent:Spawn()

	local t = { ent }

	local isInRange = false
	local entLine
	if fGetSourcePos ~= nil then
		entLine = ents.create("debug_dotted_line")
		local ddlC = entLine:GetComponent(ents.COMPONENT_DEBUG_DOTTED_LINE)
		if ddlC ~= nil then
			ddlC:SetStartPosition(pos)
			ddlC:SetEndPosition(fGetSourcePos())
		end
		entLine:Spawn()

		local cb = game.add_callback("Think", function()
			if util.is_valid(ddlC) then
				ddlC:SetEndPosition(fGetSourcePos())

				isInRange = (ddlC:GetStartPosition():Distance(ddlC:GetEndPosition()) <= successDistance)
				local col = isInRange and Color.Lime or Color.Red
				if ent:IsValid() then
					ent:SetColor(col)
				end
				ddlC:GetEntity():SetColor(col)
			end
		end)

		table.insert(t, entLine)
		table.insert(t, cb)
	end
	table.insert(self.m_viewportTargets, {
		resources = t,
	})
	return {
		spriteEntity = ent,
		lineEntity = entLine,
		isInRange = function()
			return isInRange
		end,
	}
end
function Element:SetTutorial(t)
	self.m_tutorial = t
end
function Element:FindPanelByWindow(identifier)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	return pm:GetWindowFrame(identifier)
end
function Element:FindElementByPath(path, baseElement, includeHidden)
	if type(path) == "string" then
		path = util.Path.CreateFilePath(path)
	end
	local root = baseElement or tool.get_filmmaker()
	local pathComponents = path:ToComponents()
	local function find_descendant(elBase)
		local el = elBase
		for _, c in ipairs(pathComponents) do
			local children = el:FindDescendantsByName(c)
			for i = #children, 1, -1 do
				local child = children[i]
				if child:IsHidden() and includeHidden ~= true then
					table.remove(children, i)
				end
			end
			if #children == 0 then
				return false
			end
			el = children[1]
		end
		return el
	end
	local elChild = find_descendant(root)
	if elChild == false and baseElement == nil then
		for cat, frame in pairs(tool.get_filmmaker():GetFrames()) do
			for _, tabData in ipairs(frame:GetTabs()) do
				local window = frame:GetDetachedTabWindow(tabData.identifier)
				if util.is_valid(window) then
					local el = gui.get_base_element(window)
					if el ~= nil then
						elChild = find_descendant(el)
					end
				end
			end
		end
	end
	return elChild or (baseElement ~= false and root) or nil
end
function Element:GetBackButton()
	return self.m_buttonPrev
end
function Element:GetContinueButton()
	return self.m_buttonNext
end
function Element:GetEndButton()
	return self.m_buttonEnd
end
function Element:AddLocationMarker(pos)
	local ent = ents.create("env_particle_system")
	ent:SetKeyValue("loop", "0")
	ent:SetKeyValue("particle_file", "tutorial_viewport")
	ent:SetKeyValue("particle", "location_highlight")
	ent:SetKeyValue("transform_with_emitter", "0")
	ent:SetKeyValue("orientation_type", "3")
	ent:SetKeyValue("static_scale", "0.4")
	ent:Spawn()

	ent:SetPos(pos)
	ent:SetAngles(EulerAngles(-90, 0, 0))

	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if ptC ~= nil then
		ptC:Start()
	end
	return ent
end
function Element:GetPrimaryHighlightItem()
	return self.m_primaryHighlightItem
end
function Element:SetPrimaryHighlightItem(item, el)
	local elCur = self:GetPrimaryHighlightItem()
	if type(elCur) ~= "string" and util.is_valid(elCur) then
		elCur:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MEDIUM)
	end

	local itemOutline = el or item
	if type(itemOutline) ~= "string" then
		itemOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MAJOR)
	end
	self.m_primaryHighlightItemIdentifier = (type(item) == "string") and item or nil
	self.m_primaryHighlightItem = itemOutline
end
function Element:SetArrowTarget(tgt)
	self.m_arrowTarget = tgt
end
function Element:AddHighlight(el, setAsArrowTarget)
	if type(el) == "string" then
		local o = self:FindElementByPath(el, false)
		if o ~= nil then
			self:AddHighlight(o)
		end
	end
	local els = el
	if type(els) ~= "table" then
		els = { els }
	end
	if #els == 0 then
		return
	end
	if type(els[1]) == "string" then
		table.insert(self.m_namedHighlights, {
			els = els,
		})
		self:SetPrimaryHighlightItem(els[#els])
		if setAsArrowTarget == true then
			self:SetArrowTarget(el)
		end
		return
	end
	local elFirst = els[1]
	if util.is_valid(elFirst) == false then
		if setAsArrowTarget == true then
			self:SetArrowTarget(el)
		end
		return
	end
	local elOutline = gui.create("WIElementSelectionOutline", self:DetermineHighlightItemParent(els))
	elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MEDIUM)
	elOutline:SetTargetElement(els)
	elOutline:Update()
	table.insert(self.m_highlightItems, elOutline)
	table.insert(self.m_highlights, elOutline)

	self:SetPrimaryHighlightItem(elOutline)
	if setAsArrowTarget == true then
		self:SetArrowTarget(el)
	end
	return elFirst, elOutline
end
function Element:SetFocusElement(el)
	if util.is_valid(el) == false then
		return
	end
	self.m_elFocus = el
	local elOutline = gui.create("WIElementSelectionOutline", self:DetermineHighlightItemParent(el))
	elOutline:SetTargetElement(el)
	elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MINOR)
	table.insert(self.m_highlightItems, elOutline)
	table.insert(self.m_highlights, elOutline)
end
function Element:CreateButton(parent, text, f)
	local elBt = gui.create("WIPFMGenericButton", parent)
	elBt:SetText(text)
	elBt:AddCallback("OnPressed", function()
		f()
		return util.EVENT_REPLY_HANDLED
	end)
	elBt:SizeToContents()
	elBt:Update()
	return elBt
end
function Element:SetIdentifier(identifier)
	self.m_identifier = identifier
end
function Element:AddGenericMessageBox(locArgs)
	local identifier = gui.Tutorial.tutorial_identifier .. "_" .. self.m_identifier
	local tutorialData = gui.Tutorial.registered_tutorials[gui.Tutorial.tutorial_identifier]
	local audioFile = "pfm/" .. tutorialData.path .. "/" .. self.m_identifier .. ".mp3"
	self:AddMessageBox(pfm.LocStr("pfm_tut_" .. identifier, locArgs), audioFile)
end
function Element:UpdateCurrentSlideText(currentSlideIndex, totalSlideCount)
	if util.is_valid(self.m_elCurSlide) == false then
		return
	end
	self.m_elCurSlide:SetText(tostring(currentSlideIndex + 1) .. "/" .. tostring(totalSlideCount))
	self.m_elCurSlide:SizeToContents()
end
function Element:OnSizeChanged(w, h)
	for _, msgBoxInfo in ipairs(self.m_messageBoxes) do
		if msgBoxInfo.element:IsValid() then
			local fw = (msgBoxInfo.frameSize.x > 0) and (w / msgBoxInfo.frameSize.x) or 0
			local fh = (msgBoxInfo.frameSize.y > 0) and (h / msgBoxInfo.frameSize.y) or 0
			local pos = msgBoxInfo.element:GetPos()
			pos.x = pos.x * fw
			pos.y = pos.y * fh
			msgBoxInfo.element:SetPos(pos)
			msgBoxInfo.frameSize = Vector2i(w, h)
		end
	end
end
function Element:FindConnectorLineTarget()
	if type(self.m_arrowTarget) == "string" then
		local function get_highlight_name(i)
			local t = self.m_namedHighlights[i]
			if t == nil then
				return
			end
			return t.els[#t.els]
		end
		local function get_highlight_element(i)
			local t = self.m_namedHighlights[i]
			if t == nil then
				return
			end
			local tEl = t.targetElements[#t.targetElements]
			if tEl == nil then
				return
			end
			return tEl.element
		end
		local el = self.m_arrowTargetElement
		if util.is_valid(el) == false and self.m_arrowTarget == get_highlight_name(#self.m_namedHighlights) then
			-- If the arrow target is the same as the last highlighted item, we'll assume that the highlighted item is a child of the
			-- previous highlight items, and we'll use one of them as the arrow target instead.
			for i = #self.m_namedHighlights, 1, -1 do
				el = get_highlight_element(i)
				if util.is_valid(el) then
					if el:IsHidden() then
						el = nil
					else
						break
					end
				end
			end
		end
		return el
	end
	return util.is_valid(self.m_arrowTarget) and self.m_arrowTarget or self.m_focusElement
end
function Element:UpdateConnectorLine()
	local el = self:FindConnectorLineTarget()
	if util.is_valid(self.m_connectorLine) then
		if util.is_valid(el) == false then
			util.remove(self.m_connectorLine)
			return
		end
		if util.is_same_object(el, self.m_connectorLineTarget) then
			return
		end
		util.remove(self.m_connectorLine)
	end
	if util.is_valid(el) == false then
		self.m_connectorLine = nil
		self.m_connectorLineTarget = nil
		return
	end

	local l = gui.create("WIElementConnectorLine", self)
	l:SetSize(self:GetSize())
	l:SetAnchor(0, 0, 1, 1)
	l:Setup(self.m_messageBox, el)
	self.m_connectorLine = l
	self.m_connectorLineTarget = el
end
function Element:AddMessageBox(msg, audioFile)
	local elTgt
	local numHighlights = #self.m_highlights + #self.m_namedHighlights
	if numHighlights > 1 then
		elTgt = self.m_elFocus
	end
	elTgt = elTgt or self.m_highlights[1] or self
	local elFocus = util.is_valid(self.m_elFocus) and self.m_elFocus or elTgt
	self.m_focusElement = elFocus
	local overlay = gui.create("WIModalOverlay", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)

	local el = gui.create("WITransformable", self)
	el:SetDraggable(true)
	el:SetResizable(false)
	el:SetSize(400, 128)
	el:SetMouseInputEnabled(true)
	el:SetZPos(100)
	el:GetDragArea():SetAutoAlignToParent(true)
	self.m_messageBox = el

	local vbox = gui.create("WIVBox", el)

	local msgText = msg
	if util.get_type_name(msgText) == "LocStr" then
		msgText = msgText:GetText()
	end
	local elBox = gui.create_info_box(vbox, msgText)
	elBox:SetAlpha(220)
	elBox:SetWidth(el:GetWidth())
	elBox:SetShowCloseButton(false)
	--elBox:SetSize(el:GetSize())
	table.insert(self.m_messageBoxes, {
		infoBox = elBox,
		vbox = vbox,
		element = el,
		frameSize = self:GetSize(),
		message = message,
	})
	local msgBoxInfo = self.m_messageBoxes[#self.m_messageBoxes]

	elBox:SetSkinCallbacksEnabled(true)
	elBox:AddCallback("OnSkinApplied", function()
		elBox:SizeToContents()
		el:SetHeight(elBox:GetHeight() + 28)
	end)

	if tool.get_filmmaker():IsDeveloperModeEnabled() then
		elBox:SetMouseInputEnabled(true)
		elBox:AddCallback("OnMouseEvent", function(el, button, state, mods)
			if button == input.MOUSE_BUTTON_RIGHT then
				if state == input.STATE_PRESS then
					local pContext = gui.open_context_menu()
					if util.is_valid(pContext) then
						pContext:SetPos(input.get_cursor_pos())
						pContext:AddItem("Translate to " .. locale.get_language(), function()
							self:Translate(msgBoxInfo, msg)
						end)
						pContext:AddItem("Generate Audio for " .. locale.get_language(), function()
							self:GenerateAudio(msgBoxInfo, msg)
						end)
						pContext:Update()
						return util.EVENT_REPLY_HANDLED
					end
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)
	end

	local elCurSlide = gui.create("WIText", elBox)
	elCurSlide:SetText("")
	elCurSlide:SetFont("pfm_small")
	elCurSlide:SetColor(Color.White)
	elCurSlide:SetPos(elBox:GetWidth() - 70, 4)
	elCurSlide:SizeToContents()
	elCurSlide:SetAnchor(1, 0, 1, 0)
	elCurSlide:SetColor(Color.LightGrey)
	self.m_elCurSlide = elCurSlide

	local buttonContainer = gui.create("WIBase", vbox)
	local hbox = gui.create("WIHBox", buttonContainer)
	self.m_buttonPrev = self:CreateButton(
		hbox,
		locale.get_text("pfm_go_back") .. " (" .. pfm.get_key_binding("pfm_tutorial_back") .. ")",
		function()
			self.m_tutorial:PreviousSlide()
		end
	)
	self.m_buttonNext = self:CreateButton(
		hbox,
		locale.get_text("pfm_continue") .. " (" .. pfm.get_key_binding("pfm_tutorial_next") .. ")",
		function()
			self.m_tutorial:NextSlide()
		end
	)
	self.m_buttonNext:SetEnabledColor(Color.Lime)
	self.m_buttonNext:SetDisabledColor(Color.Red)
	hbox:Update()
	self.m_buttonEnd = self:CreateButton(buttonContainer, locale.get_text("pfm_end_tutorial"), function()
		self.m_tutorial:EndTutorial()
	end)
	self.m_buttonEnd:SetX(elBox:GetWidth() - self.m_buttonEnd:GetWidth())
	buttonContainer:SizeToContents()

	local hasAudio = (audioFile ~= nil and asset.exists(audioFile, asset.TYPE_AUDIO))
	if hasAudio then
		local iconAudio = gui.PFMButton.create(el, "gui/pfm/icon_mute", "gui/pfm/icon_mute_activated", function()
			self:ToggleAudio()
			return true
		end)
		iconAudio:SetSize(20, 20)
		iconAudio:SetPos(5, 0)
		iconAudio:SetTooltip(locale.get_text("pfm_toggle_audio"))
		self.m_iconAudio = iconAudio
	end

	elBox:SizeToContents()
	elBox:Update()
	vbox:Update()
	el:SetSize(vbox:GetSize())

	if elTgt ~= self then
		local posAbs = elTgt:GetAbsolutePos()
		local posAbsEnd = posAbs + elTgt:GetSize()
		local spaceLeft = posAbs.x
		local spaceRight = self:GetWidth() - posAbsEnd.x
		local spaceUp = posAbs.y
		local spaceDown = self:GetHeight() - posAbsEnd.y

		local w = elBox:GetWidth()
		local h = elBox:GetHeight()

		local max = math.max(spaceLeft - w, spaceRight - w, spaceUp - h, spaceDown - h)
		local hw = el:GetHalfWidth()
		local hh = el:GetHalfHeight()
		local offset = 0.333
		local oneMinusOffset = 1.0 - offset
		if spaceLeft - w >= max then
			el:SetPos(spaceLeft * oneMinusOffset - hw, self:GetHeight() * offset - hh)
		elseif spaceRight - w >= max then
			el:SetPos(posAbsEnd.x + spaceRight * oneMinusOffset - hw, self:GetHeight() * offset - hh)
		elseif spaceUp - h >= max then
			el:SetPos(self:GetWidth() * offset - hw, spaceUp * oneMinusOffset - hh)
		elseif spaceDown - h >= max then
			el:SetPos(self:GetWidth() * offset - hw, posAbsEnd.y + spaceDown * oneMinusOffset - hh)
		end

		-- If element is out of bounds, re-adjust its position
		local margin = 20
		if el:GetX() <= margin then
			el:SetX(margin)
		elseif el:GetRight() >= self:GetWidth() - margin then
			el:SetX(self:GetWidth() - el:GetWidth() - 20)
		end
		if el:GetY() <= margin then
			el:SetY(margin)
		elseif el:GetBottom() >= self:GetHeight() - margin then
			el:SetY(self:GetHeight() - el:GetHeight() - 20)
		end

		--[[if
			(el:GetRight() > posAbs.x and el:GetX() < posAbsEnd.x)
			and (el:GetBottom() > posAbs.y and el:GetY() < posAbsEnd.y)
		then
			el:SetPos(posAbs.x + elTgt:GetHalfWidth() - hw, posAbs.y + elTgt:GetHalfHeight() - hh)
		end]]

		overlay:SetTarget(elFocus)
	else
		el:CenterToParent()
	end
	overlay:ScheduleUpdate()

	if hasAudio then
		if self.m_sound ~= nil then
			self.m_sound:Stop()
		end
		self.m_sound = sound.create(audioFile, sound.TYPE_VOICE, 1.0, 1.0)
		self:UpdateAudio()
	end

	return el
end
function Element:Translate(msgBoxInfo, msg)
	if util.is_valid(msgBoxInfo.infoBox) == false then
		return
	end
	include("/util/locale/localization_helper.lua")
	include("/util/locale/localization_cache.lua")
	local text = msgBoxInfo.infoBox:GetText()
	local id = msg:GetLocaleIdentifier()
	local locCache = util.locale.LocaleCache("en")
	local englishText = locCache:GetRawText(id)
	local cat = locCache:GetCategory(id)
	if englishText == nil or cat == nil then
		return
	end
	local batchTranslator = util.ai.BatchTranslator()
	batchTranslator:Add(cat, id, englishText, locale.get_language())
end
function Element:GenerateAudio(msgBoxInfo, msg)
	if util.is_valid(msgBoxInfo.infoBox) == false then
		return
	end
	include("/util/ai/batch_tutorial_audio_generator.lua")
	local text = msgBoxInfo.infoBox:GetText()
	local id = msg:GetLocaleIdentifier()
	local tutorial = gui.Tutorial.get_current_tutorial_identifier()
	local batchAudioGenerator = util.ai.TutorialAudioGenerator(tutorial, locale.get_language(), id)
	batchAudioGenerator:Add(id)
end
function Element:GetWindow(window)
	return tool.get_filmmaker():GetWindow(window)
end
function Element:OpenWindow(window)
	return tool.get_filmmaker():OpenWindow(window)
end
function Element:GoToWindow(window, minDividerFraction)
	minDividerFraction = minDividerFraction or 0.4
	local window = tool.get_filmmaker():OpenWindow(window)
	tool.get_filmmaker():GoToWindow(window)
	self:SetMinWindowFrameDividerFraction(window, minDividerFraction)
	return window
end
function Element:SetMinWindowFrameDividerFraction(windowIdentifier, fraction)
	return self:SetWindowFrameDividerFraction(windowIdentifier, fraction, true)
end
function Element:GetWindowFrame(windowIdentifier)
	return tool.get_filmmaker():GetWindowFrame(windowIdentifier)
end
function Element:GetWindowFrameDividers(windowIdentifier)
	local frame = self:GetWindowFrame(windowIdentifier)
	if util.is_valid(frame) == false then
		return
	end
	local parent = frame:GetParent()
	if parent == nil then
		return
	end
	local className = parent:GetClass()
	if className ~= "wihbox" and className ~= "wivbox" then
		return
	end
	local children = parent:GetChildren()
	local preDivider
	local postDivider
	for i, c in ipairs(children) do
		if c:GetClass() == "wiresizer" then
			preDivider = c
		end
		if c == frame then
			for j = i, #children do
				if children[j]:GetClass() == "wiresizer" then
					postDivider = children[j]
					break
				end
			end
			break
		end
	end
	return preDivider, postDivider, parent
end
function Element:SetWindowFrameDividerFraction(windowIdentifier, fraction, dontChangeIfLargerFraction)
	local frame = self:GetWindowFrame(windowIdentifier)
	if util.is_valid(frame) == false then
		return
	end
	local preDivider, postDivider, parent = self:GetWindowFrameDividers(windowIdentifier)
	local children = parent:GetChildren()
	for i, c in ipairs(children) do
		if c:GetClass() == "wiresizer" then
			preDivider = c
		end
		if c == frame then
			for j = i, #children do
				if children[j]:GetClass() == "wiresizer" then
					postDivider = children[j]
					break
				end
			end
			break
		end
	end
	if preDivider ~= nil then
		fraction = 1.0 - fraction
		if
			dontChangeIfLargerFraction ~= true
			or (dontChangeIfLargerFraction == true and preDivider:GetFraction() < fraction)
		then
			preDivider:SetFraction(fraction)
		end
		return preDivider
	elseif postDivider ~= nil then
		if
			dontChangeIfLargerFraction ~= true
			or (dontChangeIfLargerFraction == true and postDivider:GetFraction() < fraction)
		then
			postDivider:SetFraction(fraction)
		end
		return postDivider
	end
	-- TODO: What if there is both a pre- and a post-divider?
end
function Element:IsAudioEnabled()
	return console.get_convar_bool("pfm_tutorial_audio_enabled")
end
function Element:UpdateAudio()
	local enabled = self:IsAudioEnabled()
	self.m_iconAudio:SetActivated(not enabled)

	if enabled == false then
		if self.m_sound ~= nil then
			self.m_sound:Stop()
		end
	else
		if self.m_sound ~= nil then
			self.m_sound:Play()
		end
	end
end
function Element:ToggleAudio()
	local enabled = not self:IsAudioEnabled()
	console.run("pfm_tutorial_audio_enabled", enabled and "1" or "0")
end
function Element:SetTutorialCompleted()
	tool.get_filmmaker():SetTutorialCompleted()
	local window = tool.get_filmmaker():GetWindow("tutorial_catalog")
	local explorer = util.is_valid(window) and window:GetExplorer() or nil
	if util.is_valid(explorer) then
		explorer:ReloadPath()
	end
end
gui.register("WITutorialSlide", Element)
