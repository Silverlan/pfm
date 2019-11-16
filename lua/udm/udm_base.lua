--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.BaseItem")

function udm.BaseItem:__init(class,value)
	self.m_parents = {}
end

function udm.BaseItem:Initialize() end

function udm.BaseItem:GetParents() return self.m_parents end

function udm.BaseItem:FindParent(filter)
	for _,parent in ipairs(self.m_parents) do
		if(filter(parent)) then return parent end
	end
end

function udm.BaseItem:IsAttribute() return false end
function udm.BaseItem:IsElement() return false end

function udm.BaseItem:GetTypeName() return udm.get_type_name(self:GetType()) end
