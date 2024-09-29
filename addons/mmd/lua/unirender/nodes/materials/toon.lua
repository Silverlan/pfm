--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

unirender.Node.toon_material = {
	IN_AMBIENT_COLOR = "ambient_color",
	IN_DIFFUSE_COLOR = "diffuse_color",
	IN_SPECULAR_COLOR = "specular_color",
	IN_REFLECT = "reflect",
	IN_BASE_TEX_FAC = "base_tex_fac",
	IN_BASE_TEX = "base_tex",
	IN_TOON_TEX_FAC = "toon_tex_fac",
	IN_TOON_TEX = "toon_tex",
	IN_SPHERE_TEX_FAC = "sphere_tex_fac",
	IN_SPHERE_TEX = "sphere_tex",
	IN_SPHERE_MUL = "sphere_mul",
	IN_DOUBLE_SIDED = "double_sided",
	IN_ALPHA = "alpha",
	IN_BASE_ALPHA = "base_alpha",
	IN_TOON_ALPHA = "toon_alpha",
	IN_SPHERE_ALPHA = "sphere_alpha",

	OUT_SHADER = "shader",
	OUT_COLOR = "color",
	OUT_ALPHA = "alpha",
}

local function add_group0(
	desc,
	inAmbientColor,
	inDiffuseColor,
	inBaseTex,
	inBaseTexFac,
	inToonTex,
	inToonTexFac,
	inSphereTex,
	inSphereTexFac,
	inSphereMul
)
	local add0 = desc:AddNode(unirender.NODE_MIX)
	inAmbientColor:Link(add0, unirender.Node.mix.IN_COLOR1)
	inDiffuseColor:Link(add0, unirender.Node.mix.IN_COLOR2)
	add0:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_ADD)
	add0:SetProperty(unirender.Node.mix.IN_USE_CLAMP, true)
	add0:SetProperty(unirender.Node.mix.IN_FAC, 0.6)

	local mul0 = desc:AddNode(unirender.NODE_MIX)
	add0:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(mul0, unirender.Node.mix.IN_COLOR1)
	inBaseTex:Link(mul0, unirender.Node.mix.IN_COLOR2)
	inBaseTexFac:Link(mul0, unirender.Node.mix.IN_FAC)
	mul0:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_MUL)
	mul0:SetProperty(unirender.Node.mix.IN_USE_CLAMP, false)

	local mul1 = desc:AddNode(unirender.NODE_MIX)
	mul0:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(mul1, unirender.Node.mix.IN_COLOR1)
	inToonTex:Link(mul1, unirender.Node.mix.IN_COLOR2)
	inToonTexFac:Link(mul1, unirender.Node.mix.IN_FAC)
	mul1:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_MUL)
	mul1:SetProperty(unirender.Node.mix.IN_USE_CLAMP, false)

	local mul2 = desc:AddNode(unirender.NODE_MIX)
	mul1:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(mul2, unirender.Node.mix.IN_COLOR1)
	inSphereTex:Link(mul2, unirender.Node.mix.IN_COLOR2)
	inSphereTexFac:Link(mul2, unirender.Node.mix.IN_FAC)
	mul2:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_MUL)
	mul2:SetProperty(unirender.Node.mix.IN_USE_CLAMP, false)

	local add1 = desc:AddNode(unirender.NODE_MIX)
	mul1:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(add1, unirender.Node.mix.IN_COLOR1)
	inSphereTex:Link(add1, unirender.Node.mix.IN_COLOR2)
	inSphereTexFac:Link(add1, unirender.Node.mix.IN_FAC)
	add1:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_ADD)
	add1:SetProperty(unirender.Node.mix.IN_USE_CLAMP, false)

	local mix0 = desc:AddNode(unirender.NODE_MIX)
	mul2:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(mix0, unirender.Node.mix.IN_COLOR1)
	add1:GetOutputSocket(unirender.Node.mix.OUT_COLOR):Link(mix0, unirender.Node.mix.IN_COLOR2)
	inSphereMul:Link(mix0, unirender.Node.mix.IN_FAC)
	mix0:SetProperty(unirender.Node.mix.IN_TYPE, unirender.Node.mix.TYPE_BLEND)
	mix0:SetProperty(unirender.Node.mix.IN_USE_CLAMP, false)
	return mix0:GetOutputSocket(unirender.Node.mix.OUT_COLOR)
end
local function add_group1(desc, inAlpha, inBaseAlpha, inToonAlpha, inSphereAlpha)
	local mul0 = desc:AddNode(unirender.NODE_MATH)
	inAlpha:Link(mul0, unirender.Node.math.IN_VALUE1)
	inBaseAlpha:Link(mul0, unirender.Node.math.IN_VALUE2)
	mul0:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_MULTIPLY)
	mul0:SetProperty(unirender.Node.math.IN_USE_CLAMP, false)

	local mul1 = desc:AddNode(unirender.NODE_MATH)
	mul0:GetOutputSocket(unirender.Node.math.OUT_VALUE):Link(mul1, unirender.Node.math.IN_VALUE1)
	inToonAlpha:Link(mul1, unirender.Node.math.IN_VALUE2)
	mul1:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_MULTIPLY)
	mul1:SetProperty(unirender.Node.math.IN_USE_CLAMP, false)

	local mul2 = desc:AddNode(unirender.NODE_MATH)
	mul1:GetOutputSocket(unirender.Node.math.OUT_VALUE):Link(mul2, unirender.Node.math.IN_VALUE1)
	inSphereAlpha:Link(mul2, unirender.Node.math.IN_VALUE2)
	mul2:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_MULTIPLY)
	mul2:SetProperty(unirender.Node.math.IN_USE_CLAMP, false)
	return mul2:GetOutputSocket(unirender.Node.math.OUT_VALUE)
end
unirender.TOON_MATERIAL = unirender.register_node("toon_material", function(desc)
	local inAmbientColor = desc:RegisterInput(
		unirender.Socket.TYPE_COLOR,
		unirender.Node.toon_material.IN_AMBIENT_COLOR,
		Vector(0.4, 0.4, 0.4)
	)
	local inDiffuseColor = desc:RegisterInput(
		unirender.Socket.TYPE_COLOR,
		unirender.Node.toon_material.IN_DIFFUSE_COLOR,
		Vector(0.8, 0.8, 0.8)
	)
	local inSpecularColor = desc:RegisterInput(
		unirender.Socket.TYPE_COLOR,
		unirender.Node.toon_material.IN_SPECULAR_COLOR,
		Vector(0.8, 0.8, 0.8)
	)
	local inReflect = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_REFLECT, 50.0)
	local inBaseTexFac =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_BASE_TEX_FAC, 1.0)
	local inBaseTex =
		desc:RegisterInput(unirender.Socket.TYPE_COLOR, unirender.Node.toon_material.IN_BASE_TEX, Vector(1, 1, 1))
	local inToonTexFac =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_TOON_TEX_FAC, 1.0)
	local inToonTex =
		desc:RegisterInput(unirender.Socket.TYPE_COLOR, unirender.Node.toon_material.IN_TOON_TEX, Vector(1, 1, 1))
	local inSphereTexFac =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_SPHERE_TEX_FAC, 1.0)
	local inSphereTex =
		desc:RegisterInput(unirender.Socket.TYPE_COLOR, unirender.Node.toon_material.IN_SPHERE_TEX, Vector(1, 1, 1))
	local inSphereMul = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_SPHERE_MUL, 0.0)
	local inDoubleSided =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_DOUBLE_SIDED, 0.0)
	local inAlpha = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_ALPHA, 1.0)
	local inBaseAlpha = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_BASE_ALPHA, 1.0)
	local inToonAlpha = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_TOON_ALPHA, 1.0)
	local inSphereAlpha =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.IN_SPHERE_ALPHA, 1.0)

	local group0 = add_group0(
		desc,
		inAmbientColor,
		inDiffuseColor,
		inBaseTex,
		inBaseTexFac,
		inToonTex,
		inToonTexFac,
		inSphereTex,
		inSphereTexFac,
		inSphereMul
	)

	local group1 = add_group1(desc, inAlpha, inBaseAlpha, inToonAlpha, inSphereAlpha)

	local geo = desc:AddNode(unirender.NODE_GEOMETRY)
	local alpha =
		geo:GetOutputSocket(unirender.Node.geometry.OUT_BACKFACING):LessThan(0.5):Max(inDoubleSided):Min(group1)

	local div0 = desc:AddNode(unirender.NODE_MATH)
	unirender.Socket(1.0):Link(div0, unirender.Node.math.IN_VALUE1)
	inReflect:Link(div0, unirender.Node.math.IN_VALUE2)
	div0:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_DIVIDE)
	div0:SetProperty(unirender.Node.math.IN_USE_CLAMP, true)

	local glossy = desc:AddNode(unirender.NODE_GLOSSY_BSDF)
	inSpecularColor:Link(glossy, unirender.Node.glossy_bsdf.IN_COLOR)
	div0:GetOutputSocket(unirender.Node.math.OUT_VALUE):Link(glossy, unirender.Node.glossy_bsdf.IN_ROUGHNESS)
	glossy:SetProperty(
		unirender.Node.glossy_bsdf.IN_DISTRIBUTION,
		unirender.Node.glossy_bsdf.DISTRIBUTION_MICROFACET_MULTI_GGX
	)

	local diffuse = desc:AddNode(unirender.NODE_DIFFUSE_BSDF)
	group0:Link(diffuse, unirender.Node.diffuse_bsdf.IN_COLOR)
	diffuse:SetProperty(unirender.Node.diffuse_bsdf.IN_ROUGHNESS, 0.0)

	local mix1 = desc:AddNode(unirender.NODE_MIX_CLOSURE)
	diffuse:GetOutputSocket(unirender.Node.diffuse_bsdf.OUT_BSDF):Link(mix1, unirender.Node.mix_closure.IN_CLOSURE1)
	glossy:GetOutputSocket(unirender.Node.glossy_bsdf.OUT_BSDF):Link(mix1, unirender.Node.mix_closure.IN_CLOSURE2)
	mix1:SetProperty(unirender.Node.mix_closure.IN_FAC, 0.02)

	local transparent = desc:AddNode(unirender.NODE_TRANSPARENT_BSDF)
	local mix2 = desc:AddNode(unirender.NODE_MIX_CLOSURE)
	transparent
		:GetOutputSocket(unirender.Node.transparent_bsdf.OUT_BSDF)
		:Link(mix2, unirender.Node.mix_closure.IN_CLOSURE1)
	mix1:GetOutputSocket(unirender.Node.mix_closure.OUT_CLOSURE):Link(mix2, unirender.Node.mix_closure.IN_CLOSURE2)
	alpha:Link(mix2, unirender.Node.mix_closure.IN_FAC)

	local outShader = desc:RegisterOutput(unirender.Socket.TYPE_CLOSURE, unirender.Node.toon_material.OUT_SHADER)
	desc:SetPrimaryOutputSocket(outShader)
	local outColor = desc:RegisterOutput(unirender.Socket.TYPE_COLOR, unirender.Node.toon_material.OUT_COLOR)
	local outAlpha = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT, unirender.Node.toon_material.OUT_ALPHA)
	desc:Link(mix2:GetOutputSocket(unirender.Node.mix_closure.OUT_CLOSURE), outShader)
	desc:Link(group0, outColor)
	desc:Link(alpha, outAlpha)
end)
