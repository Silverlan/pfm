-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
local TimelineEditorBase = util.register_class("gui.pfm.TimelineEditorBase", gui.Base)
function TimelineEditorBase:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetScrollInputEnabled(true)
end
function TimelineEditorBase:SetTimeline(timeline)
	self.m_timeline = timeline
end
function TimelineEditorBase:GetTimeline()
	return self.m_timeline
end
function TimelineEditorBase:ScrollCallback(x, y)
    self:ZoomTimeAxis(y)
    return util.EVENT_REPLY_HANDLED
end
function TimelineEditorBase:ZoomTimeAxis(am)
    local elRef = self.m_timeline
	local timeLine = self.m_timeline:GetTimeline()
	local timeAxis = timeLine:GetTimeAxis():GetAxis()

	local isAltDown = input.is_alt_key_down()
    if(isAltDown) then
	    local cursorPos = input.get_cursor_pos()
        local relCursorPos = cursorPos - elRef:GetAbsolutePos()
        pivotTime = timeAxis:GetStartOffset() + timeAxis:XDeltaToValue(relCursorPos.x)
    else
	    local playhead = elRef:GetPlayhead()
        pivotTime = playhead:GetTimeOffset()
    end

    timeAxis:SetZoomLevel(timeAxis:GetZoomLevel() - (am / 20.0), pivotTime)
    timeLine:Update()
end
