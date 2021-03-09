--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/materials/glass.lua")

util.register_class("unirender.WaterShader",unirender.Shader)
function unirender.WaterShader:__init()
	unirender.Shader.__init(self)
end
function unirender.WaterShader:InitializeCombinedPass(desc,outputNode)
	--[[local glass = desc:AddNode(unirender.NODE_GLASS_MATERIAL)

	local mat = self:GetMaterial()
	if(mat == nil) then return end

	
	
	local data = mat:GetDataBlock()
	local ior = 1.3244 -- data:GetFloat("ior")
	if(data:HasValue("ior")) then glass:SetProperty(unirender.Node.glass_material.IN_IOR,ior) end

	glass:SetProperty(unirender.Node.glass_material.IN_COLOR,Vector(0,225 /255.0,229 /255.0))
	--finalAlpha = finalAlpha *desc:AddNode(unirender.NODE_LIGHT_PATH):GetOutputSocket(unirender.Node.light_path.OUT_TRANSPARENT_DEPTH):LessThan(2)
	glass:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(unirender.Node.output.IN_SURFACE))]]

	local glass = desc:AddNode(unirender.NODE_GLASS_BSDF)
	local ior = 1.3244 -- data:GetFloat("ior")
	glass:SetProperty(unirender.Node.glass_bsdf.IN_IOR,ior)
	glass:SetProperty(unirender.Node.glass_bsdf.IN_COLOR,Vector(0,225 /255.0,229 /255.0))
	glass:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(unirender.Node.output.IN_SURFACE))

--[[
	local inColor = desc:RegisterInput(unirender.Socket.TYPE_COLOR,unirender.Node.glass_material.IN_COLOR,Vector(0.8,0.8,0.8))
	local inRoughness = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.glass_material.IN_ROUGHNESS,0.0)
	local inIOR = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.glass_material.IN_IOR,0.3)
	local outShader = desc:RegisterOutput(unirender.Socket.TYPE_CLOSURE,unirender.Node.glass_material.OUT_SHADER)
]]


	--[[local mat = self:GetMaterial()
	local albedoMap = mat:GetTextureInfo("albedo_map")
	if(albedoMap == nil) then return end



	local texPath = unirender.get_texture_path(albedoMap:GetName())
	if(texPath == nil) then return end

	local alphaMode = mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()
	local nAlbedoMap = desc:AddNode(unirender.NODE_ALBEDO_MAP)
	nAlbedoMap:SetProperty(unirender.Node.albedo_map.IN_TEXTURE,texPath)]]--albedoMap:GetName())
	--desc:Link(nAlbedoMap:GetOutputSocket(unirender.Node.albedo_map.OUT_COLOR) +Vector(0,0,0),outputNode:GetInputSocket(unirender.Node.output.IN_SURFACE))
	--local rgb = desc:AddNode(unirender.NODE_COMBINE_RGB)
	--desc:Link(unirender.Socket(0.0) +1.0,rgb:GetInputSocket(unirender.Node.combine_rgb.IN_R))

	--nAlbedoMap:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(unirender.Node.output.IN_SURFACE))

	--[[local nEqual = desc:AddNode(unirender.NODE_EQUAL)
	nEqual:SetProperty(unirender.Node.equal.IN_VALUE1,0)
	nEqual:SetProperty(unirender.Node.equal.IN_VALUE2,0)]]

	--local test = desc:AddNode(unirender.NODE_GLASS_MATERIAL)
	--test:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(unirender.Node.output.IN_SURFACE))




	--[[print("Albedo: ",albedoMap)


	local c = desc:AddConstantNode(1)

	local n = desc:AddNode("not")
	--n:SetProperty("value",1)
	--desc:Link(c,"value",n,"value")

	local rgb = desc:AddNode(unirender.NODE_COMBINE_RGB)
	desc:Link(n,"value",rgb,"r")
	desc:Link(n,"value",rgb,"g")

	desc:Link(rgb,"image",outputNode,unirender.Node.output.IN_SURFACE)]]

	--local t = desc:AddNode("test")

end
unirender.register_shader("water",unirender.WaterShader)
