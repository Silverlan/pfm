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

	self:BindEvent(ents.ColorComponent.EVENT_ON_COLOR_CHANGED, "OnColorChanged")

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self.m_dbgLines = {}
end
function Component:OnRemove()
	util.remove(self.m_dbgLines)
end
function Component:OnColorChanged()
	local col = self:GetEntity():GetColor():ToVector4()
	for _, l in ipairs(self.m_dbgLines) do
		if l:IsValid() then
			l:SetColor(col)
		end
	end
end
function Component:DrawDottedLine(startPos, endPos, color)
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(color)

	local dir = endPos - startPos
	local len = dir:Length()
	dir:Normalize()

	local segmentLength = 4
	local clearSegmentLength = 2
	local f = 0.0
	local i = 0
	local lines = {}
	while true do
		local fNext = f + (i % 2 == 0 and segmentLength or clearSegmentLength)
		fNext = math.min(fNext, len)
		if i % 2 == 0 then
			table.insert(lines, { startPos + dir * f, startPos + dir * fNext })
			if #lines > 1000 then
				break
			end
		end
		f = fNext
		i = i + 1
		if f >= len then
			break
		end
	end

	for i, line in ipairs(lines) do
		if util.is_valid(self.m_dbgLines[i]) == false then
			self.m_dbgLines[i] = debug.draw_line(line[1], line[2], drawInfo)
		else
			self.m_dbgLines[i]:SetVertexPosition(0, line[1])
			self.m_dbgLines[i]:SetVertexPosition(1, line[2])
			self.m_dbgLines[i]:UpdateVertexBuffer()
		end
	end
	for i = #self.m_dbgLines, #lines + 1, -1 do
		util.remove(self.m_dbgLines[i])
		self.m_dbgLines[i] = nil
	end
end
function Component:OnTick()
	self:DrawDottedLine(self:GetStartPosition(), self:GetEndPosition(), self:GetEntity():GetColor())
end
ents.register_component("debug_dotted_line", Component, "debug")
