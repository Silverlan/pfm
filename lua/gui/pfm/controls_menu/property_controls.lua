--[[
    Copyright (C) 2025 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("controls_menu.lua")

local Element = util.register_class("gui.PFMPropertyControls", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetAutoSizeToContents(false, true)
	local controls = gui.create("WIPFMControlsMenu", self)
	controls:SetAutoFillContentsToWidth(true)
	controls:SetAutoFillContentsToHeight(false)
	controls:SetFixedHeight(false)
	controls:AddCallback("OnContentsUpdated", function()
		self:UpdateMarkers()
	end)

	self.m_cbPropertyControlAdded = pfm.add_event_listener(
		"OnActorPropertyControlAdded",
		function(actor, targetPath, type, wrapper)
			local elContainer = wrapper:GetContainerElement()
			if util.is_valid(elContainer) then
				if udm.is_animatable_type(type) then
					local marker = gui.create("WIKeyframeMarker", self)
					marker:SetName("keyframe_marker")
					self.m_markerManager:AddMarker(marker, actor, targetPath, type)
					elContainer:AddIcon(marker)
					marker:SetY(4)
				end
			end
		end
	)

	self.m_controls = controls

	self.m_markerManager = gui.KeyframeMarkerManager()
end
function Element:OnRemove()
	util.remove(self.m_cbPropertyControlAdded)
	self.m_markerManager:Clear()
end
function Element:OnUpdate()
	self:UpdateMarkers()
end
function Element:UpdateMarkers() end
function Element:OnSizeChanged(w, h)
	self.m_controls:SetWidth(w)
end
function Element:GetControlsMenu()
	return self.m_controls
end
gui.register("WIPFMPropertyControls", Element)
