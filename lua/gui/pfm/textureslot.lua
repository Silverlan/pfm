--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTextureSlot", gui.Base)
function gui.PFMTextureSlot:__init()
	gui.Base.__init(self)
end
function gui.PFMTextureSlot:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 128)

	self.m_texRect = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)

	self.m_outline = gui.create("WIOutlinedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_outline:SetColor(Color.Black)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnFilesDropped", function(texSlot, tFiles)
		if #tFiles == 0 then
			return util.EVENT_REPLY_UNHANDLED
		end
		local f = game.open_dropped_file(tFiles[1], true)
		if f == nil then
			return util.EVENT_REPLY_UNHANDLED
		end
		if self.m_matPath == nil then
			local tex = asset.load(f, asset.TYPE_TEXTURE)
			tex = (tex ~= nil) and tex:GetVkTexture() or nil
			if tex ~= nil then
				self.m_texRect:SetTexture(tex)
			else
				self.m_texRect:ClearTexture()
			end
			return util.EVENT_REPLY_HANDLED
		end
		local texPath = util.Path(self.m_matPath) + tFiles[1]
		texPath:RemoveFileExtension()
		local texImportInfo = asset.TextureImportInfo()

		-- TODO: Doesn't seem to work properly?
		-- texImportInfo.normalMap = self.m_normalMap

		-- Importing the texture could potentially trigger a material reload through the asset watchers, which we want to avoid,
		-- so we'll lock them temporarily
		asset.lock_asset_watchers()

		local tex = asset.load(f, asset.TYPE_TEXTURE)
		tex = (tex ~= nil) and tex:GetVkTexture() or nil
		if tex == nil then
			pfm.log("Failed to import texture!", pfm.LOG_CATEGORY_PFM)
			asset.unlock_asset_watchers()
			return util.EVENT_REPLY_HANDLED
		end
		local texInfo = util.TextureInfo()
		texInfo.flags = bit.bor(texInfo.flags, util.TextureInfo.FLAG_BIT_GENERATE_MIPMAPS)
		texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS

		if asset.exists(texPath:GetString(), asset.TYPE_TEXTURE) then
			-- A texture with the target name already exists, we'll add a postfix to make it unique
			local tmpPath
			local i = 2
			repeat
				tmpPath = texPath:GetString() .. "_" .. tostring(i)
				i = i + 1
			until not asset.exists(tmpPath, asset.TYPE_TEXTURE)
			texPath = util.Path.CreateFilePath(tmpPath)
		end

		pfm.log("Saving texture as '" .. "materials/" .. texPath:GetString() .. "'...", pfm.LOG_CATEGORY_PFM)
		local result = util.save_image(tex:GetImage(), "materials/" .. texPath:GetString(), texInfo)
		if result == false then
			pfm.log("Saving failed!", pfm.LOG_CATEGORY_PFM)
		end

		asset.unlock_asset_watchers()

		-- Force texture reload
		asset.reload(texPath:GetString(), asset.TYPE_TEXTURE)

		if result == false then
			console.print_warning("Unable to load texture '" .. tFiles[1] .. "': " .. errMsg)
			return util.EVENT_REPLY_HANDLED
		end
		self:SetTexture(texPath:GetString())
		self:ReloadTexture(true)
		self:CallCallbacks("OnTextureImported")
		return util.EVENT_REPLY_HANDLED
	end)
	self:SetNormalMap(false)
end
function gui.PFMTextureSlot:SetClearTexture(clearTex)
	self.m_clearTex = clearTex
end
function gui.PFMTextureSlot:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
		local pContext = gui.open_context_menu()
		if util.is_valid(pContext) == false then
			return
		end
		pContext:SetPos(input.get_cursor_pos())
		pContext:AddItem(locale.get_text("clear"), function()
			if self.m_clearTex ~= nil then
				self:SetTexture(self.m_clearTex)
			else
				self:ClearTexture()
			end
		end)
		--[[if(self:IsValidTexture()) then
			pContext:AddItem(locale.get_text("flip"),function()
				self:Flip()
			end)
		end]]
		self:CallCallbacks("PopulateContextMenu", pContext)
		pContext:Update()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTextureSlot:SetImportPath(matPath)
	self.m_matPath = matPath
end
function gui.PFMTextureSlot:SetNormalMap(normalMap)
	self.m_normalMap = normalMap
end
function gui.PFMTextureSlot:SetTransparencyEnabled(enabled)
	-- TODO
end
function gui.PFMTextureSlot:Flip()
	local tex = self:GetTextureObject()
	if tex == nil then
		return
	end
	local imgBuffers = tex:GetImage():ToImageBuffer(true, true)
	for _, layer in ipairs(imgBuffers) do
		for _, imgMipmap in ipairs(layer) do
			imgMipmap:Flip(true, true) -- Flip horizontally/vertically
		end
	end
	-- TODO: Save the image in the original format
end
function gui.PFMTextureSlot:SetTexture(tex)
	if type(tex) ~= "string" then
		self.m_texRect:SetTexture(tex)
		return
	end
	self.m_texPath = tex
	self:ReloadTexture()
end
function gui.PFMTextureSlot:SetAlphaMode(alphaMode)
	self.m_texRect:SetAlphaMode(alphaMode)
end
function gui.PFMTextureSlot:SetAlphaCutoff(cutoff)
	self.m_texRect:SetAlphaCutoff(cutoff)
end
function gui.PFMTextureSlot:SetAlphaFactor(factor)
	local col = self.m_texRect:GetColor()
	col.a = factor * 255
	self.m_texRect:SetColor(col)
end
function gui.PFMTextureSlot:GetTextureObject()
	return self.m_texRect:GetTexture()
end
function gui.PFMTextureSlot:IsValidTexture()
	return asset.exists(self.m_texPath, asset.TYPE_TEXTURE)
end
function gui.PFMTextureSlot:ClearTexture()
	self.m_texPath = nil
	self.m_texRect:ClearTexture()
	self:CallCallbacks("OnTextureCleared")
end
function gui.PFMTextureSlot:GetTexture()
	return self.m_texPath
end
function gui.PFMTextureSlot:ReloadTexture(reloadCache)
	if self:IsValidTexture() == false then
		return
	end
	local tex
	if reloadCache then
		tex = asset.reload(self.m_texPath, asset.TYPE_TEXTURE)
	else
		tex = asset.load(self.m_texPath, asset.TYPE_TEXTURE)
	end
	tex = (tex ~= nil) and tex:GetVkTexture() or nil
	if tex == nil then
		return
	end
	self.m_texRect:SetTexture(tex)
end
function gui.PFMTextureSlot:SetGreyscaleChannel(channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_RED, channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_GREEN, channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_BLUE, channel)
end
gui.register("WIPFMTextureSlot", gui.PFMTextureSlot)
