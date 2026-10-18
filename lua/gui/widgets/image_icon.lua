-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.ImageIcon", gui.Base)
function gui.ImageIcon:__init()
	gui.Base.__init(self)
end
function gui.ImageIcon:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128, 128)

	self:AddStyleClass("image-icon")

	local contents = gui.create("vbox", self)
	contents:AddStyleClass("image-icon__content")
	self.m_contents = contents

	local texWrapper = gui.create("vbox", contents)
	texWrapper:AddStyleClass("image-icon__image-wrapper")

	local tex = gui.create("WITexturedRect", texWrapper)
	tex:AddStyleClass("image-icon__image")
	self.m_texture = tex

	local labelContainer = gui.create("vbox", contents)
	labelContainer:AddStyleClass("image-icon__label-container")

	local text = gui.create("WIText", labelContainer)
	text:AddStyleClass("font_small")
	text:AddStyleClass("label")
	text:AddStyleClass("image-icon__label")
	self.m_text = text

	self:SetSelected(false)
end
function gui.ImageIcon:SetSelected(selected)
	if selected == self.m_selected then
		return
	end
	self.m_selected = selected
	self:SetInputState(selected and gui.INPUT_STATE_FOCUSED or gui.INPUT_STATE_NONE)
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
end
function gui.ImageIcon:SetPrefixText(text)
	self.m_text:SetPrefixText(text)
end
function gui.ImageIcon:SetSuffixText(text)
	self.m_text:SetSuffixText(text)
end
function gui.ImageIcon:GetTextureElement()
	return self.m_texture
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
end
function gui.ImageIcon:SetTexture(tex, w, h)
	self.m_texture:SetTexture(tex)
	w = w or self:GetWidth()
	h = h or self:GetHeight()

	self.m_texture:SetSize(w, h)
end
gui.register("image_icon", gui.ImageIcon)
