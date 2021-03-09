--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.Tree.Node")

function pfm.Tree.Node:__init(name,attr)
	self.m_children = {}
	self.m_name = name or ""
	self.m_udmAttribute = attr
end

function pfm.Tree.Node:GetChildren() return self.m_children end
function pfm.Tree.Node:GetName() return self.m_name end
function pfm.Tree.Node:SetName(name) self.m_name = name end

function pfm.Tree.Node:GetAttribute() return self.m_udmAttribute end
function pfm.Tree.Node:SetAttribute(attr) self.m_udmAttribute = attr end

function pfm.Tree.Node:IsLeaf()
	return #self.m_children == 0
end

function pfm.Tree.Node:AddChild()
	local childNode = pfm.Tree.Node()
	table.insert(self.m_children,childNode)
	return childNode
end

function pfm.Tree.Node:AssignUDMItem(name,item)
	self.m_udmAttribute = item
	if(item:IsElement()) then
		for _,prop in ipairs(item:GetProperties()) do
			local child = self:AddChild()
			child:AssignUDMItem(prop)
		end
		return
	end
	if(item:IsAttribute() == false or item:IsArray() == false) then return end
	for _,v in ipairs(item:GetValue()) do
		local child = self:AddChild()
		child:AssignUDMItem(v)
	end
end
