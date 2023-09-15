--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/curve_canvas.lua")

function gui.PFMTimelineGraph:IsInDrawingMode()
	return self.m_canvasData ~= nil
end
function gui.PFMTimelineGraph:StartCanvasDrawing(actor, propertyPath, valueBaseIndex)
	self:EndCanvasDrawing()
	local el = gui.create(
		"WICurveCanvas",
		self.m_graphContainer,
		0,
		0,
		self.m_graphContainer:GetWidth(),
		self.m_graphContainer:GetHeight(),
		0,
		0,
		1,
		1
	)
	local canvasData = {}
	canvasData.canvas = el
	canvasData.callbacks = {}
	canvasData.actor = actor
	canvasData.propertyPath = propertyPath
	canvasData.valueBaseIndex = valueBaseIndex
	local function update_canvas()
		if el:IsValid() == false then
			return
		end
		local x0 = self.m_timeAxis:GetAxis():GetStartOffset()
		local x1 = self.m_timeAxis:GetAxis():XOffsetToValue(self:GetRight())
		el:SetHorizontalRange(x0, x1)

		local y0 = self.m_dataAxis:GetAxis():GetStartOffset()
		local y1 = self.m_dataAxis:GetAxis():XOffsetToValue(self:GetBottom())
		el:SetVerticalRange(y0, y1)
	end
	table.insert(canvasData.callbacks, self:GetDataAxis():GetAxis():AddCallback("OnPropertiesChanged", update_canvas))
	table.insert(canvasData.callbacks, self:GetTimeAxis():GetAxis():AddCallback("OnPropertiesChanged", update_canvas))
	update_canvas()
	el:StartDrawing()

	table.insert(
		canvasData.callbacks,
		el:AddCallback("OnCurveUpdated", function()
			local pm = tool.get_filmmaker()
			local points = el:GetPoints()
			if #points == 0 then
				return
			end
			local p = points[#points]
			pm:SetTimeOffset(p.x)
		end)
	)
	self.m_canvasData = canvasData
end
function gui.PFMTimelineGraph:EndCanvasDrawing()
	if self.m_canvasData == nil then
		return
	end

	if util.is_valid(self.m_canvasData.canvas) then
		self.m_canvasData.canvas:EndDrawing()

		local points = self.m_canvasData.canvas:GetPoints()
		local times = {}
		local values = {}
		for _, p in ipairs(points) do
			table.insert(times, p.x)
			table.insert(values, p.y)
		end
		local actor = pfm.dereference(self.m_canvasData.actor)
		if actor ~= nil then
			pfm.undoredo.push(
				"set_animation_channel_range_data",
				pfm.create_command(
					"set_animation_channel_range_data",
					actor,
					self.m_canvasData.propertyPath,
					times,
					values,
					udm.TYPE_FLOAT
				)
			)()
		end
	end
	util.remove(self.m_canvasData.canvas)
	util.remove(self.m_canvasData.callbacks)
	self.m_canvasData = nil
end
