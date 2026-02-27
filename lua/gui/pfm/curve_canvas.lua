-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/curve.lua")

local Element = util.register_class("gui.CurveCanvas", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 128)
	local elCurve = gui.create("curve", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elCurve:SetHorizontalRange(0.0, 1.0)
	elCurve:SetVerticalRange(0.0, 1.0)
	self.m_elCurve = elCurve

	self.m_points = {}
end
function Element:SetHorizontalRange(x, y)
	self.m_elCurve:SetHorizontalRange(x, y)
end
function Element:SetVerticalRange(x, y)
	self.m_elCurve:SetVerticalRange(x, y)
end
function Element:GetPoints()
	return self.m_points
end
function Element:UpdateCurve()
	local elCurve = self.m_elCurve
	elCurve:BuildCurve(self.m_points)

	self:CallCallbacks("OnCurveUpdated")
end
function Element:AddPoint(p)
	table.insert(self.m_points, p)
	self:UpdateCurve()
end
function Element:NormalizedPointToValue(p)
	local xRange = self.m_elCurve:GetHorizontalRange()
	local yRange = self.m_elCurve:GetVerticalRange()
	local v = p:Copy()
	v.x = xRange.x + (v.x * (xRange.y - xRange.x))
	v.y = yRange.x + (v.y * (yRange.y - yRange.x))
	return v
end
function Element:ValueToNormalizedPoint(v)
	local xRange = self.m_elCurve:GetHorizontalRange()
	local yRange = self.m_elCurve:GetVerticalRange()
	local p = v:Copy()
	p.x = (p.x - xRange.x) / (xRange.y - xRange.x)
	p.y = (p.y - yRange.x) / (yRange.y - yRange.x)
	return p
end
function Element:OnThink()
	if self:IsDrawing() == false then
		self:SetThinkingEnabled(false)
		return
	end
	local curPos = self:GetCursorPos()
	local dtPos = curPos - self.m_lastCursorPos
	if dtPos:Length() < 2.0 then
		return
	end
	local normPos = curPos:Copy()
	normPos.x = normPos.x / self:GetWidth()
	normPos.y = normPos.y / self:GetHeight()
	normPos.y = 1.0 - normPos.y
	if #self.m_points > 0 then
		-- The curve can't go backwards, so if the cursor moves backwards, we'll just start removing points
		local value = self:NormalizedPointToValue(normPos)
		local updateCursor = false
		for i = #self.m_points, 1, -1 do
			local p = self.m_points[i]
			if p.x >= value.x then
				self.m_points[i] = nil
				if dtPos.x < 0.0 then
					value.y = p.y
					updateCursor = true
				end
			else
				break
			end
		end
		normPos = self:ValueToNormalizedPoint(value)
		if updateCursor then
			local pos = self:GetAbsolutePos()
			pos = pos + Vector2(normPos.x, 1.0 - normPos.y) * self:GetSize()
			input.set_cursor_pos(pos)
		end
	end
	self:AddPoint(self:NormalizedPointToValue(normPos))

	self.m_lastCursorPos = curPos
end
function Element:Clear()
	self.m_points = {}
	self:UpdateCurve()
end
function Element:IsDrawing()
	return self.m_drawing or false
end
function Element:StartDrawing()
	self.m_drawing = true
	self:SetThinkingEnabled(true)
	self.m_lastCursorPos = self:GetCursorPos()
	self:AddPoint(self.m_lastCursorPos)
end
function Element:EndDrawing()
	self.m_drawing = false
	self:SetThinkingEnabled(false)
end
gui.register("curve_canvas", Element)
