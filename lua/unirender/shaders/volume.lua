-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("generic.lua")

util.register_class("unirender.VolumeShader", unirender.GenericShader)
function unirender.VolumeShader:__init()
	unirender.GenericShader.__init(self)
end
function unirender.VolumeShader:InitializeCombinedPass(desc, outputNode)
	local cyclesRenderer = (unirender.PBRShader.get_global_renderer_identifier() == "cycles")
	if cyclesRenderer then
		local mat = self:GetMaterial()
		if mat == nil then
			return
		end
		local data = mat:GetPropertyDataBlock()
		local volData = data:FindBlock("volumetric")
		if volData == nil then
			return
		end
		local vol = desc:AddNode(unirender.NODE_PRINCIPLED_VOLUME)
		vol:SetProperty(unirender.Node.principled_volume.IN_COLOR, volData:GetVector("color", Vector(0.5, 0.5, 0.5)))
		vol:SetProperty(unirender.Node.principled_volume.IN_DENSITY, volData:GetFloat("density", 0.05))
		vol:SetProperty(unirender.Node.principled_volume.IN_ANISOTROPY, volData:GetFloat("anisotropy", 0.0))
		vol:SetProperty(
			unirender.Node.principled_volume.IN_ABSORPTION_COLOR,
			volData:GetVector("absorption_color", Vector(0.0, 0.0, 0.0))
		)
		vol:SetProperty(
			unirender.Node.principled_volume.IN_EMISSION_STRENGTH,
			volData:GetFloat("emission_strength", 0.0)
		)
		vol:SetProperty(
			unirender.Node.principled_volume.IN_EMISSION_COLOR,
			volData:GetVector("emission_color", Vector(0.0, 0.0, 0.0))
		)
		vol:SetProperty(
			unirender.Node.principled_volume.IN_BLACKBODY_INTENSITY,
			volData:GetFloat("blackbody_intensity", 0.0)
		)
		vol:SetProperty(
			unirender.Node.principled_volume.IN_BLACKBODY_TINT,
			volData:GetVector("blackbody_tint", Vector(0.0, 0.0, 0.0))
		)
		vol:SetProperty(unirender.Node.principled_volume.IN_TEMPERATURE, volData:GetFloat("temperature", 1000.0))
		vol:SetProperty(unirender.Node.principled_volume.IN_VOLUME_MIX_WEIGHT, 0.0)
		vol:GetPrimaryOutputSocket():Link(outputNode, unirender.Node.output.IN_VOLUME)
		return
	end

	local node = self:LinkDefaultVolume(desc, outputNode)
	node:SetProperty(unirender.Node.volume_homogeneous.IN_DEFAULT_WORLD_VOLUME, true)
end
unirender.register_shader("volume", unirender.VolumeShader)
