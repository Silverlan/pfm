--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("fudm.BaseItem")

function fudm.BaseItem:__init(class,value)
	self.m_parents = {}
end

function fudm.BaseItem:Initialize() end

function fudm.BaseItem:GetParents() return self.m_parents end

function fudm.BaseItem:FindParent(filter)
	for _,parent in ipairs(self.m_parents) do
		if(filter(parent)) then return parent end
	end
end

function fudm.BaseItem:IsAttribute() return false end
function fudm.BaseItem:IsElement() return false end

function fudm.BaseItem:GetTypeName() return fudm.get_type_name(self:GetType()) end

function fudm.BaseItem:SaveToBinary(ds) self:WriteToBinary(ds) end
function fudm.BaseItem:LoadFromBinary(ds) end

-- These should be overwritten by derived classes
function fudm.BaseItem:WriteToBinary(ds) end
function fudm.BaseItem:ReadFromBinary(ds) end
