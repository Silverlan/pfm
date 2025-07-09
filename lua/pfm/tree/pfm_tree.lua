-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("pfm.Tree")

include("pfm_tree_node.lua")

function pfm.Tree:__init()
	self.m_rootNode = pfm.Tree.Node()
end

function pfm.Tree:GetRootNode()
	return self.m_rootNode
end
