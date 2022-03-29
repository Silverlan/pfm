--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util = util or {}

local Class = util.register_class("util.ColorScheme")
function Class:__init(defaultColor)
	self.m_defaultColor = defaultColor or Color.White:Copy()
	self.m_colors = {}
end

function Class:GetDefaultColor() return self.m_defaultColor end
function Class:SetColor(name,col) self.m_colors[name] = col end
function Class:GetColor(name) return self.m_colors[name] or self.m_defaultColor end
