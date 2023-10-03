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
		if #points > 0 then
			local times = {}
			local values = {}
			for _, p in ipairs(points) do
				table.insert(times, p.x)
				table.insert(values, p.y)
			end
			local actor = pfm.dereference(self.m_canvasData.actor)
			if actor ~= nil then
				local channel, animClip = actor:FindAnimationChannel(self.m_canvasData.propertyPath)
				if channel ~= nil then
					local cmd = pfm.create_command(
						"keyframe_property_composition",
						actor,
						self.m_canvasData.propertyPath,
						self.m_canvasData.valueBaseIndex
					)
					local editorChannel, editorData, animClip = actor:FindEditorChannel(self.m_canvasData.propertyPath)
					if editorChannel ~= nil then
						local graphCurve = editorChannel:GetGraphCurve()
						local keyData = graphCurve:GetKey(self.m_canvasData.valueBaseIndex)
						local numKeyframes = keyData:GetTimeCount()
						if numKeyframes > 0 then
							-- Delete all keyframes within range of new animation data
							local tStart = points[1].x
							local tEnd = points[#points].x

							local preKeyframeOutside
							local preKeyframeInside
							local postKeyframeInside
							local postKeyframeOutside
							for i = 0, numKeyframes - 1 do
								local kfTime = keyData:GetTime(i)
								if kfTime <= tStart then
									preKeyframeOutside = i
								end

								if kfTime >= tStart and kfTime <= tEnd then
									preKeyframeInside = preKeyframeInside or i
									postKeyframeInside = i
								end
								if kfTime >= tEnd then
									postKeyframeOutside = postKeyframeOutside or i
								end
							end

							-- Delete inner keyframes
							if preKeyframeInside ~= nil and postKeyframeInside ~= nil then
								for i = preKeyframeInside, postKeyframeInside do
									local t = keyData:GetTime(i)
									cmd:AddSubCommand(
										"delete_keyframe",
										actor,
										self.m_canvasData.propertyPath,
										t,
										self.m_canvasData.valueBaseIndex
									)
								end
							end

							-- If the new animation data intersects the segment between two keyframes, we'll apply
							-- curve fitting automatically.
							local curveFittingStartIdx = preKeyframeOutside or preKeyframeInside
							local curveFittingEndIdx = postKeyframeOutside or postKeyframeInside
							if
								curveFittingStartIdx ~= nil
								and curveFittingEndIdx ~= nil
								and curveFittingStartIdx ~= curveFittingEndIdx
							then
								local channel = actor:FindAnimationChannel(self.m_canvasData.propertyPath)
								if channel ~= nil then
									local tLowerKf = keyData:GetTime(curveFittingStartIdx)
									local tUpperKf = keyData:GetTime(curveFittingEndIdx)
									local panimaChannel = channel:GetPanimaChannel()
									local valueType = panimaChannel:GetValueType()
									local oldTimes, oldValues = panimaChannel:GetDataInRange(tLowerKf, tUpperKf)
									if udm.get_numeric_component_count(valueType) > 1 then
										local tmpValues = {}
										for _, val in ipairs(oldValues) do
											table.insert(
												tmpValues,
												udm.get_numeric_component(self.m_canvasData.valueBaseIndex, valueType)
											)
										end
										oldValues = tmpValues
									end

									local tmpChannel = panima.Channel()
									tmpChannel:GetValueArray():SetValueType(udm.TYPE_FLOAT)
									tmpChannel:InsertValues(oldTimes, oldValues)
									tmpChannel:InsertValues(times, values)
									print("Key fitting in time range ", tLowerKf, tUpperKf)
									local keyframes = pfm.udm.Channel.calculate_curve_fitting_keyframes(
										tmpChannel:GetTimes(),
										tmpChannel:GetValues()
									)

									if #keyframes > 0 then
										cmd:AddSubCommand(
											"apply_curve_fitting",
											actor,
											self.m_canvasData.propertyPath,
											keyframes,
											udm.TYPE_FLOAT,
											self.m_canvasData.valueBaseIndex
										)
									end
								end
							end
						end
					end

					local panimaChannel = channel:GetPanimaChannel()
					local valueType = panimaChannel:GetValueType()
					local n = udm.get_numeric_component_count(valueType)
					if n > 1 then
						-- Channel type is a composite type; We have to expand the values
						local newValues = {}
						for i, t in ipairs(times) do
							local v = panimaChannel:GetInterpolatedValue(t, false)
							v = udm.set_numeric_component(v, self.m_canvasData.valueBaseIndex, valueType, values[i])
							table.insert(newValues, v)
						end
						values = newValues
					end
					cmd:AddSubCommand(
						"set_animation_channel_range_data",
						actor,
						self.m_canvasData.propertyPath,
						times,
						values,
						valueType
					)

					pfm.undoredo.push("set_animation_channel_range_data", cmd)()
				end
			end
		end
	end
	util.remove(self.m_canvasData.canvas)
	util.remove(self.m_canvasData.callbacks)
	self.m_canvasData = nil
end
