-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.TrimText", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(1, 1)

	local elText = gui.create("WIText", self)
	elText:AddStyleClass("input_field_text")
	elText:GetColorProperty():Link(self:GetColorProperty())
	self.m_elText = elText
end
function Element:SetFont(font)
	self.m_elText:SetFont(font)
	self.m_lenEllipsis = engine.get_text_size("...", font).x
	self:UpdateTruncatedText()
end
function Element:SetText(text)
	self.m_text = text
	self:SetTooltip(text)
	self:UpdateTruncatedText()
end
function Element:UpdateTruncatedText()
	if self.m_text == nil or self.m_lenEllipsis == nil then
		return
	end

	local font = self.m_elText:GetFont()
	local lenEllipsis = self.m_lenEllipsis
	local maxLen = math.max(self:GetWidth() - lenEllipsis, 0)

	local truncatedText = self.m_text
	local numChars = engine.get_truncated_text_length(truncatedText, font, maxLen)
	if numChars < #truncatedText then
		truncatedText = truncatedText:sub(0, numChars) .. "..."
	end
	self.m_elText:CenterToParentY()
	self.m_elText:SetText(truncatedText)
	self.m_elText:SizeToContents()
end
function Element:OnSizeChanged(w, h)
	if util.is_valid(self.m_elText) then
		self:UpdateTruncatedText()
	end
end
gui.register("WITrimText", Element)
