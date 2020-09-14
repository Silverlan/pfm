--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/materials/glass.lua")

util.register_class("cycles.GlassShader",cycles.Shader)
function cycles.GlassShader:__init()
	cycles.Shader.__init(self)
end
function cycles.GlassShader:InitializeCombinedPass(desc,outputNode)
	local glass = desc:AddNode(cycles.NODE_GLASS_MATERIAL)

	local mat = self:GetMaterial()
	if(mat == nil) then return end

	
	
	local data = mat:GetDataBlock()
	if(data:HasValue("ior")) then glass:SetProperty(cycles.Node.glass_material.IN_IOR,data:GetFloat("ior")) end

	glass:SetProperty(cycles.Node.glass_material.IN_COLOR,Vector(1,1,1))
	--finalAlpha = finalAlpha *desc:AddNode(cycles.NODE_LIGHT_PATH):GetOutputSocket(cycles.Node.light_path.OUT_TRANSPARENT_DEPTH):LessThan(2)
	glass:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))

--[[
	local inColor = desc:RegisterInput(cycles.Socket.TYPE_COLOR,cycles.Node.glass_material.IN_COLOR,Vector(0.8,0.8,0.8))
	local inRoughness = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.glass_material.IN_ROUGHNESS,0.0)
	local inIOR = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.glass_material.IN_IOR,0.3)
	local outShader = desc:RegisterOutput(cycles.Socket.TYPE_CLOSURE,cycles.Node.glass_material.OUT_SHADER)
]]


	--[[local mat = self:GetMaterial()
	local albedoMap = mat:GetTextureInfo("albedo_map")
	if(albedoMap == nil) then return end



	local texPath = self:PrepareTexture(albedoMap:GetName())
	if(texPath == nil) then return end

	local alphaMode = mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()
	local nAlbedoMap = desc:AddNode(cycles.NODE_ALBEDO_MAP)
	nAlbedoMap:SetProperty(cycles.Node.albedo_map.IN_TEXTURE,texPath)]]--albedoMap:GetName())
	--desc:Link(nAlbedoMap:GetOutputSocket(cycles.Node.albedo_map.OUT_COLOR) +Vector(0,0,0),outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))
	--local rgb = desc:AddNode(cycles.NODE_COMBINE_RGB)
	--desc:Link(cycles.Socket(0.0) +1.0,rgb:GetInputSocket(cycles.Node.combine_rgb.IN_R))

	--nAlbedoMap:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))

	--[[local nEqual = desc:AddNode(cycles.NODE_EQUAL)
	nEqual:SetProperty(cycles.Node.equal.IN_VALUE1,0)
	nEqual:SetProperty(cycles.Node.equal.IN_VALUE2,0)]]

	--local test = desc:AddNode(cycles.NODE_GLASS_MATERIAL)
	--test:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))




	--[[print("Albedo: ",albedoMap)


	local c = desc:AddConstantNode(1)

	local n = desc:AddNode("not")
	--n:SetProperty("value",1)
	--desc:Link(c,"value",n,"value")

	local rgb = desc:AddNode(cycles.NODE_COMBINE_RGB)
	desc:Link(n,"value",rgb,"r")
	desc:Link(n,"value",rgb,"g")

	desc:Link(rgb,"image",outputNode,cycles.Node.output.IN_SURFACE)]]

	--local t = desc:AddNode("test")

end
cycles.register_shader("glass",cycles.GlassShader)
