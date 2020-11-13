--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/logic.lua")

cycles.Node.albedo_texture = {
	IN_TEXTURE = "texture",
	IN_ALPHA_MODE = "alpha_mode",
	IN_ALPHA_CUTOFF = "alpha_cutoff",
	IN_COLOR_FACTOR = "color_factor",
	IN_ALPHA_FACTOR = "alpha_factor",
	IN_UV = "uv",
	OUT_COLOR = "color",
	OUT_ALPHA = "alpha"
}
cycles.NODE_ALBEDO_TEXTURE = cycles.register_node("albedo_texture",function(desc)
	local inTexture = desc:RegisterProperty(cycles.Socket.TYPE_STRING,cycles.Node.albedo_texture.IN_TEXTURE,"E:/projects/pragma/build_winx64/output/materials/errora.dds")
	local inAlphaMode = desc:RegisterInput(cycles.Socket.TYPE_ENUM,cycles.Node.albedo_texture.IN_ALPHA_MODE,game.Material.ALPHA_MODE_OPAQUE)
	local inAlphaCutoff = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.albedo_texture.IN_ALPHA_CUTOFF,0.5)
	local inColorFactor = desc:RegisterInput(cycles.Socket.TYPE_COLOR,cycles.Node.albedo_texture.IN_COLOR_FACTOR,Vector(1,1,1))
	local inAlphaFactor = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.albedo_texture.IN_ALPHA_FACTOR,1.0)
	local inUv = desc:RegisterInput(cycles.Socket.TYPE_VECTOR,cycles.Node.albedo_texture.IN_UV,Vector())

	local outColor = desc:RegisterOutput(cycles.Socket.TYPE_COLOR,cycles.Node.albedo_texture.OUT_COLOR)
	local outAlpha = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.albedo_texture.OUT_ALPHA)
	desc:SetPrimaryOutputSocket(outColor)

	local nodeAlbedo = desc:AddTextureNode(inTexture)
	--local texCoord = desc:AddNode(cycles.NODE_TEXTURE_COORDINATE)
	--local uv = texCoord:GetOutputSocket(cycles.Node.texture_coordinate.OUT_UV) *20.0
	--uv:Link(nodeAlbedo,cycles.Node.image_texture.IN_VECTOR)
	inUv:Link(nodeAlbedo,cycles.Node.image_texture.IN_VECTOR)
	local albedoColor = nodeAlbedo:GetPrimaryOutputSocket() *inColorFactor

	local alpha = nodeAlbedo:GetOutputSocket(cycles.Node.image_texture.OUT_ALPHA)
	local isOpaque = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_OPAQUE)
	local isMasked = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_MASK)
	local isBlend = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_BLEND)

	alpha = alpha *inAlphaFactor
	local finalAlpha = cycles.Socket(0)
	finalAlpha = finalAlpha +isOpaque
	finalAlpha = finalAlpha +isBlend *alpha
	finalAlpha = finalAlpha +isMasked *alpha:GreaterThanOrEqualTo(inAlphaCutoff)

	-- finalAlpha = finalAlpha *desc:AddNode(cycles.NODE_LIGHT_PATH):GetOutputSocket(cycles.Node.light_path.OUT_TRANSPARENT_DEPTH):LessThan(2)

	finalAlpha:Link(outAlpha)
	albedoColor:Link(outColor)
end)

cycles.Node.emission_texture = {
	IN_TEXTURE = "texture",
	IN_USE_ALPHA_CHANNEL = "use_alpha_channel",
	IN_COLOR_FACTOR = "color_factor",
	OUT_COLOR = "color"
}
cycles.NODE_EMISSION_TEXTURE = cycles.register_node("emission_texture",function(desc)
	local inTexture = desc:RegisterProperty(cycles.Socket.TYPE_STRING,cycles.Node.emission_texture.IN_TEXTURE,"E:/projects/pragma/build_winx64/output/materials/errora.dds")
	local inUseAlphaChannel = desc:RegisterInput(cycles.Socket.TYPE_BOOL,cycles.Node.emission_texture.IN_USE_ALPHA_CHANNEL,false)
	local inColorFactor = desc:RegisterInput(cycles.Socket.TYPE_COLOR,cycles.Node.emission_texture.IN_COLOR_FACTOR,Vector(1,1,1))

	local outColor = desc:RegisterOutput(cycles.Socket.TYPE_COLOR,cycles.Node.emission_texture.OUT_COLOR)
	desc:SetPrimaryOutputSocket(outColor)

	local nodeColor = desc:AddTextureNode(inTexture)
	local color = nodeColor:GetPrimaryOutputSocket() *(1.0 -inUseAlphaChannel)
	local a = nodeColor:GetOutputSocket(cycles.Node.image_texture.OUT_ALPHA)
	color = color +desc:CombineRGB(a,a,a) *inUseAlphaChannel
	color = color *inColorFactor

	color:Link(outColor)
end)

cycles.Node.normal_texture = {
	IN_TEXTURE = "texture",
	OUT_NORMAL = "normal"
}
cycles.NODE_NORMAL_TEXTURE = cycles.register_node("normal_texture",function(desc)
	local inTexture = desc:RegisterProperty(cycles.Socket.TYPE_STRING,cycles.Node.normal_texture.IN_TEXTURE,"E:/projects/pragma/build_winx64/output/materials/errora.dds")

	local outNormal = desc:RegisterOutput(cycles.Socket.TYPE_NORMAL,cycles.Node.normal_texture.OUT_NORMAL)
	desc:SetPrimaryOutputSocket(outNormal)

	local normalStrength = 1.0
	local normal = desc:AddNormalMapNode(inTexture,normalStrength)
	normal:Link(outNormal)
end)
