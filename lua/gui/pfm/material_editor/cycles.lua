--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMMaterialEditor:InitializeCyclesOptions(ctrlVbox,shader)
	if(shader == "pbr") then
		-- See https://blender.stackexchange.com/a/179561 for more information of SSS in Cycles
		local sssPresets = {}
		for _,surfMat in ipairs(phys.get_surface_materials()) do
			local sssFactor = surfMat:GetSubsurfaceFactor()
			if(sssFactor > 0.0) then
				table.insert(sssPresets,{
					name = locale.get_text("phys_material_" .. surfMat:GetName()),
					factor = sssFactor,
					scatterColor = surfMat:GetSubsurfaceScatterColor()
				})
			end
		end

		local options = {
			{"-","-"}
		}
		for i,preset in ipairs(sssPresets) do
			table.insert(options,{tostring(i),preset.name})
		end
		local ctrlSSSFactor
		local ctrlScatterColor
		local ctrlSSSMethod
		ctrlVbox:AddDropDownMenu("preset","preset",options,0,function(el,option)
			local preset = tonumber(el:GetOptionValue(el:GetSelectedOption()))
			if(sssPresets[preset] == nil) then return end
			preset = sssPresets[preset]
			-- self.m_ctrlSSSColor:SetColor(Color(Vector(preset.color[1],preset.color[2],preset.color[3])))
			ctrlScatterColor:SetColor(Color(preset.scatterColor))
			ctrlSSSFactor:SetValue(preset.factor)
			if(ctrlSSSMethod:GetOptionValue(ctrlSSSMethod:GetSelectedOption()) == "none") then
				ctrlSSSMethod:SelectOption("principled_random_walk")
			end
		end)

		-- Subsurface method
		local sssControls
		ctrlSSSMethod = ctrlVbox:AddDropDownMenu("pfm_mated_sss_method","sss_method",{
			{"none",locale.get_text("pfm_mated_sss_method_none")},
			{"principled_random_walk",locale.get_text("pfm_mated_sss_method_principled_random_walk")},
			{"burley",locale.get_text("pfm_mated_sss_method_burley")},
			{"cubic",locale.get_text("pfm_mated_sss_method_cubic")},
			{"gaussian",locale.get_text("pfm_mated_sss_method_gaussian")},
			{"principled",locale.get_text("pfm_mated_sss_method_principled")},
			{"random_walk",locale.get_text("pfm_mated_sss_method_random_walk")}
		},0,function(el,option)
			local val = el:GetOptionValue(option)
			local sssEnabled = (val ~= "none")
			self:SetMaterialParameter("string","method",val,{"subsurface_scattering"})
			sssControls:SetVisible(sssEnabled)
		end)
		self.m_ctrlSSSMethod = ctrlSSSMethod
		self:LinkControlToMaterialParameter("method",ctrlSSSMethod,{"subsurface_scattering"},function(block)
			if(block:HasValue("method") == false) then return end
			ctrlSSSMethod:SelectOption(block:GetString("method"))
		end)

		sssControls = ctrlVbox:AddSubMenu()
		sssControls:SetVisible(false)

		-- Subsurface Scattering
		ctrlSSSFactor = sssControls:AddSliderControl("pfm_mated_sss_factor","sss_factor",0.01,0.0,0.1,function(el,value) self:SetMaterialParameter("float","factor",value,{"subsurface_scattering"}) end,0.001)
		-- ctrlSSSFactor:SetTooltip(locale.get_text("sss_factor_desc"))
		self:LinkControlToMaterialParameter("factor",ctrlSSSFactor,{"subsurface_scattering"})

		-- Subsurface color
		--[[local sssColorEntry = gui.create("WIPFMColorEntry",sssControls)
		sssColorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
			self:ApplySubsurfaceScattering()
		end)
		sssColorEntry:SetColor(Color(242,210,157))
		local sssColorEntryWrapper = sssColorEntry:Wrap("WIEditableEntry")
		sssColorEntryWrapper:SetText(locale.get_text("pfm_mated_sss_color"))
		self.m_ctrlSSSColor = sssColorEntry
		self.m_ctrlSSSColorWrapper = sssColorEntryWrapper
		self.m_ctrlSSSColorWrapper:SetVisible(false)]]

		-- Subsurface radius
		ctrlScatterColor = sssControls:AddColorField("pfm_mated_sss_scatter_color","sss_scatter_color",Color(Vector(0.367,0.137,0.068)),function(oldCol,newCol) self:SetMaterialParameter("color","scatter_color",newCol.r .. " " .. newCol.g .. " " .. newCol.b,{"subsurface_scattering"}) end)
		self:LinkControlToMaterialParameter("color_factor",ctrlScatterColor,nil,function(block)
			if(block:HasValue("color_factor") == false) then return end
			local colorFactor = block:GetVector("color_factor")
			ctrlScatterColor:SetColor(Color(colorFactor))
		end)
	elseif(shader == "glass") then

	elseif(shader == "toon") then
		local propBlock = {"cycles","shader_properties"}
		local shadeColor = ctrlVbox:AddColorField("pfm_mated_toon_shade_color","toon_shade_color",Color(179,81,54),function(oldCol,newCol) self:SetMaterialParameter("color","shade_color",newCol.r .. " " .. newCol.g .. " " .. newCol.b,propBlock) end)
		self:LinkControlToMaterialParameter("shade_color",shadeColor,propBlock,function(block)
			if(block:HasValue("shade_color") == false) then return end
			shadeColor:SetColor(block:GetColor("shade_color"))
		end)

		local specularColor = ctrlVbox:AddColorField("pfm_mated_toon_specular_color","toon_specular_color",Color(255,255,255),function(oldCol,newCol) self:SetMaterialParameter("color","specular_color",newCol.r .. " " .. newCol.g .. " " .. newCol.b,propBlock) end)
		self:LinkControlToMaterialParameter("specular_color",specularColor,propBlock,function(block)
			if(block:HasValue("specular_color") == false) then return end
			specularColor:SetColor(block:GetColor("specular_color"))
		end)

		local diffuseSize = ctrlVbox:AddSliderControl("pfm_mated_toon_diffuse_size","toon_diffuse_size",0.9,0.0,2.0,function(el,value) self:SetMaterialParameter("float","diffuse_size",value,propBlock) end,0.01)
		self:LinkControlToMaterialParameter("diffuse_size",diffuseSize,propBlock)

		local diffuseSmooth = ctrlVbox:AddSliderControl("pfm_mated_toon_diffuse_smooth","toon_diffuse_smooth",0.0,0.0,1.0,function(el,value) self:SetMaterialParameter("float","diffuse_smooth",value,propBlock) end,0.01)
		self:LinkControlToMaterialParameter("diffuse_smooth",diffuseSmooth,propBlock)

		local specularSize = ctrlVbox:AddSliderControl("pfm_mated_toon_specular_size","toon_specular_size",0.2,0.0,2.0,function(el,value) self:SetMaterialParameter("float","specular_size",value,propBlock) end,0.01)
		self:LinkControlToMaterialParameter("specular_size",specularSize,propBlock)

		local specularSmooth = ctrlVbox:AddSliderControl("pfm_mated_toon_specular_smooth","toon_specular_smooth",0.0,0.0,1.0,function(el,value) self:SetMaterialParameter("float","specular_smooth",value,propBlock) end,0.01)
		self:LinkControlToMaterialParameter("specular_smooth",specularSmooth,propBlock)
	end
end
