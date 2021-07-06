--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("unirender.GenericShader",unirender.Shader)
function unirender.GenericShader:__init()
	unirender.Shader.__init(self)
end
function unirender.GenericShader:AddTextureNode(desc,dbVolumetric,factorName,mapName)
	local mat = self:GetMaterial()
	if(mat == nil) then return end
	local data = mat:GetDataBlock()
	local factor = dbVolumetric:GetVector(factorName,Vector(0,0,0))

	local map = dbVolumetric:GetString(mapName)
	if(map == nil or #map == 0) then return unirender.Socket(factor) end
	local texPath = unirender.get_texture_path(map)
	if(texPath == nil) then return unirender.Socket(factor) end

	local nMap = desc:AddTextureNode(texPath)
	return nMap:GetPrimaryOutputSocket() *unirender.Socket(factor)
end
function unirender.GenericShader:LinkDefaultVolume(desc,outputNode)
	local mat = self:GetMaterial()
	if(mat == nil) then return end
	local data = mat:GetDataBlock()
	local dbVolumetric = mat and mat:GetDataBlock():FindBlock("volumetric")
	if(dbVolumetric ~= nil) then
		local enabled = true
		if(dbVolumetric:HasValue("enabled")) then enabled = dbVolumetric:GetBool("enabled") end
		if(enabled == true) then
			local type = dbVolumetric:GetString("type","homogeneous"):lower()
			local node
			if(type == "clear") then
				node = desc:AddNode(unirender.NODE_VOLUME_CLEAR)
			else
				if(type == "homogeneous") then
					node = desc:AddNode(unirender.NODE_VOLUME_HOMOGENEOUS)

					self:AddTextureNode(desc,dbVolumetric,"scattering_factor","scattering_map"):Link(node,unirender.Node.volume_homogeneous.IN_SCATTERING)
					self:AddTextureNode(desc,dbVolumetric,"asymmetry_factor","asymmetry_map"):Link(node,unirender.Node.volume_homogeneous.IN_ASYMMETRY)
					if(dbVolumetric:HasValue("multiscattering")) then unirender.Socket(dbVolumetric:GetBool("multiscattering",false) and 1 or 0):Link(node,unirender.Node.volume_homogeneous.IN_MULTI_SCATTERING) end
				elseif(type == "heterogeneous") then
					node = desc:AddNode(unirender.NODE_VOLUME_HETEROGENEOUS)

					if(dbVolumetric:HasValue("step_size")) then unirender.Socket(dbVolumetric:GetInt("step_size",0)):Link(node,unirender.Node.volume_heterogeneous.IN_STEP_SIZE) end
					if(dbVolumetric:HasValue("step_max_count")) then unirender.Socket(dbVolumetric:GetInt("step_max_count",0)):Link(node,unirender.Node.volume_heterogeneous.IN_STEP_MAX_COUNT) end
				end
			end
			if(node ~= nil) then
				if(dbVolumetric:HasValue("priority")) then unirender.Socket(dbVolumetric:GetInt("priority",0)):Link(node,unirender.Node.volume_clear.IN_PRIORITY) end
				if(dbVolumetric:HasValue("ior")) then unirender.Socket(dbVolumetric:GetVector("ior",Vector(0.3,0.3,0.3))):Link(node,unirender.Node.volume_clear.IN_IOR) end
				if(dbVolumetric:HasValue("absorption")) then unirender.Socket(dbVolumetric:GetVector("absorption",Vector(0.0,0.0,0.0))):Link(node,unirender.Node.volume_clear.IN_ABSORPTION) end
				self:AddTextureNode(desc,dbVolumetric,"emission_factor","emission_map"):Link(node,unirender.Node.volume_clear.IN_EMISSION)

				node:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_VOLUME)
			end
			return node
		end
	end
end
