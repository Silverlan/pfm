--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("generic.lua")
include("/unirender/nodes/textures/base.lua")
include("/unirender/nodes/textures/pbr.lua")

util.register_class("unirender.PBRShader",unirender.GenericShader)

unirender.PBRShader.GLOBAL_EMISSION_STRENGTH = 1.0
function unirender.PBRShader.set_global_emission_strength(strength) unirender.PBRShader.GLOBAL_EMISSION_STRENGTH = strength end
function unirender.PBRShader.get_global_emission_strength() return unirender.PBRShader.GLOBAL_EMISSION_STRENGTH end

function unirender.PBRShader.set_global_albedo_override_color(col) unirender.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR = col end
function unirender.PBRShader.get_global_albedo_override_color() return unirender.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR end

function unirender.PBRShader:__init()
	unirender.GenericShader.__init(self)
end
function unirender.PBRShader:AddAlbedoNode(desc,mat)
	local data = mat:GetDataBlock()
	local alphaMode = mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()
	local alphaFactor = data:GetFloat("alpha_factor",1.0)
	local colorFactor = data:GetVector("color_factor",Vector(1,1,1))

	local albedoMap = mat:GetTextureInfo("albedo_map")
	local texPath = (albedoMap ~= nil) and unirender.get_texture_path(albedoMap:GetName()) or unirender.get_texture_path("white") or nil
	if(texPath == nil) then return unirender.Socket(colorFactor),unirender.Socket(alphaFactor) end

	local texCoord = desc:AddNode(unirender.NODE_TEXTURE_COORDINATE)
	local uv = texCoord:GetOutputSocket(unirender.Node.texture_coordinate.OUT_UV)

	-- Albedo
	local nAlbedoMap = desc:AddNode(unirender.NODE_ALBEDO_TEXTURE)
	nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_TEXTURE,texPath)
	nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_COLOR_FACTOR,colorFactor)
	nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_MODE,alphaMode)
	nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_CUTOFF,alphaCutoff)
	nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_FACTOR,alphaFactor)
	uv:Link(nAlbedoMap,unirender.Node.albedo_texture.IN_UV)

	local col = nAlbedoMap:GetPrimaryOutputSocket()
	local alpha = nAlbedoMap:GetOutputSocket(unirender.Node.albedo_texture.OUT_ALPHA)

	local detailMap = mat:GetTextureInfo("detail_map")
	local blendMode = game.Material.detail_blend_mode_to_enum(data:GetString("detail_blend_mode"))
	if(detailMap ~= nil and blendMode ~= nil) then
		local detailTexPath = unirender.get_texture_path(detailMap:GetName())
		if(detailTexPath ~= nil) then
			local detailUvScale = data:GetVector2("detail_uv_scale",Vector2(4.0,4.0))
			local nDetailMap = desc:AddNode(unirender.NODE_ALBEDO_TEXTURE)
			nDetailMap:SetProperty(unirender.Node.albedo_texture.IN_TEXTURE,detailTexPath)
			uv = uv *unirender.Socket(Vector(detailUvScale,0))
			uv:Link(nDetailMap,unirender.Node.albedo_texture.IN_UV)
			local blendFactor = unirender.Socket(data:GetFloat("detail_factor",1.0))
			local detailColorFactor = unirender.Socket(data:GetVector("detail_color_factor",Vector(1,1,1)))

			local detailColor = nDetailMap:GetPrimaryOutputSocket() *detailColorFactor
			local detailAlpha = nDetailMap:GetOutputSocket(unirender.Node.albedo_texture.OUT_ALPHA)
			if(blendMode == game.Material.DETAIL_BLEND_MODE_DECAL_MODULATE) then col = col *unirender.Socket(1.0):Lerp(detailColor *2.0,blendFactor)
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
				col = col *unirender.Socket(1.0):Lerp(2.0 *dc,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_MULTIPLY) then
				col = col:Lerp(col *detailColor,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_BASE_MASK_VIA_DETAIL_ALPHA) then
				alpha = alpha:Lerp(alpha *detailAlpha,blendFactor)
			elseif(blendMode == game.Material.DETAIL_BLEND_MODE_SSBUMP_ALBEDO) then
				local v = 2.0 /3.0
				col = col *detailColor:DotProduct(unirender.Socket(Vector(v,v,v)))
			end
		end
	end
	return col,alpha
end
function unirender.PBRShader:AddNormalNode(desc,mat) -- Result is in world space
	local data = mat:GetDataBlock()
	local normalMap = mat:GetTextureInfo("normal_map")
	local normalStrength = data:GetFloat("normal_strength",1.0)
	local normalTex = (normalMap ~= nil) and unirender.get_texture_path(normalMap:GetName()) or nil
	if(normalTex ~= nil) then
		local nNormalMap = desc:AddNode(unirender.NODE_NORMAL_TEXTURE)
		nNormalMap:SetProperty(unirender.Node.normal_texture.IN_FILENAME,normalTex)
		nNormalMap:SetProperty(unirender.Node.normal_texture.IN_STRENGTH,normalStrength)
		return nNormalMap:GetPrimaryOutputSocket()
	end
end
function unirender.PBRShader:AddMetalnessRoughnessNode(desc,mat)
	local data = mat:GetDataBlock()
	-- Metalness / Roughness
	local rmaMap = mat:GetTextureInfo("rma_map")
	local rmaTex = (rmaMap ~= nil) and unirender.get_texture_path(rmaMap:GetName()) or nil
	local nRMAMap = desc:AddNode(unirender.NODE_RMA_TEXTURE)
	if(rmaTex ~= nil) then nRMAMap:SetProperty(unirender.Node.rma_texture.IN_TEXTURE,rmaTex) end

	-- TODO: Default metalness/roughness if no texture defined!
	local metalnessFactor = data:GetFloat("metalness_factor",1.0)
	local roughnessFactor = data:GetFloat("roughness_factor",1.0)
	unirender.Socket(metalnessFactor):Link(nRMAMap,unirender.Node.rma_texture.IN_METALNESS_FACTOR)
	unirender.Socket(roughnessFactor):Link(nRMAMap,unirender.Node.rma_texture.IN_ROUGHNESS_FACTOR)

	return nRMAMap:GetOutputSocket(unirender.Node.rma_texture.OUT_METALNESS),nRMAMap:GetOutputSocket(unirender.Node.rma_texture.OUT_ROUGHNESS)
end
function unirender.PBRShader:Initialize()
	local mat = self:GetMaterial()

	local dbHair = mat and mat:GetDataBlock():FindBlock("hair")
	if(dbHair ~= nil) then
		local enabled = true
		if(dbHair:HasValue("enabled")) then enabled = dbHair:GetBool("enabled") end
		if(enabled) then
			local hairConfig = unirender.Shader.HairConfig()
			hairConfig.hairPerSquareMeter = dbHair:GetFloat("hair_per_square_meter",1000000)
			hairConfig.numSegments = dbHair:GetFloat("segment_count",2)
			hairConfig.defaultThickness = util.units_to_metres(dbHair:GetFloat("thickness",0.005))
			hairConfig.defaultLength = util.units_to_metres(dbHair:GetFloat("length",0.6))
			hairConfig.defaultHairStrength = dbHair:GetFloat("strength",0.4)
			hairConfig.randomHairLengthFactor = dbHair:GetFloat("random_hair_length_factor",0.3)
			hairConfig.curvature = dbHair:GetFloat("curvature",0.6)
			self:SetHairConfig(hairConfig)
		end
	end

	local dbSubdiv = mat and mat:GetDataBlock():FindBlock("subdivision")
	if(dbSubdiv ~= nil) then
		local enabled = true
		if(dbSubdiv:HasValue("enabled")) then enabled = dbSubdiv:GetBool("enabled") end
		if(enabled) then
			local subdivSettings = unirender.Shader.SubdivisionSettings()
			subdivSettings.maxLevel = dbSubdiv:GetInt("max_level",2)
			subdivSettings.maxEdgeScreenSize = dbSubdiv:GetFloat("max_edge_screen_size",0.0)
			self:SetSubdivisionSettings(subdivSettings)
		end
	end
end
include("/unirender/nodes/test.lua")
function unirender.PBRShader:InitializeCombinedPass(desc,outputNode)
	--[[if(true) then
		return unirender.Node.test.test_output(desc,outputNode,0)
	end]]
	--[[local mat = self:GetMaterial()
	if(mat == nil) then return end
	local principled = desc:AddNode(unirender.NODE_PRINCIPLED_BSDF)

	local nAlbedoMap = desc:AddNode(unirender.NODE_ALBEDO_TEXTURE)
	--nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_TEXTURE,unirender.get_texture_path("error"))

	nAlbedoMap:GetPrimaryOutputSocket():Link(principled,unirender.Node.principled_bsdf.IN_BASE_COLOR)
	principled:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_SURFACE)]]
	local mat = self:GetMaterial()
	if(mat == nil) then return end

	-- TODO: If no albedo map, use white texture instead

	local data = mat:GetDataBlock()
	local colorFactor = data:GetVector("color_factor",Vector(1,1,1))

	-- Albedo
	local albedoColor,alpha = self:AddAlbedoNode(desc,mat)

	local sss = data:FindBlock("subsurface_scattering")
	local sssEnabled = false
	if(sss ~= nil) then
		local factor = sss:GetFloat("factor",0)
		if(factor > 0) then
			sssEnabled = true
		end
	end

	local useGlossyBsdf = false
	local bsdf
	if(sssEnabled) then
		bsdf = desc:AddNode(unirender.NODE_GLOSSY_BSDF)
		useGlossyBsdf = true
	else bsdf = desc:AddNode(unirender.NODE_PRINCIPLED_BSDF) end

	local sssVolume
	local albedoColorOverride = util.get_class_value(unirender.PBRShader,"GLOBAL_ALBEDO_OVERRIDE_COLOR")
	if(sssEnabled == false) then
		if(albedoColorOverride) then unirender.Socket(albedoColorOverride):Link(bsdf,unirender.Node.principled_bsdf.IN_BASE_COLOR)
		else albedoColor:Link(bsdf,unirender.Node.principled_bsdf.IN_BASE_COLOR) end
		alpha:Link(bsdf,unirender.Node.principled_bsdf.IN_ALPHA)
	else
		if(albedoColorOverride) then unirender.Socket(albedoColorOverride):Link(bsdf,unirender.Node.glossy_bsdf.IN_COLOR)
		else albedoColor:Link(bsdf,unirender.Node.glossy_bsdf.IN_COLOR) end

		sssVolume = desc:AddNode(unirender.NODE_VOLUME_HOMOGENEOUS)

		-- Default properties
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_PRIORITY,0)
		local ior = 1.5
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_IOR,Vector(ior,ior,ior))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ABSORPTION,Vector(0,0,0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_EMISSION,Vector(0,0,0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_SCATTERING,Vector(1,1,1))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ASYMMETRY,Vector(0,0,0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ABSORPTION_DEPTH,0.01)
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_MULTI_SCATTERING,1)
	end

	local ior = 1.45
	if(data:HasValue("ior")) then
		ior = data:GetFloat("ior",ior)
		bsdf:SetProperty(unirender.Node.principled_bsdf.IN_IOR,ior)
	end

	-- Subsurface scattering
	local sss = data:FindBlock("subsurface_scattering")
	if(sss ~= nil) then
		local factor = sss:GetFloat("factor",0)
		if(factor > 0) then
			if(sss:HasValue("method") == false or sss:GetString("method") ~= "none") then
				if(sssVolume == nil) then bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE,factor) end

				local colorFactor = sss:GetVector("color_factor",Vector(1,1,1))
				local sssColor = albedoColor *colorFactor
				if(sssVolume ~= nil) then
					--sssColor = sssColor *(1.0 -factor)
					unirender.Socket(factor):Link(bsdf,unirender.Node.principled_bsdf.IN_ALPHA)
					sssColor:Link(sssVolume,unirender.Node.volume_homogeneous.IN_ABSORPTION)
				else sssColor:Link(bsdf,unirender.Node.principled_bsdf.IN_SUBSURFACE_COLOR) end

				if(sss:HasValue("method") and sssVolume == nil) then
					local method = sss:GetString("method")
					local methodToEnum = {
						["cubic"] = unirender.SUBSURFACE_SCATTERING_METHOD_CUBIC,
						["gaussian"] = unirender.SUBSURFACE_SCATTERING_METHOD_GAUSSIAN,
						["principled"] = unirender.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED,
						["burley"] = unirender.SUBSURFACE_SCATTERING_METHOD_BURLEY,
						["random_walk"] = unirender.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK,
						["principled_random_walk"] = unirender.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED_RANDOM_WALK
					}
					method = methodToEnum[method] or unirender.SUBSURFACE_SCATTERING_METHOD_BURLEY
					bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE_METHOD,method)
				end

				if(sss:HasValue("scatter_color")) then
					local radius = sss:GetColor("scatter_color"):ToVector()
					if(sssVolume ~= nil) then sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_SCATTERING,radius)
					else bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE_RADIUS,radius) end
				end
			end
		end
	end

	if(useGlossyBsdf == false) then
		local specular
		local unirenderBlock = data:FindBlock("unirender")
		if(unirenderBlock ~= nil and unirenderBlock:HasValue("specular")) then
			specular = unirenderBlock:GetFloat("specular",0.0)
		end
		specular = specular or math.calc_dielectric_specular_reflection(ior) -- See https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html#inputs
		bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SPECULAR,specular)
	end

	-- Emission map
	local globalEmissionStrength = unirender.PBRShader.get_global_emission_strength()
	if(globalEmissionStrength > 0.0) then
		local emissionMap = mat:GetTextureInfo("emission_map")
		local emissionTex = (emissionMap ~= nil) and unirender.get_texture_path(emissionMap:GetName()) or nil
		if(emissionTex ~= nil) then
			local emissionFactor = data:GetVector("emission_factor",Vector(1,1,1)) *globalEmissionStrength
			local nEmissionMap = desc:AddNode(unirender.NODE_EMISSION_TEXTURE)
			nEmissionMap:SetProperty(unirender.Node.emission_texture.IN_TEXTURE,emissionTex)
			unirender.Socket(emissionFactor):Link(nEmissionMap,unirender.Node.emission_texture.IN_COLOR_FACTOR)
			nEmissionMap:GetPrimaryOutputSocket():Link(bsdf,unirender.Node.principled_bsdf.IN_EMISSION)
		end
	end
	-- TODO: UV coordinates?

	-- Normal map
	local normal = self:AddNormalNode(desc,mat)
	if(normal ~= nil) then normal:Link(bsdf,unirender.Node.principled_bsdf.IN_NORMAL) end

	-- Metalness / Roughness
	local metalness,roughness = self:AddMetalnessRoughnessNode(desc,mat)
	if(useGlossyBsdf == false) then metalness:Link(bsdf,unirender.Node.principled_bsdf.IN_METALLIC) end
	roughness:Link(bsdf,unirender.Node.principled_bsdf.IN_ROUGHNESS)

	bsdf:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_SURFACE)
	if(sssVolume ~= nil) then sssVolume:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_VOLUME)
	else self:LinkDefaultVolume(desc,outputNode) end
end
function unirender.PBRShader:InitializeAlbedoPass(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end

	local color,alpha = self:AddAlbedoNode(desc,mat)
	local transparent = desc:AddNode(unirender.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(unirender.Node.transparent_bsdf.IN_COLOR,Vector(1,1,1))

	-- Output completely metallic surfaces as white (See https://github.com/OpenImageDenoise/oidn)
	local metalness,roughness = self:AddMetalnessRoughnessNode(desc,mat)
	color = color:Mix(desc:CombineRGB(1,1,1),metalness:IsEqualTo(1.0))

	transparent:GetPrimaryOutputSocket():Mix(color,alpha):Link(outputNode,unirender.Node.output.IN_SURFACE)
end
function unirender.PBRShader:InitializeNormalPass(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end
	local normal = self:AddNormalNode(desc,mat)
	if(normal == nil) then
		local geo = desc:AddNode(unirender.NODE_GEOMETRY)
		normal = geo:GetOutputSocket(unirender.Node.geometry.OUT_NORMAL)
	end

	local color,alpha = self:AddAlbedoNode(desc,mat)
	local transparent = desc:AddNode(unirender.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(unirender.Node.transparent_bsdf.IN_COLOR,Vector(1,1,1))
	
	-- Transparent normals don't make any sense, so just hide surfaces that have an alpha of < 0.5,
	-- otherwise render them as fully opaque
	normal = normal:Mix(transparent:GetPrimaryOutputSocket(),alpha:LessThan(0.5))
	normal:Link(outputNode,unirender.Node.output.IN_SURFACE)
end
unirender.register_shader("pbr",unirender.PBRShader)
