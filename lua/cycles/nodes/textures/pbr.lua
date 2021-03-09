--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/logic.lua")

unirender.Node.rma_texture = {
	IN_TEXTURE = "texture",
	IN_METALNESS_FACTOR = "metalness_factor",
	IN_ROUGHNESS_FACTOR = "roughness_factor",
	OUT_METALNESS = "metalness",
	OUT_ROUGHNESS = "roughness"
}
unirender.NODE_RMA_TEXTURE = unirender.register_node("rma_texture",function(desc)
	local inTexture = desc:RegisterProperty(unirender.Socket.TYPE_STRING,unirender.Node.rma_texture.IN_TEXTURE,unirender.get_texture_path("error"))
	local inMetalnessFactor = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.rma_texture.IN_METALNESS_FACTOR,1.0)
	local inRoughnessFactor = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.rma_texture.IN_ROUGHNESS_FACTOR,1.0)

	local outMetalness = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.rma_texture.OUT_METALNESS)
	local outRoughness = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.rma_texture.OUT_ROUGHNESS)

	local nodeRMA = desc:AddTextureNode(inTexture,unirender.Node.image_texture.TEXTURE_TYPE_NON_COLOR_IMAGE)
	local rmaColor = nodeRMA:GetOutputSocket(unirender.Node.image_texture.OUT_COLOR)

	local metalness = rmaColor.b *inMetalnessFactor
	local roughness = rmaColor.g *inRoughnessFactor

	metalness:Link(outMetalness)
	roughness:Link(outRoughness)
end)
