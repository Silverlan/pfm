-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util = util or {}

local Class = util.register_class("util.ColorScheme")
function Class:__init(defaultColor)
	self.m_defaultColor = defaultColor or Color.White:Copy()
	self.m_colors = {}
end

function Class:GetDefaultColor()
	return self.m_defaultColor
end
function Class:SetColor(name, col)
	self.m_colors[name] = col
end
function Class:GetColor(name)
	return self.m_colors[name] or self.m_defaultColor
end
