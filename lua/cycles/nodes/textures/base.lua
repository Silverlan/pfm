--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/logic.lua")

unirender.Node.albedo_texture = {
	IN_TEXTURE = "texture",
	IN_ALPHA_MODE = "alpha_mode",
	IN_ALPHA_CUTOFF = "alpha_cutoff",
	IN_COLOR_FACTOR = "color_factor",
	IN_ALPHA_FACTOR = "alpha_factor",
	IN_UV = "uv",
	OUT_COLOR = "color",
	OUT_ALPHA = "alpha"
}
unirender.NODE_ALBEDO_TEXTURE = unirender.register_node("albedo_texture",function(desc)
	local inTexture = desc:RegisterProperty(unirender.Socket.TYPE_STRING,unirender.Node.albedo_texture.IN_TEXTURE,unirender.get_texture_path("error"))
	local inAlphaMode = desc:RegisterInput(unirender.Socket.TYPE_ENUM,unirender.Node.albedo_texture.IN_ALPHA_MODE,game.Material.ALPHA_MODE_OPAQUE)
	local inAlphaCutoff = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.albedo_texture.IN_ALPHA_CUTOFF,0.5)
	local inColorFactor = desc:RegisterInput(unirender.Socket.TYPE_COLOR,unirender.Node.albedo_texture.IN_COLOR_FACTOR,Vector(1,1,1))
	local inAlphaFactor = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.albedo_texture.IN_ALPHA_FACTOR,1.0)
	local inUv = desc:RegisterInput(unirender.Socket.TYPE_VECTOR,unirender.Node.albedo_texture.IN_UV,Vector())

	local outColor = desc:RegisterOutput(unirender.Socket.TYPE_COLOR,unirender.Node.albedo_texture.OUT_COLOR)
	local outAlpha = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.albedo_texture.OUT_ALPHA)
	desc:SetPrimaryOutputSocket(outColor)

	local nodeAlbedo = desc:AddTextureNode(inTexture)
	--local texCoord = desc:AddNode(unirender.NODE_TEXTURE_COORDINATE)
	--local uv = texCoord:GetOutputSocket(unirender.Node.texture_coordinate.OUT_UV) *20.0
	--uv:Link(nodeAlbedo,unirender.Node.image_texture.IN_VECTOR)
	inUv:Link(nodeAlbedo,unirender.Node.image_texture.IN_VECTOR)
	local albedoColor = nodeAlbedo:GetPrimaryOutputSocket() *inColorFactor

	local alpha = nodeAlbedo:GetOutputSocket(unirender.Node.image_texture.OUT_ALPHA)
	local isOpaque = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_OPAQUE)
	local isMasked = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_MASK)
	local isBlend = inAlphaMode:IsEqualTo(game.Material.ALPHA_MODE_BLEND)

	alpha = alpha *inAlphaFactor
	local finalAlpha = unirender.Socket(0)
	finalAlpha = finalAlpha +isOpaque
	finalAlpha = finalAlpha +isBlend *alpha
	finalAlpha = finalAlpha +isMasked *alpha:GreaterThanOrEqualTo(inAlphaCutoff)

	-- finalAlpha = finalAlpha *desc:AddNode(unirender.NODE_LIGHT_PATH):GetOutputSocket(unirender.Node.light_path.OUT_TRANSPARENT_DEPTH):LessThan(2)

	finalAlpha:Link(outAlpha)
	albedoColor:Link(outColor)
end)

unirender.Node.emission_texture = {
	IN_TEXTURE = "texture",
	IN_USE_ALPHA_CHANNEL = "use_alpha_channel",
	IN_COLOR_FACTOR = "color_factor",
	OUT_COLOR = "color"
}
unirender.NODE_EMISSION_TEXTURE = unirender.register_node("emission_texture",function(desc)
	local inTexture = desc:RegisterProperty(unirender.Socket.TYPE_STRING,unirender.Node.emission_texture.IN_TEXTURE,unirender.get_texture_path("error"))
	local inUseAlphaChannel = desc:RegisterInput(unirender.Socket.TYPE_BOOL,unirender.Node.emission_texture.IN_USE_ALPHA_CHANNEL,false)
	local inColorFactor = desc:RegisterInput(unirender.Socket.TYPE_COLOR,unirender.Node.emission_texture.IN_COLOR_FACTOR,Vector(1,1,1))

	local outColor = desc:RegisterOutput(unirender.Socket.TYPE_COLOR,unirender.Node.emission_texture.OUT_COLOR)
	desc:SetPrimaryOutputSocket(outColor)

	local nodeColor = desc:AddTextureNode(inTexture)
	local color = nodeColor:GetPrimaryOutputSocket() *(1.0 -inUseAlphaChannel)
	local a = nodeColor:GetOutputSocket(unirender.Node.image_texture.OUT_ALPHA)
	color = color +desc:CombineRGB(a,a,a) *inUseAlphaChannel
	color = color *inColorFactor

	color:Link(outColor)
end)
