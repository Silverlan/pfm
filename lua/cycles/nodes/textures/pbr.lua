--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/logic.lua")

cycles.Node.rma_texture = {
	IN_TEXTURE = "texture",
	IN_METALNESS_FACTOR = "metalness_factor",
	IN_ROUGHNESS_FACTOR = "roughness_factor",
	OUT_METALNESS = "metalness",
	OUT_ROUGHNESS = "roughness"
}
cycles.NODE_RMA_TEXTURE = cycles.register_node("rma_texture",function(desc)
	local inTexture = desc:RegisterProperty(cycles.Socket.TYPE_STRING,cycles.Node.rma_texture.IN_TEXTURE,"E:/projects/pragma/build_winx64/output/materials/errora.dds")
	local inMetalnessFactor = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.rma_texture.IN_METALNESS_FACTOR,1.0)
	local inRoughnessFactor = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.rma_texture.IN_ROUGHNESS_FACTOR,1.0)

	local outMetalness = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.rma_texture.OUT_METALNESS)
	local outRoughness = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.rma_texture.OUT_ROUGHNESS)

	local nodeRMA = desc:AddTextureNode(inTexture,cycles.Node.image_texture.TEXTURE_TYPE_NON_COLOR_IMAGE)
	local rmaColor = nodeRMA:GetOutputSocket(cycles.Node.image_texture.OUT_COLOR)

	local metalness = rmaColor.b *inMetalnessFactor
	local roughness = rmaColor.g *inRoughnessFactor

	metalness:Link(outMetalness)
	roughness:Link(outRoughness)
end)
