--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

cycles.Node.glass_material = {
	IN_COLOR = "color",
	IN_ROUGHNESS = "roughness",
	IN_IOR = "ior",
	OUT_SHADER = "shader"
}
cycles.NODE_GLASS_MATERIAL = cycles.register_node("glass_material",function(desc)
	-- This implementation is equivalent to https://docs.blender.org/manual/en/dev/render/cycles/optimizations/reducing_noise.html#render-cycles-reducing-noise-glass-and-transp-shadows
	local inColor = desc:RegisterInput(cycles.Socket.TYPE_COLOR,cycles.Node.glass_material.IN_COLOR,Vector(0.8,0.8,0.8))
	local inRoughness = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.glass_material.IN_ROUGHNESS,0.0)
	local inIOR = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.glass_material.IN_IOR,0.3)
	local outShader = desc:RegisterOutput(cycles.Socket.TYPE_CLOSURE,cycles.Node.glass_material.OUT_SHADER)
	desc:SetPrimaryOutputSocket(outShader)

	local lp = desc:AddNode(cycles.NODE_LIGHT_PATH)
	local min = desc:AddMathNode(cycles.Node.math.TYPE_MINIMUM,lp:GetOutputSocket(cycles.Node.light_path.OUT_IS_SHADOW_RAY),lp:GetOutputSocket(cycles.Node.light_path.OUT_IS_REFLECTION_RAY))

	local glass = desc:AddNode(cycles.NODE_GLASS_BSDF)
	glass:SetProperty(cycles.Node.glass_bsdf.IN_DISTRIBUTION,cycles.Node.glass_bsdf.DISTRIBUTION_BECKMANN)
	inColor:Link(glass:GetInputSocket(cycles.Node.glass_bsdf.IN_COLOR))
	inRoughness:Link(glass:GetInputSocket(cycles.Node.glass_bsdf.IN_ROUGHNESS))
	inIOR:Link(glass:GetInputSocket(cycles.Node.glass_bsdf.IN_IOR))

	local translucent = desc:AddNode(cycles.NODE_TRANSLUCENT_BSDF)
	inColor:Link(translucent:GetInputSocket(cycles.Node.translucent_bsdf.IN_COLOR))

	local mix = desc:AddNode(cycles.NODE_MIX_CLOSURE)
	min:GetPrimaryOutputSocket():Link(mix:GetInputSocket(cycles.Node.mix_closure.IN_FAC))
	glass:GetPrimaryOutputSocket():Link(mix:GetInputSocket(cycles.Node.mix_closure.IN_CLOSURE1))
	translucent:GetPrimaryOutputSocket():Link(mix:GetInputSocket(cycles.Node.mix_closure.IN_CLOSURE2))

	mix:GetPrimaryOutputSocket():Link(outShader)
end)
