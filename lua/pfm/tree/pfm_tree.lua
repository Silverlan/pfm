--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.Tree")

include("pfm_tree_node.lua")

function pfm.Tree:__init()
	self.m_rootNode = pfm.Tree.Node()
end

function pfm.Tree:GetRootNode()
	return self.m_rootNode
end
