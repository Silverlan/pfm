--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.PFMCoreViewportBase

function Element:GetViewerCamera()
	local ent, c = ents.citerator(ents.COMPONENT_PFM_WORK_CAMERA)()
	if c == nil then
		return
	end
	return ent:GetComponent(ents.COMPONENT_VIEWER_CAMERA)
end
function Element:ScrollCallback(xoffset, yoffset)
	gui.Base.ScrollCallback(self, xoffset, yoffset)
	if self:IsInCameraControlMode() then
		return
	end
	local vc = self:GetViewerCamera()
	local workCameraC = (vc ~= nil) and vc:GetEntity():GetComponent(ents.COMPONENT_PFM_WORK_CAMERA) or nil
	if workCameraC ~= nil then
		pfm.tag_render_scene_as_dirty()
		self:UpdateViewerCameraPose()
		workCameraC:SetPivotDistance(math.max(workCameraC:GetPivotDistance() - yoffset * 10.0, 0.0))
	end
end
function Element:SetRotationModeEnabled(enabled)
	if enabled then
		self:SetPanningModeEnabled(false)
		self:UpdateViewerCameraPose()
	end
	self.m_rotateCamera = enabled

	util.remove(self.m_dbgViewerCameraPivot)
	if enabled then
		local vc = self:GetViewerCamera()
		if util.is_valid(vc) then
			local ent = ents.create("entity")
			ent:AddComponent("debug_draw_axis")
			ent:SetPos(vc:GetPivotPos())
			ent:Spawn()
			self.m_dbgViewerCameraPivot = ent
		end
	end
end
function Element:SetPanningModeEnabled(enabled)
	if enabled then
		self:SetRotationModeEnabled(false)
		self:UpdateViewerCameraPose()
	end
	self.m_panCamera = enabled
end
function Element:UpdateViewerCameraPose()
	local vc = self:GetViewerCamera()
	if vc == nil then
		return
	end
	vc:SetPose(vc:GetEntity():GetPose())
	self:MarkActorAsDirty(vc:GetEntity())
end
function Element:UpdateViewerCamera()
	if self.m_rotateCamera ~= true and self.m_panCamera ~= true then
		return
	end
	pfm.tag_render_scene_as_dirty()
	local cursorPos = self:GetCursorPos()
	local offset = cursorPos - self.m_tLastCursorPos
	if self.m_rotateCamera == true then
		local vc = self:GetViewerCamera()
		if vc ~= nil then
			vc:Rotate(offset.x, offset.y)
			self:MarkActorAsDirty(vc:GetEntity())
			self.m_updateCamera = true
			self.m_bRenderScheduled = true
		end
	end
	if self.m_panCamera == true then
		local vc = self:GetViewerCamera()
		if vc ~= nil then
			local speed = 60.0
			vc:Pan(offset.x * speed, offset.y * speed)
			self:MarkActorAsDirty(vc:GetEntity())
			self.m_updateCamera = true
			self.m_bRenderScheduled = true
		end
	end
	self.m_tLastCursorPos = cursorPos
end
