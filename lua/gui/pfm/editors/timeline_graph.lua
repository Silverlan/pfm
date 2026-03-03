-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("timeline_graph_base.lua")

local TimelineEditorGraph = util.register_class("gui.pfm.TimelineEditorGraph", gui.pfm.TimelineEditorGraphBase)

function TimelineEditorGraph:OnInitialize()
	gui.pfm.TimelineEditorGraphBase.OnInitialize(self)

	self.m_grid = gui.create("grid", self.m_bg, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	local session = tool.get_filmmaker():GetSession()
	local settings = session:GetSettings()
	local renderSettings = settings:GetRenderSettings()

	local function updateTimeLayer()
		local frameRate = renderSettings:GetFrameRate()
		if frameRate <= 0 then
			frameRate = 24
		end
		self.m_grid:GetTimeLayer():SetStepSize(1.0 / frameRate)
		self.m_grid:Update()
	end
	self.m_cbUpdateFrameRate = renderSettings:AddChangeListener("frameRate", updateTimeLayer)
	updateTimeLayer()

	self.m_grid:SetXAxis(self.m_timeAxis)
	self.m_grid:SetYAxis(self.m_dataAxis)
end
function TimelineEditorGraph:UpdateAxisRanges(startOffset, zoomLevel, timeStartOffset, timeZoomLevel)
	if util.is_valid(self.m_grid) then
		self.m_grid:SetStartOffsetX(startOffset)
		self.m_grid:SetZoomLevelX(zoomLevel)
		self.m_grid:SetStartOffsetY(timeStartOffset)
		self.m_grid:SetZoomLevelY(timeZoomLevel)
		self.m_grid:Update()
	end
	gui.pfm.TimelineEditorGraphBase.UpdateAxisRanges(self, startOffset, zoomLevel, timeStartOffset, timeZoomLevel)
end
gui.register("pfm_timeline_editor_graph", TimelineEditorGraph)
