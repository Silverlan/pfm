--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMButton", gui.Base)

gui.PFMButton.create = function(parent, matUnpressed, matPressed, onPressed)
	local bt = gui.create("WIPFMButton", parent)
	bt:SetMaterials(matUnpressed, matPressed)
	if onPressed ~= nil then
		bt:AddCallback("OnPressed", onPressed)
	end
	return bt
end

function gui.PFMButton:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetSize(64, 64)
	self.m_icon = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_icon:GetColorProperty():Link(self:GetColorProperty())

	self.m_pressed = false
	self.m_enabled = true
end
function gui.PFMButton:SetText(text)
	if util.is_valid(self.m_text) == false then
		self.m_text = gui.create("WIText", self)
		self.m_text:SetFont("pfm_medium")
		self.m_text:SetColor(Color(182, 182, 182))
	end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParent()
	self.m_text:SetAnchor(0.5, 0.5, 0.5, 0.5)
end
function gui.PFMButton:SetEnabledColor(col)
	self.m_enabledColor = col
end
function gui.PFMButton:SetDisabledColor(col)
	self.m_disabledColor = col
end
function gui.PFMButton:SetEnabled(enabled)
	if enabled == self:IsEnabled() then
		return
	end
	if enabled == false then
		self:SetActivated(false)
	end
	self.m_enabled = enabled
	local color = enabled and (self.m_enabledColor or Color.White) or (self.m_disabledColor or Color(128, 128, 128))
	self:SetColor(color)
end
function gui.PFMButton:IsEnabled()
	return self.m_enabled
end
function gui.PFMButton:IsActivated()
	return self.m_pressed
end
function gui.PFMButton:SetActivated(activated)
	if self:IsEnabled() == false then
		return
	end
	self.m_pressed = activated
	self:SetMaterial(activated and self.m_pressedMaterial or self.m_unpressedMaterial)
end
function gui.PFMButton:SetPressedMaterial(mat)
	self.m_pressedMaterial = mat
	if self:IsActivated() then
		self:SetMaterial(mat)
	end
end
function gui.PFMButton:SetUnpressedMaterial(mat)
	self.m_unpressedMaterial = mat
	if self:IsActivated() == false then
		self:SetMaterial(mat)
	end
end
function gui.PFMButton:SetMaterials(unpressedMat, pressedMat)
	self.m_unpressedMaterial = unpressedMat
	self.m_pressedMaterial = pressedMat
	self:SetMaterial(self.m_pressed and pressedMat or unpressedMat)
	local mat = game.load_material(unpressedMat)
	if mat == nil then
		return
	end
	local texInfo = mat:GetTextureInfo("diffuse_map")
	if texInfo == nil then
		return
	end
	self:SetSize(texInfo:GetWidth(), texInfo:GetHeight())
end
function gui.PFMButton:SetMaterial(mat)
	if mat ~= nil and util.is_valid(self.m_icon) then
		self.m_icon:SetMaterial(mat)
	end
end
function gui.PFMButton:SetupContextMenu(fPopulateContextMenu, openOnClick)
	self.m_fPopulateContextMenu = fPopulateContextMenu
	local w = 12
	self.m_contextTrigger = gui.create("WIBase", self, self:GetWidth() - w, 0, w, self:GetHeight(), 1, 0, 1, 0)
	self.m_contextTrigger:SetMouseInputEnabled(true)
	self.m_contextTrigger:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button ~= input.MOUSE_BUTTON_LEFT or self:IsEnabled() == false then
			return util.EVENT_REPLY_UNHANDLED
		end
		if state == input.STATE_PRESS then
			self:OpenContextMenu()
		end
		return util.EVENT_REPLY_HANDLED
	end)
	if openOnClick == true then
		self:AddCallback("OnPressed", function()
			self:OpenContextMenu()
		end)
	end
end
function gui.PFMButton:OpenContextMenu()
	if self.m_fPopulateContextMenu == nil then
		return
	end
	self:SetActivated(true)
	local pContext = gui.open_context_menu()
	if util.is_valid(pContext) == false then
		return
	end
	local pos = self:GetAbsolutePos()
	pContext:SetPos(pos.x, pos.y + self:GetHeight())
	self.m_fPopulateContextMenu(pContext)
	pContext:Update()

	pContext:AddCallback("OnRemove", function()
		if self:IsValid() then
			self:SetActivated(false)
		end
	end)
end
function gui.PFMButton:OnPressed() end
function gui.PFMButton:MouseCallback(button, state, mods)
	if self:IsEnabled() == false then
		return util.EVENT_REPLY_UNHANDLED
	end
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:SetActivated(true)
		elseif state == input.STATE_RELEASE then
			if self:OnPressed() ~= true and self:CallCallbacks("OnPressed") ~= true and self:IsValid() then
				self:SetActivated(false)
			end
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("WIPFMButton", gui.PFMButton)

----------

util.register_class("gui.PFMGenericButton", gui.PFMButton)
function gui.PFMGenericButton:OnInitialize()
	gui.PFMButton.OnInitialize(self)
	self.m_segments = {}

	local btL = gui.create("WITexturedRect", self)
	btL:SetMaterial("gui/pfm/bt_left")
	btL:SizeToTexture()
	btL:GetColorProperty():Link(self:GetColorProperty())
	self.m_elLeft = btL

	local btR = gui.create("WITexturedRect", self)
	btR:SetMaterial("gui/pfm/bt_right")
	btR:SizeToTexture()
	btR:GetColorProperty():Link(self:GetColorProperty())
	self.m_elRight = btR

	self:SetPressedMaterial("gui/pfm/bt_middle_activated")
	self:SetUnpressedMaterial("gui/pfm/bt_middle")
	self:SetText("")
	self.m_text:ClearAnchor()
	self.m_text:SetZPos(1)
end
function gui.PFMGenericButton:ReallocateMiddleSegments(requestSize)
	local szUnit = 24 -- Width of "gui/pfm/bt_middle"
	local size = requestSize
	local m = requestSize % szUnit
	if m > 0 then
		size = size + (szUnit - m)
	end

	local count = size / szUnit

	for i = #self.m_segments, count + 1 do
		util.remove(self.m_segments[i])
		self.m_segments[i] = nil
	end

	for i = 1, count do
		local btM = gui.create("WITexturedRect", self)
		btM:SetMaterial("gui/pfm/bt_middle")
		btM:SizeToTexture()
		btM:GetColorProperty():Link(self:GetColorProperty())
		table.insert(self.m_segments, btM)
	end
	return size
end
function gui.PFMGenericButton:SetMaterial(mat)
	local matLeft = "gui/pfm/bt_left"
	local matRight = "gui/pfm/bt_right"
	if self:IsActivated() then
		matLeft = matLeft .. "_activated"
		matRight = matRight .. "_activated"
	end
	self.m_elLeft:SetMaterial(matLeft)
	self.m_elRight:SetMaterial(matRight)

	for _, el in ipairs(self.m_segments) do
		el:SetMaterial(mat)
	end
end
function gui.PFMGenericButton:OnUpdate()
	local sz = self.m_text:GetWidth()
	local margin = 20
	local middleSize = sz + margin
	middleSize = self:ReallocateMiddleSegments(middleSize)
	local totalSize = self.m_elLeft:GetWidth() + self.m_elRight:GetWidth() + middleSize
	local x = self.m_elLeft:GetRight()
	for _, el in ipairs(self.m_segments) do
		el:SetX(x)
		x = el:GetRight()
	end
	self.m_elRight:SetX(x)

	self.m_text:CenterToParentX()
	self.m_text:SetY(5)
	self:SetWidth(totalSize)
end
gui.register("WIPFMGenericButton", gui.PFMGenericButton)
