--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("generic.lua")
include("/unirender/nodes/textures/base.lua")
include("/unirender/nodes/textures/pbr.lua")
include("/unirender/nodes/misc/eye_uv.lua")

util.register_class("unirender.PBRShader", unirender.GenericShader)

unirender.PBRShader.GLOBAL_EMISSION_STRENGTH = 1.0
unirender.PBRShader.GLOBAL_RENDERER_IDENTIFIER = ""
unirender.PBRShader.GLOBAL_BAKE_DIFFUSE_LIGHTING = false
function unirender.PBRShader.set_global_emission_strength(strength)
	unirender.PBRShader.GLOBAL_EMISSION_STRENGTH = strength
end
function unirender.PBRShader.get_global_emission_strength()
	return unirender.PBRShader.GLOBAL_EMISSION_STRENGTH
end

function unirender.PBRShader.set_global_renderer_identifier(identifier)
	unirender.PBRShader.GLOBAL_RENDERER_IDENTIFIER = identifier
end
function unirender.PBRShader.get_global_renderer_identifier()
	return unirender.PBRShader.GLOBAL_RENDERER_IDENTIFIER
end

function unirender.PBRShader.set_global_albedo_override_color(col)
	unirender.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR = col
end
function unirender.PBRShader.get_global_albedo_override_color()
	return unirender.PBRShader.GLOBAL_ALBEDO_OVERRIDE_COLOR
end

function unirender.PBRShader.set_global_bake_diffuse_lighting(b)
	unirender.PBRShader.GLOBAL_BAKE_DIFFUSE_LIGHTING = b
end
function unirender.PBRShader.get_global_bake_diffuse_lighting()
	return unirender.PBRShader.GLOBAL_BAKE_DIFFUSE_LIGHTING
end

function unirender.PBRShader:__init()
	unirender.GenericShader.__init(self)
end
function unirender.PBRShader:AddAlbedoNode(desc, mat)
	local data = mat:GetDataBlock()
	local alphaMode = mat:GetAlphaMode()
	local alphaCutoff = mat:GetAlphaCutoff()
	local alphaFactor = data:GetFloat("alpha_factor", 1.0)
	local colorFactor = data:GetVector("color_factor", Vector(1, 1, 1))

	local albedoMap = mat:GetTextureInfo("albedo_map")
	local translucent = (alphaMode ~= game.Material.ALPHA_MODE_OPAQUE)
	local texPath = (albedoMap ~= nil) and unirender.get_texture_path(albedoMap:GetName(), translucent)
		or unirender.get_texture_path("white")
		or nil
	if texPath == nil then
		return unirender.Socket(colorFactor), unirender.Socket(alphaFactor)
	end

	local texCoord = desc:AddNode(unirender.NODE_TEXTURE_COORDINATE)
	local uv = texCoord:GetOutputSocket(unirender.Node.texture_coordinate.OUT_UV)

	local col, alpha
	local sphereUv, eyeColor = self:ApplyEye(desc, mat, uv)
	if eyeColor ~= nil then
		-- Legacy eye shader
		col = eyeColor
		alpha = unirender.Socket(1.0)
	else
		uv = sphereUv -- sphereUv is unchanged uv if this is not an eye shader

		-- Albedo
		local nAlbedoMap = desc:AddNode(unirender.NODE_ALBEDO_TEXTURE)
		nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_TEXTURE, texPath)
		nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_COLOR_FACTOR, colorFactor)
		nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_MODE, alphaMode)
		nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_CUTOFF, alphaCutoff)
		nAlbedoMap:SetProperty(unirender.Node.albedo_texture.IN_ALPHA_FACTOR, alphaFactor)
		uv:Link(nAlbedoMap, unirender.Node.albedo_texture.IN_UV)

		col = nAlbedoMap:GetPrimaryOutputSocket()
		alpha = nAlbedoMap:GetOutputSocket(unirender.Node.albedo_texture.OUT_ALPHA)
	end
	col, alpha = unirender.apply_image_view_swizzling(desc, { col, alpha }, albedoMap)

	local detailMap = mat:GetTextureInfo("detail_map")
	local blendMode = game.Material.detail_blend_mode_to_enum(data:GetString("detail_blend_mode"))
	if detailMap ~= nil and blendMode ~= nil then
		local detailTexPath = unirender.get_texture_path(detailMap:GetName())
		if detailTexPath ~= nil then
			local detailUvScale = data:GetVector2("detail_uv_scale", Vector2(4.0, 4.0))
			local nDetailMap = desc:AddNode(unirender.NODE_ALBEDO_TEXTURE)
			nDetailMap:SetProperty(unirender.Node.albedo_texture.IN_TEXTURE, detailTexPath)
			uv = uv * unirender.Socket(Vector(detailUvScale, 0))
			uv:Link(nDetailMap, unirender.Node.albedo_texture.IN_UV)
			local blendFactor = unirender.Socket(data:GetFloat("detail_factor", 1.0))
			local detailColorFactor = unirender.Socket(data:GetVector("detail_color_factor", Vector(1, 1, 1)))

			local detailColor, detailAlpha = unirender.apply_image_view_swizzling(desc, nDetailMap, detailMap)
			detailColor = detailColor * detailColorFactor
			if blendMode == game.Material.DETAIL_BLEND_MODE_DECAL_MODULATE then
				col = col * unirender.Socket(1.0):Lerp(detailColor * 2.0, blendFactor)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_ADDITIVE then
				col = col + blendFactor * detailColor
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_TRANSLUCENT_DETAIL then
				local blend = blendFactor * detailAlpha
				col = col:Lerp(detailColor, blend)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_BLEND_FACTOR_FADE then
				col = col:Lerp(detailColor, blendFactor)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_TRANSLUCENT_BASE then
				local blend = blendFactor * (1.0 - alpha)
				col = col:Lerp(detailColor, blend)
				alpha = detailAlpha
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_TWO_PATTERN_DECAL_MODULATE then
				local dc = detailColor:Lerp(detailAlpha, alpha)
				col = col * unirender.Socket(1.0):Lerp(2.0 * dc, blendFactor)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_MULTIPLY then
				col = col:Lerp(col * detailColor, blendFactor)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_BASE_MASK_VIA_DETAIL_ALPHA then
				alpha = alpha:Lerp(alpha * detailAlpha, blendFactor)
			elseif blendMode == game.Material.DETAIL_BLEND_MODE_SSBUMP_ALBEDO then
				local v = 2.0 / 3.0
				col = col * detailColor:DotProduct(unirender.Socket(Vector(v, v, v)))
			end
		end
	end
	return col, alpha
end
function unirender.PBRShader:AddNormalNode(desc, mat) -- Result is in world space
	local data = mat:GetDataBlock()
	local normalMap = mat:GetTextureInfo("normal_map")
	local normalStrength = data:GetFloat("normal_strength", 1.0)
	local normalTex = (normalMap ~= nil) and unirender.get_texture_path(normalMap:GetName()) or nil
	if normalTex ~= nil then
		local nNormalMap = desc:AddNode(unirender.NODE_NORMAL_TEXTURE)
		nNormalMap:SetProperty(unirender.Node.normal_texture.IN_FILENAME, normalTex)
		nNormalMap:SetProperty(unirender.Node.normal_texture.IN_STRENGTH, normalStrength)
		return unirender.apply_image_view_swizzling(desc, nNormalMap, normalMap)
	end
end
function unirender.PBRShader:AddMetalnessRoughnessNode(desc, mat)
	local data = mat:GetDataBlock()
	-- Metalness / Roughness
	local rmaMap = mat:GetTextureInfo("rma_map")
	local rmaTex = (rmaMap ~= nil) and unirender.get_texture_path(rmaMap:GetName()) or nil
	local metalnessFactor = data:GetFloat("metalness_factor", 1.0)
	local roughnessFactor = data:GetFloat("roughness_factor", 1.0)
	if rmaTex ~= nil then
		local nRMAMap = desc:AddNode(unirender.NODE_RMA_TEXTURE)
		if rmaTex ~= nil then
			nRMAMap:SetProperty(unirender.Node.rma_texture.IN_TEXTURE, rmaTex)
		end

		unirender.Socket(metalnessFactor):Link(nRMAMap, unirender.Node.rma_texture.IN_METALNESS_FACTOR)
		unirender.Socket(roughnessFactor):Link(nRMAMap, unirender.Node.rma_texture.IN_ROUGHNESS_FACTOR)

		local metalnessChannel, roughnessChannel = unirender.translate_swizzle_channels(
			rmaMap,
			unirender.Node.rma_texture.DEFAULT_METALNESS_CHANNEL,
			unirender.Node.rma_texture.DEFAULT_ROUGHNESS_CHANNEL
		)
		nRMAMap:SetProperty(unirender.Node.rma_texture.IN_METALNESS_CHANNEL, metalnessChannel)
		nRMAMap:SetProperty(unirender.Node.rma_texture.IN_ROUGHNESS_CHANNEL, roughnessChannel)

		return nRMAMap:GetOutputSocket(unirender.Node.rma_texture.OUT_METALNESS),
			nRMAMap:GetOutputSocket(unirender.Node.rma_texture.OUT_ROUGHNESS)
	end
	local mtNode = desc:AddNode(unirender.NODE_MATH)
	mtNode:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_ADD)
	mtNode:SetProperty(unirender.Node.math.IN_VALUE1, metalnessFactor)

	local rgNode = desc:AddNode(unirender.NODE_MATH)
	rgNode:SetProperty(unirender.Node.math.IN_TYPE, unirender.Node.math.TYPE_ADD)
	rgNode:SetProperty(unirender.Node.math.IN_VALUE1, roughnessFactor)

	return mtNode:GetPrimaryOutputSocket(), rgNode:GetPrimaryOutputSocket()
end
function unirender.PBRShader:Initialize()
	local mat = self:GetMaterial()

	--[[local dbHair = mat and mat:GetDataBlock():FindBlock("hair")
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
	end]]

	local dbSubdiv = mat and mat:GetDataBlock():FindBlock("subdivision")
	if dbSubdiv ~= nil then
		local enabled = true
		if dbSubdiv:HasValue("enabled") then
			enabled = dbSubdiv:GetBool("enabled")
		end
		if enabled then
			local subdivSettings = unirender.Shader.SubdivisionSettings()
			subdivSettings.maxLevel = dbSubdiv:GetInt("max_level", 2)
			subdivSettings.maxEdgeScreenSize = dbSubdiv:GetFloat("max_edge_screen_size", 0.0)
			self:SetSubdivisionSettings(subdivSettings)
		end
	end
end
include("/unirender/nodes/test.lua")
function unirender.PBRShader:InitializeCombinedPass(desc, outputNode)
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

	--[[if(true) then
		-- Simple textured node
		local texNode = desc:AddTextureNode(unirender.get_texture_path("models/player/soldier/soldier_d"))
		local bsdf = desc:AddNode(unirender.NODE_GLOSSY_BSDF)
		texNode:GetPrimaryOutputSocket():Link(bsdf,unirender.Node.glossy_bsdf.IN_COLOR)
		bsdf:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_SURFACE)
		return
	end]]

	local mat = self:GetMaterial()
	if mat == nil then
		return
	end

	-- TODO: If no albedo map, use white texture instead

	local data = mat:GetDataBlock()
	local colorFactor = data:GetVector("color_factor", Vector(1, 1, 1))

	-- Albedo
	local albedoColor, alpha = self:AddAlbedoNode(desc, mat)

	local sss = data:FindBlock("subsurface_scattering")
	local sssEnabled = false
	if sss ~= nil then
		local factor = sss:GetFloat("factor", 0)
		if factor > 0 then
			sssEnabled = true
		end
	end

	local useGlossyBsdf = false
	-- TODO: Shaders should be the same regardless of which render engine is used, this is not a good way of handling it!
	-- The reason for it is that SSS is handled via the principled bsdf in Cycles, but via volumes in LuxCoreRender.
	local cyclesRenderer = (unirender.PBRShader.get_global_renderer_identifier() == "cycles")

	local bsdf
	if sssEnabled and cyclesRenderer == false then
		bsdf = desc:AddNode(unirender.NODE_GLOSSY_BSDF)
		useGlossyBsdf = true
	else
		bsdf = desc:AddNode(unirender.NODE_PRINCIPLED_BSDF)
	end

	local sssVolume
	local albedoColorOverride = util.get_class_value(unirender.PBRShader, "GLOBAL_ALBEDO_OVERRIDE_COLOR")
	if sssEnabled == false or cyclesRenderer then
		if albedoColorOverride then
			unirender.Socket(albedoColorOverride):Link(bsdf, unirender.Node.principled_bsdf.IN_BASE_COLOR)
		else
			albedoColor:Link(bsdf, unirender.Node.principled_bsdf.IN_BASE_COLOR)
		end
		alpha:Link(bsdf, unirender.Node.principled_bsdf.IN_ALPHA)
	else
		if albedoColorOverride then
			unirender.Socket(albedoColorOverride):Link(bsdf, unirender.Node.glossy_bsdf.IN_COLOR)
		else
			albedoColor:Link(bsdf, unirender.Node.glossy_bsdf.IN_COLOR)
		end

		sssVolume = desc:AddNode(unirender.NODE_VOLUME_HOMOGENEOUS)

		-- Default properties
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_PRIORITY, 0)
		local ior = 1.5
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_IOR, Vector(ior, ior, ior))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ABSORPTION, Vector(0, 0, 0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_EMISSION, Vector(0, 0, 0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_SCATTERING, Vector(1, 1, 1))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ASYMMETRY, Vector(0, 0, 0))
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_ABSORPTION_DEPTH, 0.01)
		sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_MULTI_SCATTERING, 1)
	end

	local ior = 1.45
	if data:HasValue("ior") then
		ior = data:GetFloat("ior", ior)
		bsdf:SetProperty(unirender.Node.principled_bsdf.IN_IOR, ior)
	end

	-- Subsurface scattering
	local sss = data:FindBlock("subsurface_scattering")
	if sss ~= nil then
		local factor = sss:GetFloat("factor", 0)
		if factor > 0 then
			if sss:HasValue("method") == false or sss:GetString("method") ~= "none" then
				if sssVolume == nil then
					bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE, factor)
				end

				local colorFactor = sss:GetVector("color_factor", Vector(1, 1, 1))
				local sssColor = albedoColor * colorFactor
				if sssVolume ~= nil then
					--sssColor = sssColor *(1.0 -factor)
					unirender.Socket(factor):Link(bsdf, unirender.Node.principled_bsdf.IN_ALPHA)
					sssColor:Link(sssVolume, unirender.Node.volume_homogeneous.IN_ABSORPTION)
				else
					sssColor:Link(bsdf, unirender.Node.principled_bsdf.IN_SUBSURFACE_COLOR)
				end

				if sss:HasValue("method") and sssVolume == nil then
					--[[local method = sss:GetString("method")
					local methodToEnum = {
						["cubic"] = unirender.SUBSURFACE_SCATTERING_METHOD_CUBIC,
						["gaussian"] = unirender.SUBSURFACE_SCATTERING_METHOD_GAUSSIAN,
						["principled"] = unirender.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED,
						["burley"] = unirender.SUBSURFACE_SCATTERING_METHOD_BURLEY,
						["random_walk"] = unirender.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK,
						["principled_random_walk"] = unirender.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED_RANDOM_WALK
					}
					method = methodToEnum[method] or unirender.SUBSURFACE_SCATTERING_METHOD_BURLEY
					bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE_METHOD,method)]]
					bsdf:SetProperty(
						unirender.Node.principled_bsdf.IN_SUBSURFACE_METHOD,
						unirender.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK
					)
				end
				if sss:HasValue("scatter_color") then
					local radius = sss:GetColor("scatter_color"):ToVector()
					if sssVolume ~= nil then
						sssVolume:SetProperty(unirender.Node.volume_homogeneous.IN_SCATTERING, radius)
					else
						bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SUBSURFACE_RADIUS, radius)
					end
				end
			end
		end
	end

	-- Baking diffuse lighting with Cycles can cause weird indirect lighting reflection artifacts
	-- where objects seemingly get projected onto other surfaces. To prevent this from happening, IN_SPECULAR
	-- and IN_METALLIC must not be used when baking.
	local bakeDiffuseLighting = unirender.PBRShader.GLOBAL_BAKE_DIFFUSE_LIGHTING
	if bakeDiffuseLighting == false and useGlossyBsdf == false then
		local specular
		local unirenderBlock = data:FindBlock("unirender")
		if unirenderBlock ~= nil and unirenderBlock:HasValue("specular") then
			specular = unirenderBlock:GetFloat("specular", 0.0)
		end
		specular = specular or math.calc_dielectric_specular_reflection(ior) -- See https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html#inputs
		bsdf:SetProperty(unirender.Node.principled_bsdf.IN_SPECULAR, specular)
	end

	-- Emission map
	local globalEmissionStrength = unirender.PBRShader.get_global_emission_strength()
	if globalEmissionStrength > 0.0 then
		local emissionMap = mat:GetTextureInfo("emission_map")
		local emissionTex = (emissionMap ~= nil) and unirender.get_texture_path(emissionMap:GetName()) or nil
		local emissionFactor
		if data:HasValue("emission_factor") then
			emissionFactor = data:GetVector("emission_factor", Vector(1, 1, 1))
				* globalEmissionStrength
				* data:GetFloat("emission_strength", 1.0)
			if emissionFactor:LengthSqr() == 0.0 then
				emissionFactor = nil
			end
		end
		if emissionFactor ~= nil and emissionTex == nil then
			emissionTex = unirender.get_texture_path("white")
		end
		if emissionTex ~= nil then
			local nEmissionMap = desc:AddNode(unirender.NODE_EMISSION_TEXTURE)
			nEmissionMap:SetProperty(unirender.Node.emission_texture.IN_TEXTURE, emissionTex)
			if emissionFactor ~= nil then
				unirender.Socket(emissionFactor):Link(nEmissionMap, unirender.Node.emission_texture.IN_COLOR_FACTOR)
			end
			local col, alpha = unirender.apply_image_view_swizzling(desc, nEmissionMap, emissionMap)
			col:Link(bsdf, unirender.Node.principled_bsdf.IN_EMISSION)
		end
	end
	-- TODO: UV coordinates?

	-- Normal map
	local normal = self:AddNormalNode(desc, mat)
	if normal ~= nil then
		normal:Link(bsdf, unirender.Node.principled_bsdf.IN_NORMAL)
	end

	-- Metalness / Roughness
	local metalness, roughness = self:AddMetalnessRoughnessNode(desc, mat)
	if bakeDiffuseLighting == false and useGlossyBsdf == false then
		metalness:Link(bsdf, unirender.Node.principled_bsdf.IN_METALLIC)
	end
	roughness:Link(bsdf, unirender.Node.principled_bsdf.IN_ROUGHNESS)

	-- Wetness
	local wetnessFactor = data:GetFloat("wetness_factor", 0.0)
	if wetnessFactor > 0.0 then
		local wetnessMapTex = unirender.get_texture_path("pbr/wetnessmap_default")
		if wetnessMapTex ~= nil then
			local texCoord = desc:AddNode(unirender.NODE_TEXTURE_COORDINATE)
			local noiseTex = desc:AddNode(unirender.NODE_NOISE_TEXTURE)
			noiseTex:SetProperty(unirender.Node.noise_texture.IN_SCALE, 750.0)
			noiseTex:SetProperty(unirender.Node.noise_texture.IN_DETAIL, 13.0)
			noiseTex:SetProperty(unirender.Node.noise_texture.IN_ROUGHNESS, 0.0)
			noiseTex:SetProperty(unirender.Node.noise_texture.IN_DISTORTION, 0.9)

			local wetnessMap = desc:AddTextureNode(wetnessMapTex)

			texCoord
				:GetOutputSocket(unirender.Node.texture_coordinate.OUT_OBJECT)
				:Link(noiseTex, unirender.Node.noise_texture.IN_VECTOR)
			texCoord
				:GetOutputSocket(unirender.Node.texture_coordinate.OUT_OBJECT)
				:Link(wetnessMap, unirender.Node.image_texture.IN_VECTOR)

			local rgbRamp = desc:AddNode(unirender.NODE_RGB_RAMP)
			rgbRamp:SetProperty(unirender.Node.rgb_ramp.IN_RAMP, { Vector(0.0, 0.0, 0.0), Vector(0.5, 0.5, 0.5) })
			rgbRamp:SetProperty(unirender.Node.rgb_ramp.IN_RAMP_ALPHA, { 1.0, 1.0 })

			local fac = noiseTex:GetOutputSocket(unirender.Node.noise_texture.OUT_FAC)
			fac:Link(rgbRamp, unirender.Node.rgb_ramp.IN_FAC)

			local rgbToBw = desc:AddNode(unirender.NODE_RGB_TO_BW)
			rgbRamp:GetOutputSocket(unirender.Node.rgb_ramp.OUT_COLOR):Link(rgbToBw, unirender.Node.rgb_to_bw.IN_COLOR)

			local finalRoughness = rgbToBw:GetOutputSocket(unirender.Node.rgb_to_bw.OUT_VAL)
			finalRoughness = finalRoughness
				* (unirender.Socket(1.0) - wetnessMap:GetPrimaryOutputSocket().r):Max(unirender.Socket(0.5))
			if wetnessFactor < 1.0 then
				finalRoughness = roughness:Lerp(finalRoughness, unirender.Socket(wetnessFactor))
			end
			finalRoughness:Link(bsdf, unirender.Node.principled_bsdf.IN_ROUGHNESS)
		end
	end

	bsdf:GetPrimaryOutputSocket():Link(outputNode, unirender.Node.output.IN_SURFACE)
	if sssVolume ~= nil then
		sssVolume:GetPrimaryOutputSocket():Link(outputNode, unirender.Node.output.IN_VOLUME)
	else
		self:LinkDefaultVolume(desc, outputNode)
	end
end
function unirender.PBRShader:InitializeAlbedoPass(desc, outputNode)
	local mat = self:GetMaterial()
	if mat == nil then
		return
	end

	local color, alpha = self:AddAlbedoNode(desc, mat)
	local transparent = desc:AddNode(unirender.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(unirender.Node.transparent_bsdf.IN_COLOR, Vector(1, 1, 1))

	-- Output completely metallic surfaces as white (See https://github.com/OpenImageDenoise/oidn)
	local metalness, roughness = self:AddMetalnessRoughnessNode(desc, mat)
	color = color:Mix(desc:CombineRGB(1, 1, 1), metalness:IsEqualTo(1.0))

	transparent:GetPrimaryOutputSocket():Mix(color, alpha):Link(outputNode, unirender.Node.output.IN_SURFACE)
end
function unirender.PBRShader:InitializeNormalPass(desc, outputNode)
	local mat = self:GetMaterial()
	if mat == nil then
		return
	end
	local normal = self:AddNormalNode(desc, mat)
	if normal == nil then
		local geo = desc:AddNode(unirender.NODE_GEOMETRY)
		normal = geo:GetOutputSocket(unirender.Node.geometry.OUT_NORMAL)
	end

	local color, alpha = self:AddAlbedoNode(desc, mat)
	local transparent = desc:AddNode(unirender.NODE_TRANSPARENT_BSDF)
	transparent:SetProperty(unirender.Node.transparent_bsdf.IN_COLOR, Vector(1, 1, 1))

	-- Transparent normals don't make any sense, so just hide surfaces that have an alpha of < 0.5,
	-- otherwise render them as fully opaque
	normal = normal:Mix(transparent:GetPrimaryOutputSocket(), alpha:LessThan(0.5))
	normal:Link(outputNode, unirender.Node.output.IN_SURFACE)
end
unirender.register_shader("pbr", unirender.PBRShader)
