--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/materials/ember.lua")

util.register_class("unirender.EmberShader",unirender.Shader)
function unirender.EmberShader:__init()
	unirender.Shader.__init(self)
end
function unirender.EmberShader:InitializeCombinedPass(desc,outputNode)
	local ember = desc:AddNode(unirender.NODE_EMBER_MATERIAL)
	ember:SetProperty(unirender.Node.ember_material.IN_BLEND,0.2)
	ember:SetProperty(unirender.Node.ember_material.IN_COLOR,Vector(1,0.04,0))
	ember:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_SURFACE)
end
function unirender.EmberShader:InitializeAlbedoPass(desc,outputNode)
	desc:CombineRGB(1,1,1):Link(outputNode,unirender.Node.output.IN_SURFACE)
end
unirender.register_shader("ember",unirender.EmberShader)
