--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

unirender.Node.ember_material = {
	IN_COLOR = "color",
	IN_BLEND = "blend",
	OUT_SHADER = "shader"
}
unirender.NODE_EMBER_MATERIAL = unirender.register_node("ember_material",function(desc)
	local inColor = desc:RegisterInput(unirender.Socket.TYPE_COLOR,unirender.Node.ember_material.IN_COLOR,Vector(0,0,0))
	local inBlend = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.ember_material.IN_BLEND,0.0)
	local outShader = desc:RegisterOutput(unirender.Socket.TYPE_CLOSURE,unirender.Node.ember_material.OUT_SHADER)
	desc:SetPrimaryOutputSocket(outShader)

	local layerWeight = desc:AddNode(unirender.NODE_LAYER_WEIGHT)
	inBlend:Link(layerWeight,unirender.Node.layer_weight.IN_BLEND)

	local colorRamp = desc:AddNode(unirender.NODE_RGB_RAMP)
	colorRamp:SetProperty(unirender.Node.rgb_ramp.IN_RAMP,{Vector(),Vector(1,1,1)})
	colorRamp:SetProperty(unirender.Node.rgb_ramp.IN_RAMP_ALPHA,{0.488,0.504})
	layerWeight:GetOutputSocket(unirender.Node.layer_weight.OUT_FACING):Link(colorRamp,unirender.Node.rgb_ramp.IN_FAC)

	local principled = desc:AddNode(unirender.NODE_PRINCIPLED_BSDF)
	unirender.Socket(Vector(0.055,0.055,0.055)):Link(principled,unirender.Node.principled_bsdf.IN_BASE_COLOR)

	local emission = desc:AddNode(unirender.NODE_EMISSION)
	inColor:Link(emission,unirender.Node.emission.IN_COLOR)
	unirender.Socket(20):Link(emission,unirender.Node.emission.IN_STRENGTH)

	local mix = principled:GetPrimaryOutputSocket():Mix(emission:GetPrimaryOutputSocket(),colorRamp:GetPrimaryOutputSocket())
	mix:Link(outShader)
end)
