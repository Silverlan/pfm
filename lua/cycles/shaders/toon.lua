--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("pbr.lua")

util.register_class("cycles.ToonShader",cycles.PBRShader)
function cycles.ToonShader:__init()
	cycles.PBRShader.__init(self)
end
function cycles.ToonShader:InitializeCombinedPass(desc,outputNode)
	local mat = self:GetMaterial()
	local albedoMap = mat:GetTextureInfo("albedo_map")
	if(albedoMap == nil) then return end

	local texPath = self:PrepareTexture(albedoMap:GetName())
	if(texPath == nil) then return end

	local data = mat:GetDataBlock()
	local alphaFactor = data:GetFloat("alpha_factor",1.0)

	local alphaMode = game.Material.ALPHA_MODE_BLEND--mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()


	local albedoColor,alpha = self:AddAlbedoNode(desc,mat)
	--[[local nAlbedoMap = desc:AddNode(cycles.NODE_ALBEDO_MAP)
	nAlbedoMap:SetProperty(cycles.Node.albedo_map.IN_TEXTURE,texPath)--albedoMap:GetName())
	nAlbedoMap:SetProperty(cycles.Node.albedo_map.IN_ALPHA_FACTOR,alphaFactor)
	]]
	--desc:Link(nAlbedoMap:GetOutputSocket(cycles.Node.albedo_map.OUT_COLOR) +Vector(0,0,0),outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))
	--local rgb = desc:AddNode(cycles.NODE_COMBINE_RGB)
	--desc:Link(cycles.Socket(0.0) +1.0,rgb:GetInputSocket(cycles.Node.combine_rgb.IN_R))

	--nAlbedoMap:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))

	--[[local nEqual = desc:AddNode(cycles.NODE_EQUAL)
	nEqual:SetProperty(cycles.Node.equal.IN_VALUE1,0)
	nEqual:SetProperty(cycles.Node.equal.IN_VALUE2,0)]]

	--local test = desc:AddNode(cycles.NODE_GLASS_MATERIAL)
	--test:GetPrimaryOutputSocket():Link(outputNode:GetInputSocket(cycles.Node.output.IN_SURFACE))

	local toon = desc:AddNode(cycles.NODE_TOON_BSDF)
	albedoColor:Link(toon,cycles.Node.toon_bsdf.IN_COLOR)
	toon:GetPrimaryOutputSocket():Link(outputNode,cycles.Node.output.IN_SURFACE)




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
cycles.register_shader("toon",cycles.ToonShader)
