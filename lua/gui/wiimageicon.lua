-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.ImageIcon", gui.Base)
function gui.ImageIcon:__init()
	gui.Base.__init(self)
end
function gui.ImageIcon:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128, 128)

	local bg = gui.create("WIBase", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg = bg

	local el = gui.create("WITexturedRect", bg, 0, 0, bg:GetWidth(), bg:GetHeight(), 0, 0, 1, 1)
	self.m_texture = el

	local textBg = gui.create("WIRect", self, 0, self:GetHeight() - 18, self:GetWidth(), 18, 0, 1, 1, 1)
	textBg:AddStyleClass("label_background")
	self.m_textBg = textBg

	local elText = gui.create("WIText", self)
	elText:SetFont("pfm_small")
	elText:AddStyleClass("label")
	self.m_text = elText

	local outline = gui.create("WIOutlinedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	outline:AddStyleClass("outline")
	self.m_outline = outline

	self:SetSelected(false)
	self:AddStyleClass("image_icon")
end
function gui.ImageIcon:SetImageOnly(imageOnly)
	self.m_textBg:SetVisible(not imageOnly)
	self.m_text:SetVisible(not imageOnly)
	self.m_outline:SetVisible(not imageOnly)
end
function gui.ImageIcon:SetSelected(selected)
	if selected == self.m_selected then
		return
	end
	self.m_selected = selected
	self.m_outline:RemoveStyleClass("outline")
	self.m_outline:RemoveStyleClass("outline_focus")
	self.m_outline:AddStyleClass(selected and "outline_focus" or "outline")
	self.m_outline:RefreshSkin()
	self:CallCallbacks("OnSelectionChanged", selected)
end
function gui.ImageIcon:IsSelected()
	return self.m_selected or false
end
function gui.ImageIcon:GetText()
	return self.m_text:GetText()
end
function gui.ImageIcon:SetText(text)
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParentX()
	self.m_text:SetY(self:GetHeight() - self.m_text:GetHeight() - 4)
end
function gui.ImageIcon:GetTextureElement()
	return self.m_texture
end
function gui.ImageIcon:GetBackgroundElement()
	return self.m_bg
end
function gui.ImageIcon:GetTextBackgroundElement()
	return self.m_textBg
end
function gui.ImageIcon:GetMaterial()
	return self.m_texture:GetMaterial()
end
function gui.ImageIcon:SetMaterial(mat, w, h)
	self.m_texture:SetMaterial(mat)
	w = w or self:GetWidth()
	h = h or self:GetHeight()
	self.m_texture:SetSize(w, h)

	mat = self.m_texture:GetMaterial()
	if mat ~= nil then
		local db = mat:GetPropertyDataBlock()
		local mv = (db ~= nil) and db:AddBlock("pfm_model_view") or nil
		if mv ~= nil then
			local aspectRatio = mv:GetFloat("aspect_ratio", 1.0)
			if aspectRatio ~= 1.0 then
				self.m_texture:SetSize(w, h / aspectRatio)
			end
		end
	end
	self.m_texture:CenterToParent()
end
function gui.ImageIcon:SetTexture(tex, w, h)
	self.m_texture:SetTexture(tex)
	w = w or self:GetWidth()
	h = h or self:GetHeight()

	self.m_texture:SetSize(w, h)
	self.m_texture:CenterToParent()
end
gui.register("WIImageIcon", gui.ImageIcon)
