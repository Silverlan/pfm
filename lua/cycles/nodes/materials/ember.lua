--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

cycles.Node.ember_material = {
	IN_COLOR = "color",
	IN_BLEND = "blend",
	OUT_SHADER = "shader"
}
cycles.NODE_EMBER_MATERIAL = cycles.register_node("ember_material",function(desc)
	local inColor = desc:RegisterInput(cycles.Socket.TYPE_COLOR,cycles.Node.ember_material.IN_COLOR,Vector(0,0,0))
	local inBlend = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.ember_material.IN_BLEND,0.0)
	local outShader = desc:RegisterOutput(cycles.Socket.TYPE_CLOSURE,cycles.Node.ember_material.OUT_SHADER)
	desc:SetPrimaryOutputSocket(outShader)

	local layerWeight = desc:AddNode(cycles.NODE_LAYER_WEIGHT)
	inBlend:Link(layerWeight,cycles.Node.layer_weight.IN_BLEND)

	local colorRamp = desc:AddNode(cycles.NODE_RGB_RAMP)
	colorRamp:SetProperty(cycles.Node.rgb_ramp.IN_RAMP,{Vector(),Vector(1,1,1)})
	colorRamp:SetProperty(cycles.Node.rgb_ramp.IN_RAMP_ALPHA,{0.488,0.504})
	layerWeight:GetOutputSocket(cycles.Node.layer_weight.OUT_FACING):Link(colorRamp,cycles.Node.rgb_ramp.IN_FAC)

	local principled = desc:AddNode(cycles.NODE_PRINCIPLED_BSDF)
	cycles.Socket(Vector(0.055,0.055,0.055)):Link(principled,cycles.Node.principled_bsdf.IN_BASE_COLOR)

	local emission = desc:AddNode(cycles.NODE_EMISSION)
	inColor:Link(emission,cycles.Node.emission.IN_COLOR)
	cycles.Socket(20):Link(emission,cycles.Node.emission.IN_STRENGTH)

	local mix = principled:GetPrimaryOutputSocket():Mix(emission:GetPrimaryOutputSocket(),colorRamp:GetPrimaryOutputSocket())
	mix:Link(outShader)
end)
