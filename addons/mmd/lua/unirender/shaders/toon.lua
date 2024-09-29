--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("pbr.lua")
include("/unirender/nodes/materials/toon.lua")

util.register_class("unirender.ToonShader", unirender.PBRShader)
function unirender.ToonShader:__init()
	unirender.PBRShader.__init(self)
end
function unirender.ToonShader:InitializeCombinedPass(desc, outputNode)
	local mat = self:GetMaterial()
	local albedoColor, alpha = self:AddAlbedoNode(desc, mat)

	local toonMat = desc:AddNode(unirender.TOON_MATERIAL)
	toonMat:SetProperty(unirender.Node.toon_material.IN_AMBIENT_COLOR, Vector(0.1, 0.1, 0.1))
	albedoColor:Link(toonMat, unirender.Node.toon_material.IN_DIFFUSE_COLOR)
	alpha:Link(toonMat, unirender.Node.toon_material.IN_ALPHA)
	toonMat:GetPrimaryOutputSocket():Link(outputNode, unirender.Node.output.IN_SURFACE)
end
unirender.register_shader("toon", unirender.ToonShader)
