--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")

util.register_class("gui.PFMControlsMenu",gui.VBox)
function gui.PFMControlsMenu:__init()
	gui.VBox.__init(self)
end
function gui.PFMControlsMenu:OnInitialize()
	gui.VBox.OnInitialize(self)

	self.m_controls = {}
	self:SetAutoFillContents(true)
end
function gui.PFMControlsMenu:AddControl(name,ctrl) self.m_controls[name] = ctrl end
function gui.PFMControlsMenu:GetControl(name) return self.m_controls[name] end
function gui.PFMControlsMenu:AddToggleControl(name,identifier,checked,onChange)
	local el = gui.create("WIToggleOption",self)
	el:SetText(locale.get_text(name))
	el:SetChecked(checked)
	el:SetTooltip(locale.get_text(name .. "_desc"))
	if(onChange ~= nil) then el:GetCheckbox():AddCallback("OnChange",onChange) end
	if(identifier ~= nil) then self:AddControl(identifier,el) end
	return el
end
function gui.PFMControlsMenu:AddSliderControl(name,identifier,default,min,max,onChange,stepSize,integer)
	local slider = gui.create("WIPFMSlider",self)
	slider:SetText(locale.get_text(name))
	slider:SetRange(min,max)
	slider:SetDefault(default)
	if(integer ~= nil) then slider:SetInteger(integer) end
	if(stepSize ~= nil) then slider:SetStepSize(stepSize) end
	if(onChange ~= nil) then slider:AddCallback("OnLeftValueChanged",onChange) end
	if(identifier ~= nil) then self:AddControl(identifier,slider) end
	return slider
end
gui.register("WIPFMControlsMenu",gui.PFMControlsMenu)
