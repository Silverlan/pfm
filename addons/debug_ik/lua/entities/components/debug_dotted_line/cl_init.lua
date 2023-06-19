--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.DebugDottedLine", BaseEntityComponent)

Component:RegisterMember("StartPosition", udm.TYPE_VECTOR3, Vector(0, 0, 0))
Component:RegisterMember("EndPosition", udm.TYPE_VECTOR3, Vector(0, 0, 0))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:DrawDottedLine(startPos, endPos, color)
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(color)
	drawInfo:SetDuration(0.1)

	local dir = endPos - startPos
	local len = dir:Length()
	dir:Normalize()

	local segmentLength = 0.5
	local clearSegmentLength = 0.25
	local f = 0.0
	local i = 0
	while true do
		local fNext = f + (i % 2 == 0 and segmentLength or clearSegmentLength)
		fNext = math.min(fNext, len)
		if i % 2 == 0 then
			debug.draw_line(startPos + dir * f, startPos + dir * fNext, drawInfo)
		end
		f = fNext
		i = i + 1
		if f >= len then
			break
		end
	end
end
function Component:OnTick()
	self:DrawDottedLine(self:GetStartPosition(), self:GetEndPosition(), self:GetEntity():GetColor())
end
ents.COMPONENT_DEBUG_DOTTED_LINE = ents.register_component("debug_dotted_line", Component)
