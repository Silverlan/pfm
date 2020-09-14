--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMMaterialEditor:InitializeEyeControls()
	local mapVbox = gui.create("WIVBox",self.m_controlBox)
	mapVbox:SetAutoFillContents(true)

	-- Noise map
	local numMaps = 6
	local fractionPerMap = 1.0 /numMaps
	self.m_teAlbedoMap = self:AddTextureSlot(mapVbox,locale.get_text("albedo_map"),"albedo_map",false,true)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap)

	
end

--[[	$texture noise_map "models/player/shared/eye-cornea_noise"
	$texture ao_map "models/player/shared/eye-extra"
	"rma_info"
	{
		$bool requires_metalness_update "1"
		$bool requires_roughness_update "1"
	}
	$float roughness_factor "0.000000"
	$texture albedo_map "models/player/shared/eye-iris-blue_albedo"
	$vector subsurface_radius "112 52.8 1.6"
	$texture normal_map "models/player/shared/eye-cornea_normal"
	$texture parallax_map "models/player/shared/eye-cornea_parallax"
	$float metalness_factor "0.000000"
	$float subsurface_multiplier "0.010000"
	$color subsurface_color "242 210 157 255"
	$int subsurface_method "5"
	$bool eyeball_radius "0"
	$bool pupil_dilation "0"]]
