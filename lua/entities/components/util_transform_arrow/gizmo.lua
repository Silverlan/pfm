--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/gizmo.lua")

local Component = ents.UtilTransformArrowComponent

function Component:UpdateTransformLine()
	if util.is_valid(self.m_elLine) then
		local vpData = ents.ClickComponent.get_viewport_data()
		if vpData ~= nil then
			local cam = ents.ClickComponent.get_camera()
			local rotationPivot = cam:WorldSpaceToScreenSpace(self:GetEntity():GetPos())
			local posCursor = input.get_cursor_pos()
			rotationPivot =
				Vector2(vpData.x + rotationPivot.x * vpData.width, vpData.y + rotationPivot.y * vpData.height)

			self.m_elLine:SetStartPos(Vector2(posCursor.x, posCursor.y))
			self.m_elLine:SetEndPos(rotationPivot)
			self.m_elLine:SizeToContents()
		end
	end

	pfm.tag_render_scene_as_dirty()
end

function Component:IsActive()
	local c = self:GetEntity():GetComponent(ents.COMPONENT_TRANSFORM_CONTROLLER)
	return (c ~= nil and c:IsActive())
end

function Component:OnTransformChanged(pos, rot, scale)
	local transformC = self:GetBaseUtilTransformComponent()
	local type = self:GetType()
	if type == ents.TransformController.TYPE_TRANSLATION then
		transformC:SetAbsTransformPosition(pos)
	elseif type == ents.TransformController.TYPE_ROTATION then
		transformC:SetTransformRotation(rot)
	elseif type == ents.TransformController.TYPE_SCALE then
		transformC:SetTransformScale(scale)
	end
end

function Component:StartTransform(hitPos)
	local c = self:AddEntityComponent("transform_controller")
	c:SetAxis(self:GetAxis())
	c:SetRelative(self:IsRelative())
	c:SetType(self:GetType())
	c:SetSpace(self:GetSpace())
	c:StartTransform(hitPos)
	util.remove(self.m_cbOnTransformChanged)
	self.m_cbOnTransformChanged = c:AddEventCallback(
		ents.TransformController.EVENT_ON_TRANSFORM_CHANGED,
		function(pos, rot, scale)
			self:OnTransformChanged(pos, rot, scale)
		end
	)

	self:SetSelected(true)
	self:UpdateColor()
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)

	util.remove(self.m_elLine)
	if self:GetType() == ents.TransformController.TYPE_ROTATION then
		local elLine = gui.create("WILine")
		self.m_elLine = elLine
	end

	input.set_binding_layer_enabled("pfm_transform", true)
	input.update_effective_input_bindings()
	pfm.tag_render_scene_as_dirty()
end

function Component:StopTransform()
	local c = self:GetEntity():GetComponent(ents.COMPONENT_TRANSFORM_CONTROLLER)
	if c == nil then
		return
	end
	util.remove(self.m_elLine)
	self:SetSelected(false)
	self:UpdateColor()
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_END)

	input.set_binding_layer_enabled("pfm_transform", false)
	input.update_effective_input_bindings()
	pfm.tag_render_scene_as_dirty()
end
