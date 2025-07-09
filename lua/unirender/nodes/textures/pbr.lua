-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/unirender/nodes/logic.lua")

unirender.Node.rma_texture = {
	IN_TEXTURE = "texture",
	IN_METALNESS_FACTOR = "metalness_factor",
	IN_ROUGHNESS_FACTOR = "roughness_factor",
	IN_METALNESS_CHANNEL = "metalness_channel",
	IN_ROUGHNESS_CHANNEL = "roughness_channel",
	OUT_METALNESS = "metalness",
	OUT_ROUGHNESS = "roughness",

	DEFAULT_METALNESS_CHANNEL = util.ImageBuffer.CHANNEL_BLUE,
	DEFAULT_ROUGHNESS_CHANNEL = util.ImageBuffer.CHANNEL_GREEN,
}
local channelToName = {
	[util.ImageBuffer.CHANNEL_RED] = "r",
	[util.ImageBuffer.CHANNEL_GREEN] = "g",
	[util.ImageBuffer.CHANNEL_BLUE] = "b",
	[util.ImageBuffer.CHANNEL_ALPHA] = "a",
}
unirender.NODE_RMA_TEXTURE = unirender.register_node("rma_texture", function(desc)
	local inTexture = desc:RegisterProperty(
		unirender.Socket.TYPE_STRING,
		unirender.Node.rma_texture.IN_TEXTURE,
		unirender.get_texture_path("error")
	)
	local inMetalnessFactor =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.rma_texture.IN_METALNESS_FACTOR, 1.0)
	local inRoughnessFactor =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.rma_texture.IN_ROUGHNESS_FACTOR, 1.0)

	local inMetalnessChannel = desc:RegisterProperty(
		unirender.Socket.TYPE_INT,
		unirender.Node.rma_texture.IN_METALNESS_CHANNEL,
		unirender.Node.rma_texture.DEFAULT_METALNESS_CHANNEL
	)
	local inRoughnessChannel = desc:RegisterProperty(
		unirender.Socket.TYPE_INT,
		unirender.Node.rma_texture.IN_ROUGHNESS_CHANNEL,
		unirender.Node.rma_texture.DEFAULT_ROUGHNESS_CHANNEL
	)

	local outMetalness = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT, unirender.Node.rma_texture.OUT_METALNESS)
	local outRoughness = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT, unirender.Node.rma_texture.OUT_ROUGHNESS)

	local nodeRMA = desc:AddTextureNode(inTexture, unirender.Node.image_texture.TEXTURE_TYPE_NON_COLOR_IMAGE)
	local rmaColor = nodeRMA:GetOutputSocket(unirender.Node.image_texture.OUT_COLOR)

	local metalness = rmaColor[channelToName[desc:GetProperty(unirender.Node.rma_texture.IN_METALNESS_CHANNEL)]]
		* inMetalnessFactor
	local roughness = rmaColor[channelToName[desc:GetProperty(unirender.Node.rma_texture.IN_ROUGHNESS_CHANNEL)]]
		* inRoughnessFactor

	metalness:Link(outMetalness)
	roughness:Link(outRoughness)
end)
