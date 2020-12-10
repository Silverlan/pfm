--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/cycles/nodes/textures/base.lua")
include("/cycles/nodes/textures/pbr.lua")

util.register_class("cycles.PBRShader",cycles.Shader)

cycles.PBRShader.GLOBAL_EMISSION_STRENGTH = 1.0
function cycles.PBRShader.set_global_emission_strength(strength) cycles.PBRShader.GLOBAL_EMISSION_STRENGTH = strength end
function cycles.PBRShader.get_global_emission_strength() return cycles.PBRShader.GLOBAL_EMISSION_STRENGTH end

function cycles.PBRShader.set_global_albedo_override_color(col) cycles.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR = col end
function cycles.PBRShader.get_global_albedo_override_color() return cycles.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR end

function cycles.PBRShader:__init()
	cycles.Shader.__init(self)
end
function cycles.PBRShader:AddAlbedoNode(desc,mat)
	local data = mat:GetDataBlock()
	local alphaMode = mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()
	local alphaFactor = data:GetFloat("alpha_factor",1.0)
	local colorFactor = data:GetVector("color_factor",Vector(1,1,1))

	local albedoMap = mat:GetTextureInfo("albedo_map")
	local texPath = (albedoMap ~= nil) and self:PrepareTexture(albedoMap:GetName()) or self:PrepareTexture("white") or nil
	if(texPath == nil) then return cycles.Socket(colorFactor),cycles.Socket(alphaFactor) end

	local texCoord = desc:AddNode(cycles.NODE_TEXTURE_COORDINATE)
	local uv = texCoord:GetOutputSocket(cycles.Node.texture_coordinate.OUT_UV)

	-- Albedo
	local nAlbedoMap = desc:AddNode(cycles.NODE_ALBEDO_TEXTURE)
	nAlbedoMap:SetProperty(cycles.Node.albedo_texture.IN_TEXTURE,texPath)
	nAlbedoMap:SetProperty(cycles.Node.albedo_texture.IN_COLOR_FACTOR,colorFactor)
	nAlbedoMap:SetProperty(cycles.Node.albedo_texture.IN_ALPHA_MODE,alphaMode)
	nAlbedoMap:SetProperty(cycles.Node.albedo_texture.IN_ALPHA_CUTOFF,alphaCutoff)
	nAlbedoMap:SetProperty(cycles.Node.albedo_texture.IN_ALPHA_FACTOR,alphaFactor)
	uv:Link(nAlbedoMap,cycles.Node.albedo_texture.IN_UV)

	local col = nAlbedoMap:GetPrimaryOutputSocket()
	local alpha = nAlbedoMap:GetOutputSocket(cycles.Node.albedo_texture.OUT_ALPHA)

	local detailMap = mat:GetTextureInfo("detail_map")
	local blendMode = game.Material.detail_blend_mode_to_enum(data:GetString("detail_blend_mode"))
	if(detailMap ~= nil and blendMode ~= nil) then
		local detailTexPath = self:PrepareTexture(detailMap:GetName())
		if(detailTexPath ~= nil) then
			local detailUvScale = data:GetVector2("detail_uv_scale",Vector2(4.0,4.0))
			local nDetailMap = desc:AddNode(cycles.NODE_ALBEDO_TEXTURE)
			nDetailMap:SetProperty(cycles.Node.albedo_texture.IN_TEXTURE,detailTexPath)
			uv = uv *cycles.Socket(Vector(detailUvScale,0))
			uv:Link(nDetailMap,cycles.Node.albedo_texture.IN_UV)
			local blendFactor = cycles.Socket(data:GetVector("detail_factor",Vector(1.0,1.0,1.0)))
			local detailColorFactor = cycles.Socket(data:GetVector("detail_color_factor",Vector(1,1,1)))

			local detailColor = nDetailMap:GetPrimaryOutputSocket() *detailColorFactor
			local detailAlpha = nDetailMap:GetOutputSocket(cycles.Node.albedo_texture.OUT_ALPHA)
			if(blendMode == game.Material.DETAIL_BLEND_MODE_DECAL_MODULATE) then col = col *cycles.Socket(1.0):Lerp(detailColor *2.0,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_ADDITIVE) then col = col +blendFactor *detailColor
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_TRANSLUCENT_DETAIL) then
				local blend = blendFactor *detailAlpha
				col = col:Lerp(detailColor,blend)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_BLEND_FACTOR_FADE) then col = col:Lerp(detailColor,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_TRANSLUCENT_BASE) then
				local blend = blendFactor *(1.0 -alpha)
				col = col:Lerp(detailColor,blend)
				alpha = detailAlpha
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_TWO_PATTERN_DECAL_MODULATE) then
				local dc = detailColor:Lerp(detailAlpha,alpha)
				col = col *cycles.Socket(1.0):Lerp(2.0 *dc,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_MULTIPLY) then
				col = col:Lerp(col *detailColor,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_BASE_MASK_VIA_DETAIL_ALPHA) then
				alpha = alpha:Lerp(alpha *detailAlpha,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_SSBUMP_ALBEDO) then
				local v = 2.0 /3.0
				col = col *detailColor:DotProduct(cycles.Socket(Vector(v,v,v)))
			end
		end
	end
	return col,alpha
end
function cycles.PBRShader:AddNormalNode(desc,mat) -- Result is in world space
	local normalMap = mat:GetTextureInfo("normal_map")
	local normalTex = (normalMap ~= nil) and self:PrepareTexture(normalMap:GetName()) or nil
	if(normalTex ~= nil) then
		local nNormalMap = desc:AddNode(cycles.NODE_NORMAL_TEXTURE)
		nNormalMap:SetProperty(cycles.Node.normal_texture.IN_TEXTURE,normalTex)
		return nNormalMap:GetPrimaryOutputSocket()
	end
	local geo = desc:AddNode(cycles.NODE_GEOMETRY)
	return geo:GetOutputSocket(cycles.Node.geometry.OUT_NORMAL)
end
function cycles.PBRShader:AddMetalnessRoughnessNode(desc,mat)
	local data = mat:GetDataBlock()
	-- Metalness / Roughness
	local rmaMap = mat:GetTextureInfo("rma_map")
	local rmaTex = (rmaMap ~= nil) and self:PrepareTexture(rmaMap:GetName()) or nil
	local nRMAMap = desc:AddNode(cycles.NODE_RMA_TEXTURE)
	if(rmaTex ~= nil) then nRMAMap:SetProperty(cycles.Node.rma_texture.IN_TEXTURE,rmaTex) end

	-- TODO: Default metalness/roughness if no texture defined!
	local metalnessFactor = data:GetFloat("metalness_factor",1.0)
	local roughnessFactor = data:GetFloat("roughness_factor",1.0)
	cycles.Socket(metalnessFactor):Link(nRMAMap,cycles.Node.rma_texture.IN_METALNESS_FACTOR)
	cycles.Socket(roughnessFactor):Link(nRMAMap,cycles.Node.rma_texture.IN_ROUGHNESS_FACTOR)

	return nRMAMap:GetOutputSocket(cycles.Node.rma_texture.OUT_METALNESS),nRMAMap:GetOutputSocket(cycles.Node.rma_texture.OUT_ROUGHNESS)
end
function cycles.PBRShader:InitializeCombinedPass(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end

	-- TODO: If no albedo map, use white texture instead

	local data = mat:GetDataBlock()
	local colorFactor = data:GetVector("color_factor",Vector(1,1,1))

	-- Albedo
	local albedoColor,alpha = self:AddAlbedoNode(desc,mat)

	local principled = desc:AddNode(cycles.NODE_PRINCIPLED_BSDF)
	local albedoColorOverride = util.get_class_value(cycles.PBRShader,"GLOBAL_ALBEDO_OVERRIDE_COLOR")
	if(albedoColorOverride) then cycles.Socket(albedoColorOverride):Link(principled,cycles.Node.principled_bsdf.IN_BASE_COLOR)
	else albedoColor:Link(principled,cycles.Node.principled_bsdf.IN_BASE_COLOR) end
	alpha:Link(principled,cycles.Node.principled_bsdf.IN_ALPHA)

	local ior = 1.45
	if(data:HasValue("ior")) then
		ior = data:GetFloat("ior",ior)
		principled:SetProperty(cycles.Node.principled_bsdf.IN_IOR,ior)
	end

	-- Subsurface scattering
	local sss = data:FindBlock("subsurface_scattering")
	if(sss ~= nil) then
		local factor = sss:GetFloat("factor",0)
		if(factor > 0) then
			if(sss:HasValue("method") == false or sss:GetString("method") ~= "none") then
				principled:SetProperty(cycles.Node.principled_bsdf.IN_SUBSURFACE,factor)

				local colorFactor = sss:GetVector("color_factor",Vector(1,1,1))
				local sssColor = albedoColor *colorFactor
				sssColor:Link(principled,cycles.Node.principled_bsdf.IN_SUBSURFACE_COLOR)

				if(sss:HasValue("method")) then
					local method = sss:GetString("method")
					local methodToEnum = {
						["cubic"] = cycles.SUBSURFACE_SCATTERING_METHOD_CUBIC,
						["gaussian"] = cycles.SUBSURFACE_SCATTERING_METHOD_GAUSSIAN,
						["principled"] = cycles.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED,
						["burley"] = cycles.SUBSURFACE_SCATTERING_METHOD_BURLEY,
						["random_walk"] = cycles.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK,
						["principled_random_walk"] = cycles.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED_RANDOM_WALK
					}
					method = methodToEnum[method] or cycles.SUBSURFACE_SCATTERING_METHOD_BURLEY
					principled:SetProperty(cycles.Node.principled_bsdf.IN_SUBSURFACE_METHOD,method)
				end

				if(sss:HasValue("scatter_color")) then
					local radius = sss:GetColor("scatter_color"):ToVector()
					principled:SetProperty(cycles.Node.principled_bsdf.IN_SUBSURFACE_RADIUS,radius)
				end
			end
		end
	end

	local specular
	local cyclesBlock = data:FindBlock("cycles")
	if(cyclesBlock ~= nil and cyclesBlock:HasValue("specular")) then
		specular = cyclesBlock:GetFloat("specular",0.0)
	end
	specular = specular or math.calc_dielectric_specular_reflection(ior) -- See https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html#inputs
	principled:SetProperty(cycles.Node.principled_bsdf.IN_SPECULAR,specular)

	-- Emission map
	local globalEmissionStrength = cycles.PBRShader.get_global_emission_strength()
	if(globalEmissionStrength > 0.0) then
		local emissionMap = mat:GetTextureInfo("emission_map")
		local emissionTex = (emissionMap ~= nil) and self:PrepareTexture(emissionMap:GetName()) or nil
		if(emissionTex ~= nil) then
			local emissionFactor = data:GetVector("emission_factor",Vector(1,1,1)) *globalEmissionStrength
			local nEmissionMap = desc:AddNode(cycles.NODE_EMISSION_TEXTURE)
			nEmissionMap:SetProperty(cycles.Node.emission_texture.IN_TEXTURE,emissionTex)
			cycles.Socket(emissionFactor):Link(nEmissionMap,cycles.Node.emission_texture.IN_COLOR_FACTOR)
			nEmissionMap:GetPrimaryOutputSocket():Link(principled,cycles.Node.principled_bsdf.IN_EMISSION)
		end
	end
	-- TODO: UV coordinates?

	-- Normal map
	local normal = self:AddNormalNode(desc,mat)
	normal:Link(principled,cycles.Node.principled_bsdf.IN_NORMAL)

	-- Metalness / Roughness
	local metalness,roughness = self:AddMetalnessRoughnessNode(desc,mat)
	metalness:Link(principled,cycles.Node.principled_bsdf.IN_METALLIC)
	roughness:Link(principled,cycles.Node.principled_bsdf.IN_ROUGHNESS)

	principled:GetPrimaryOutputSocket():Link(outputNode,cycles.Node.output.IN_SURFACE)
end
function cycles.PBRShader:InitializeAlbedoPass(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end

	local color,alpha = self:AddAlbedoNode(desc,mat)
	local transparent = desc:AddNode(cycles.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(cycles.Node.transparent_bsdf.IN_COLOR,Vector(1,1,1))

	-- Output completely metallic surfaces as white (See https://github.com/OpenImageDenoise/oidn)
	local metalness,roughness = self:AddMetalnessRoughnessNode(desc,mat)
	color = color:Mix(desc:CombineRGB(1,1,1),metalness:IsEqualTo(1.0))

	transparent:GetPrimaryOutputSocket():Mix(color,alpha):Link(outputNode,cycles.Node.output.IN_SURFACE)
end
function cycles.PBRShader:InitializeNormalPass(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end
	local normal = self:AddNormalNode(desc,mat)

	local color,alpha = self:AddAlbedoNode(desc,mat)
	local transparent = desc:AddNode(cycles.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(cycles.Node.transparent_bsdf.IN_COLOR,Vector(1,1,1))
	
	-- Transparent normals don't make any sense, so just hide surfaces that have an alpha of < 0.5,
	-- otherwise render them as fully opaque
	normal = normal:Mix(transparent:GetPrimaryOutputSocket(),alpha:LessThan(0.5))
	normal:Link(outputNode,cycles.Node.output.IN_SURFACE)
end
cycles.register_shader("pbr",cycles.PBRShader)
