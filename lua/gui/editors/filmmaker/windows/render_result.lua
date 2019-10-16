--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wicontextmenu.lua")

util.register_class("gui.PFMRenderResultWindow")
function gui.PFMRenderResultWindow:__init(parent)
	local frame = gui.create("WIFrame",parent)
	frame:SetTitle(locale.get_text("pfm_render_result"))

	local margin = 10
	local tex = gui.create("WITexturedRect",frame)
	tex:SetSize(256,256)
	tex:SetPos(margin,24)
	self.m_result = tex

	frame:SetWidth(tex:GetRight() +margin)
	frame:SetHeight(tex:GetBottom() +margin *2)
	frame:SetResizeRatioLocked(true)
	frame:SetMinSize(128,128)
	frame:SetMaxSize(1024,1024)
	frame:SetCloseButtonEnabled(false)
	tex:SetAnchor(0,0,1,1)
	tex:SetMouseInputEnabled(true)
	tex:AddCallback("OnMouseEvent",function(tex,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem("Save",function()
				print("TODO: Saving not yet implemented!")
			end)
			pContext:Update()
		end
	end)
	self.m_frame = frame
end
function gui.PFMRenderResultWindow:GetFrame() return self.m_frame end
function gui.PFMRenderResultWindow:SetTexture(tex)
	if(util.is_valid(self.m_result)) then self.m_result:SetTexture(tex) end
end
function gui.PFMRenderResultWindow:Remove()
	if(util.is_valid(self.m_frame)) then self.m_frame:Remove() end
end
function gui.PFMRenderResultWindow:IsValid()
	return util.is_valid(self.m_frame)
end
