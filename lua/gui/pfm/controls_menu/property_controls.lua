-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("controls_menu.lua")

local Element = util.register_class("gui.PFMPropertyControls", gui.Base)

Element.impl = Element.impl or { count = 0 }

local function initialize_keyframe_marker_manager()
	Element.impl.markerManager = gui.KeyframeMarkerManager()
	Element.impl.cbPropertyControlAdded = pfm.add_event_listener(
		"OnActorPropertyControlAdded",
		function(actor, targetPath, type, wrapper, elPropertyControls)
			local elContainer = wrapper:GetContainerElement()
			if util.is_valid(elContainer) then
				-- Boolean types are currently not supported
				if udm.is_animatable_type(type) and type ~= udm.TYPE_BOOLEAN then
					local marker = gui.create("keyframe_marker", elPropertyControls)
					marker:SetName("keyframe_marker")
					Element.impl.markerManager:AddMarker(marker, actor, targetPath, type)
					elContainer:AddIcon(marker)
					marker:SetY(4)
				end
			end
		end
	)
end

local function clear_keyframe_marker_manager()
	Element.impl.markerManager:Clear()
	util.remove(Element.impl.cbPropertyControlAdded)
end

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	if Element.impl.count == 0 then
		initialize_keyframe_marker_manager()
	end
	Element.impl.count = Element.impl.count + 1

	self:SetAutoSizeToContents(false, true)
	local controls = gui.create("pfm_controls_menu", self)
	controls:SetAutoFillContentsToWidth(true)
	controls:SetAutoFillContentsToHeight(false)
	controls:SetFixedHeight(false)
	controls:AddCallback("OnContentsUpdated", function()
		self:UpdateMarkers()
	end)

	self.m_controls = controls

	self.m_markerManager = gui.KeyframeMarkerManager()
end
function Element:OnRemove()
	Element.impl.count = Element.impl.count - 1
	if Element.impl.count == 0 then
		clear_keyframe_marker_manager()
	end
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
gui.register("pfm_property_controls", Element)
