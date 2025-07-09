-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("pbr.lua")

util.register_class("unirender.LightCone", unirender.PBRShader)
function unirender.LightCone:__init()
	unirender.PBRShader.__init(self)
end
function unirender.LightCone:InitializeCombinedPass(desc, outputNode)
	local vol = desc:AddNode(unirender.NODE_PRINCIPLED_VOLUME)
	vol:SetProperty(unirender.Node.principled_volume.IN_COLOR, Vector(0.5, 0.5, 0.5))
	vol:SetProperty(unirender.Node.principled_volume.IN_DENSITY, 0.1)
	vol:SetProperty(unirender.Node.principled_volume.IN_ANISOTROPY, 0.0)
	vol:SetProperty(unirender.Node.principled_volume.IN_ABSORPTION_COLOR, Vector(0, 0, 0))
	vol:SetProperty(unirender.Node.principled_volume.IN_EMISSION_STRENGTH, 0.0)
	vol:SetProperty(unirender.Node.principled_volume.IN_EMISSION_COLOR, Vector(0, 0, 0))
	vol:SetProperty(unirender.Node.principled_volume.IN_BLACKBODY_INTENSITY, 0.0)
	vol:SetProperty(unirender.Node.principled_volume.IN_BLACKBODY_TINT, Vector(0, 0, 0))
	vol:SetProperty(unirender.Node.principled_volume.IN_TEMPERATURE, 1000.0)
	vol:SetProperty(unirender.Node.principled_volume.IN_VOLUME_MIX_WEIGHT, 0.0)
	vol:GetPrimaryOutputSocket():Link(outputNode, unirender.Node.output.IN_VOLUME)
end
unirender.register_shader("light_cone", unirender.LightCone)
