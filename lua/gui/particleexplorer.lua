--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")

util.register_class("gui.ParticleExplorer", gui.AssetExplorer)
function gui.ParticleExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.ParticleExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_PARTICLE_SYSTEM)
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM)
	table.insert(extensions, 1, asset.FORMAT_PARTICLE_SYSTEM_BINARY)
	table.insert(extensions, 1, asset.FORMAT_PARTICLE_SYSTEM_ASCII)
	self:SetFileExtensions(extensions, asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM), {
		asset.FORMAT_PARTICLE_SYSTEM_BINARY,
		asset.FORMAT_PARTICLE_SYSTEM_ASCII,
	})
end
function gui.ParticleExplorer:GetIdentifier()
	return "particle_explorer"
end
function gui.ParticleExplorer:OnAssetIconCreated(path, assetName, el)
	el:AddCallback("OnParticleSelected", function(el, ptPath)
		local relPath = util.Path(ptPath)
		relPath:MakeRelative(self:GetRootPath())
		self:SetPath(relPath:GetString())
		self:Update()
	end)
end
function gui.ParticleExplorer:PopulateContextMenu(pContext, tSelectedFiles)
	if #tSelectedFiles == 1 then
		local path = tSelectedFiles[1]:GetRelativeAsset()
		if asset.is_loaded(path, asset.TYPE_PARTICLE_SYSTEM) == false then
			pContext:AddItem(locale.get_text("pfm_load"), function()
				-- TODO
				-- game.precache_particle_system(ptFileName)
			end)
		end
		local ptFileName, ptName = tSelectedFiles[1]:GetParticleSystemFileName()
		if ptFileName ~= nil then
			pContext:AddItem(locale.get_text("pfm_edit_particle_system"), function(pItem)
				tool.get_filmmaker():OpenParticleEditor(ptFileName, ptName)
			end)
		end
	elseif #tSelectedFiles == 0 then
		local path = util.Path.CreatePath(self:GetPath())
		path = path:GetBack()
		path = path:sub(0, #path - 1)
		local ext = file.get_file_extension(path)
		local isInPtSys = (
			ext == asset.get_binary_udm_extension(asset.TYPE_PARTICLE_SYSTEM)
			or ext == asset.get_ascii_udm_extension(asset.TYPE_PARTICLE_SYSTEM)
		)
		if isInPtSys == false then
			pContext:AddItem(locale.get_text("pfm_add_folder"), function(pItem)
				local icon = self:AddAsset(" ", true, function() end)
				local elBg = icon:GetTextBackgroundElement()

				local te = gui.create("WITextEntry", elBg, 0, 0, elBg:GetWidth(), elBg:GetHeight(), 0, 0, 1, 1)
				te:SetText("")
				te:RequestFocus()
				te:AddCallback("OnFocusKilled", function()
					local folderName = te:GetText()
					util.remove(icon, true)
					util.remove(te, true)
					if #folderName > 0 then
						local fullPath = icon:GetAssetPath() .. folderName
						file.create_path(fullPath)
						self:AddAsset(folderName, true)
					end
				end)
			end)
			pContext:AddItem(locale.get_text("pfm_add_particle_collection"), function(pItem)
				local icon = self:AddAsset(" ", false, function() end)
				local elBg = icon:GetTextBackgroundElement()

				local te = gui.create("WITextEntry", elBg, 0, 0, elBg:GetWidth(), elBg:GetHeight(), 0, 0, 1, 1)
				te:SetText("")
				te:RequestFocus()
				te:AddCallback("OnFocusKilled", function()
					local ptSysName = te:GetText()
					util.remove(icon, true)
					util.remove(te, true)
					ptSysName = file.remove_file_extension(
						ptSysName,
						asset.get_supported_extensions(asset.TYPE_PARTICLE_SYSTEM)
					)
					if #ptSysName > 0 then
						ptSysName = ptSysName .. "." .. asset.get_ascii_udm_extension(asset.TYPE_PARTICLE_SYSTEM)
						local fullPath = icon:GetAssetPath() .. ptSysName
						local relPath = util.Path.CreateFilePath(fullPath)
						relPath:PopFront()
						relPath = relPath:GetString()
						if file.exists(fullPath) == false then
							if file.write(fullPath, '"particleSystemDefinitions" {}') then
								self:SetPath(relPath)
								self:Update()
							end
						end
					end
				end)
			end)
		else
			pContext:AddItem(locale.get_text("pfm_add_particle_system"), function(pItem)
				local icon = self:AddAsset(" ", false, function() end)
				local elBg = icon:GetTextBackgroundElement()

				local te = gui.create("WITextEntry", elBg, 0, 0, elBg:GetWidth(), elBg:GetHeight(), 0, 0, 1, 1)
				te:SetText("")
				te:RequestFocus()
				te:AddCallback("OnFocusKilled", function()
					local ptSysName = te:GetText()
					util.remove(icon, true)
					util.remove(te, true)
					if #ptSysName > 0 then
						local filePath = icon:GetAssetPath()
						filePath = filePath:sub(0, #filePath - 1)
						local udmData, err = udm.load(filePath)
						if udmData == false then
							return
						end
						local ptDefs = udmData:GetAssetData():GetData():Get("particleSystemDefinitions")
						local ptDef = ptDefs:Add(ptSysName)
						ptDef:SetValue("assetType", udm.TYPE_STRING, "PPTSYS")
						ptDef:SetValue("assetVersion", udm.TYPE_UINT32, 1)
						local assetData = ptDef:Get("assetData")
						local udmInitializers = assetData:AddArray("initializers", 4, udm.TYPE_ELEMENT)

						local init0 = udmInitializers:Get(0)
						init0:SetValue("name", udm.TYPE_STRING, "radius_random")
						local kv0 = init0:Get("keyValues")
						kv0:SetValue("radius_min", udm.TYPE_FLOAT, 9.0)
						kv0:SetValue("radius_max", udm.TYPE_FLOAT, 21.0)

						local init1 = udmInitializers:Get(1)
						init1:SetValue("name", udm.TYPE_STRING, "initial_velocity")
						local kv1 = init1:Get("keyValues")
						kv1:SetValue("velocity_min", udm.TYPE_VECTOR3, Vector(0, 40, -40))
						kv1:SetValue("velocity_max", udm.TYPE_VECTOR3, Vector(0, 40, 40))

						local init2 = udmInitializers:Get(2)
						init2:SetValue("name", udm.TYPE_STRING, "lifetime_random")
						local kv2 = init2:Get("keyValues")
						kv2:SetValue("lifetime_min", udm.TYPE_FLOAT, 10)
						kv2:SetValue("lifetime_max", udm.TYPE_FLOAT, 20)

						local init3 = udmInitializers:Get(3)
						init3:SetValue("name", udm.TYPE_STRING, "color_random")
						local kv3 = init3:Get("keyValues")
						kv3:SetValue("color1", udm.TYPE_VECTOR3, Vector(255, 0, 0))
						kv3:SetValue("color2", udm.TYPE_VECTOR3, Vector(0, 255, 0))
						kv3:SetValue("color3", udm.TYPE_VECTOR3, Vector(0, 0, 255))

						assetData:AddArray("operators", 0, udm.TYPE_ELEMENT)
						assetData:AddArray("renderers", 0, udm.TYPE_ELEMENT)
						assetData:AddArray("children", 0, udm.TYPE_ELEMENT)
						local keyValues = assetData:Get("keyValues")
						keyValues:SetValue("maxparticles", udm.TYPE_STRING, "1000")
						keyValues:SetValue("material", udm.TYPE_STRING, "white")
						keyValues:SetValue("emission_rate", udm.TYPE_STRING, "25")
						keyValues:SetValue("radius", udm.TYPE_STRING, "10")
						keyValues:SetValue("bloom_scale", udm.TYPE_STRING, "0.8")
						keyValues:SetValue("sort_particles", udm.TYPE_STRING, "0")

						local f = file.open(filePath, file.OPEN_MODE_WRITE)
						if f == nil then
							self:LogWarn("Unable to open file '" .. filePath .. "' for writing!")
							return
						end
						local res, err = udmData:SaveAscii(f)
						f:Close()
						icon:ClearIcon()
						-- If window is refreshed to early, the particle icon may not get generated properly
						-- in some cases
						time.create_simple_timer(0.5, function()
							if self:IsValid() then
								self:Refresh()
							end
						end)
					end
				end)
			end)
		end
	end
end
gui.register("WIParticleExplorer", gui.ParticleExplorer)
