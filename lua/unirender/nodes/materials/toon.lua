--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

unirender.Node.glass_material = {
	IN_COLOR = "color",
	IN_ROUGHNESS = "roughness",
	IN_IOR = "ior",
	OUT_SHADER = "shader"
}
unirender.NODE_GLASS_MATERIAL = unirender.register_node("glass_material",function(desc)
	-- This implementation is equivalent to https://docs.blender.org/manual/en/dev/render/cycles/optimizations/reducing_noise.html#render-cycles-reducing-noise-glass-and-transp-shadows
	local inColor = desc:RegisterInput(unirender.Socket.TYPE_COLOR,unirender.Node.glass_material.IN_COLOR,Vector(0.8,0.8,0.8))
	local inRoughness = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.glass_material.IN_ROUGHNESS,0.0)
	local inIOR = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.glass_material.IN_IOR,0.3)
	local outShader = desc:RegisterOutput(unirender.Socket.TYPE_CLOSURE,unirender.Node.glass_material.OUT_SHADER)
	desc:SetPrimaryOutputSocket(outShader)

	local lp = desc:AddNode(unirender.NODE_LIGHT_PATH)
	local min = desc:AddMathNode(unirender.Node.math.TYPE_MINIMUM,lp:GetOutputSocket(unirender.Node.light_path.OUT_IS_SHADOW_RAY),lp:GetOutputSocket(unirender.Node.light_path.OUT_IS_REFLECTION_RAY))

	local glass = desc:AddNode(unirender.NODE_GLASS_BSDF)
	glass:SetProperty(unirender.Node.glass_bsdf.IN_DISTRIBUTION,unirender.Node.glass_bsdf.DISTRIBUTION_BECKMANN)
	inColor:Link(glass:GetInputSocket(unirender.Node.glass_bsdf.IN_COLOR))
	inRoughness:Link(glass:GetInputSocket(unirender.Node.glass_bsdf.IN_ROUGHNESS))
	inIOR:Link(glass:GetInputSocket(unirender.Node.glass_bsdf.IN_IOR))

	local translucent = desc:AddNode(unirender.NODE_TRANSLUCENT_BSDF)
	inColor:Link(translucent:GetInputSocket(unirender.Node.translucent_bsdf.IN_COLOR))

	local mix = desc:AddNode(unirender.NODE_MIX_CLOSURE)
	min:GetPrimaryOutputSocket():Link(mix:GetInputSocket(unirender.Node.mix_closure.IN_FAC))
	glass:GetPrimaryOutputSocket():Link(mix:GetInputSocket(unirender.Node.mix_closure.IN_CLOSURE1))
	translucent:GetPrimaryOutputSocket():Link(mix:GetInputSocket(unirender.Node.mix_closure.IN_CLOSURE2))

	mix:GetPrimaryOutputSocket():Link(outShader)
end)
