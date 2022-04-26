--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")

util.register_class("gui.ParticleExplorer",gui.AssetExplorer)
function gui.ParticleExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.ParticleExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_PARTICLE_SYSTEM)
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM)
	table.insert(extensions,1,asset.FORMAT_PARTICLE_SYSTEM_BINARY)
	table.insert(extensions,1,asset.FORMAT_PARTICLE_SYSTEM_ASCII)
	self:SetFileExtensions(extensions,asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM))
end
function gui.ParticleExplorer:OnAssetIconCreated(path,assetName,el)
	el:AddCallback("OnParticleSelected",function(el,ptPath)
		local relPath = util.Path(ptPath)
		relPath:MakeRelative(self:GetRootPath())
		self:SetPath(relPath:GetString())
		self:Update()
	end)
end
function gui.ParticleExplorer:PopulateContextMenu(pContext,tSelectedFiles)
	if(#tSelectedFiles == 1) then
		local path = tSelectedFiles[1]:GetRelativeAsset()
		if(asset.is_loaded(path,asset.TYPE_PARTICLE_SYSTEM) == false) then
			pContext:AddItem(locale.get_text("pfm_load"),function()
				-- TODO
				-- game.precache_particle_system(ptFileName)
			end)
		end
		local ptFileName,ptName = tSelectedFiles[1]:GetParticleSystemFileName()
		if(ptFileName ~= nil) then
			pContext:AddItem(locale.get_text("pfm_edit_particle_system"),function(pItem)
				tool.get_filmmaker():OpenParticleEditor(ptFileName,ptName)
			end)
		end
	end
end
gui.register("WIParticleExplorer",gui.ParticleExplorer)
