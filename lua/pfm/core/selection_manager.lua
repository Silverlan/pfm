-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/pfm/selection.lua")
include("/shaders/pfm/selection_wireframe.lua")

local SelectionManager = util.register_class("pfm.SelectionManager")
function SelectionManager:__init(eventBus)
	self.m_selectionData = {}
	self.m_eventBus = eventBus
	self.m_selectionWireframeEnabled = true
	self.m_showBones = true
end

function SelectionManager:SetSelectionWireframeEnabled(enabled)
	if enabled == self.m_selectionWireframeEnabled then
		return
	end
	self.m_selectionWireframeEnabled = enabled

	self.m_eventBus:Emit("selection.wireframe.changed", self, enabled)
end

function SelectionManager:IsSelectionWireframeEnabled() return self.m_selectionWireframeEnabled end

function SelectionManager:SetShowBones(enabled)
	if enabled == self.m_showBones then
		return
	end
	self.m_showBones = enabled

	self.m_eventBus:Emit("selection.show_bones.changed", self, enabled)
end

function SelectionManager:GetSelectedObjects()
	return self.m_selectionData
end
function SelectionManager:IsSelected(object)
	if self.m_selectionData[object] == nil then
		return false
	end
	return self.m_selectionData[object].selected or false
end

function SelectionManager:Remove()
	self:ClearSelections()
end

function SelectionManager:SetSelectedObjects(tSelected)
	local t = {}
	for object, _ in pairs(self.m_selectionData) do
		t[object] = false
	end
	for _, object in ipairs(tSelected) do
		t[object] = true
	end
	for object, selected in pairs(t) do
		self:SetSelected(object, selected)
	end
end

function SelectionManager:ClearSelections()
	local selections = self.m_selectionData
	self.m_selectionData = {}
	for object, selected in pairs(selections) do
		self.m_eventBus:Emit("selection.object.changed", self, object, false)
	end
	self.m_eventBus:Emit("selection.changed", self)
end

function SelectionManager:SetSelected(object, selected)
	if selected == self:IsSelected(object) then
		return
	end
	if selected == false then
		self.m_selectionData[object] = nil
	else
		self.m_selectionData[object] = {
			selected = true,
		}
	end
	self.m_eventBus:Emit("selection.object.changed", self, object, selected)
	self.m_eventBus:Emit("selection.changed", self)
end

function SelectionManager:Select(object)
	self:SetSelected(object, true)
end
function SelectionManager:Deselect(object)
	self:SetSelected(object, false)
end
