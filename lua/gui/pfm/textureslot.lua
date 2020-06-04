--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTextureSlot",gui.Base)
function gui.PFMTextureSlot:__init()
	gui.Base.__init(self)
end
function gui.PFMTextureSlot:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)

	self.m_texRect = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)

	self.m_outline = gui.create("WIOutlinedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_outline:SetColor(Color.Black)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnFilesDropped",function(texSlot,tFiles)
		if(#tFiles == 0) then return util.EVENT_REPLY_UNHANDLED end
		local f = game.open_dropped_file(tFiles[1],true)
		if(f == nil) then return util.EVENT_REPLY_UNHANDLED end
		if(self.m_matPath == nil) then
			local texLoadFlags = bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_DONT_CACHE)
			local tex = game.load_texture(f,texLoadFlags)
			if(tex ~= nil) then self.m_texRect:SetTexture(tex)
			else self.m_texRect:ClearTexture() end
			return util.EVENT_REPLY_HANDLED
		end
		local texPath = util.Path(self.m_matPath) +tFiles[1]
		texPath:RemoveFileExtension()
		local texImportInfo = asset.TextureImportInfo()

		-- TODO: Doesn't seem to work properly?
		-- texImportInfo.normalMap = self.m_normalMap

		-- Importing the texture could potentially trigger a material reload through the asset watchers, which we want to avoid,
		-- so we'll lock them temporarily
		asset.lock_asset_watchers()

		local texLoadFlags = bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_DONT_CACHE)
		local tex = game.load_texture(f,texLoadFlags)
		local texInfo = util.TextureInfo()
		texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
		local result = util.save_image(tex:GetImage(),"materials/" .. texPath:GetString(),texInfo)

		-- TODO: This doesn't work properly?
		--local result,errMsg = asset.import_texture(f,texImportInfo,texPath:GetString())

		asset.unlock_asset_watchers()

		-- Force texture reload
		texLoadFlags = bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_RELOAD)
		game.load_texture(texPath:GetString(),texLoadFlags)

		if(result == false) then
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
function gui.PFMTextureSlot:SetClearTexture(clearTex) self.m_clearTex = clearTex end
function gui.PFMTextureSlot:OnMouseEvent(button,state,mods)
	if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
		local pContext = gui.open_context_menu()
		if(util.is_valid(pContext) == false) then return end
		pContext:SetPos(input.get_cursor_pos())
		pContext:AddItem(locale.get_text("clear"),function()
			if(self.m_clearTex ~= nil) then self:SetTexture(self.m_clearTex)
			else self:ClearTexture() end
		end)
		self:CallCallbacks("PopulateContextMenu",pContext)
		pContext:Update()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTextureSlot:SetImportPath(matPath) self.m_matPath = matPath end
function gui.PFMTextureSlot:SetNormalMap(normalMap) self.m_normalMap = normalMap end
function gui.PFMTextureSlot:SetTransparencyEnabled(enabled)
	-- TODO
end
function gui.PFMTextureSlot:SetTexture(tex)
	if(type(tex) ~= "string") then
		self.m_texRect:SetTexture(tex)
		return
	end
	self.m_texPath = tex
	self:ReloadTexture()
end
function gui.PFMTextureSlot:GetTextureObject() return self.m_texRect:GetTexture() end
function gui.PFMTextureSlot:ClearTexture()
	self.m_texPath = nil
	self.m_texRect:ClearTexture()
	self:CallCallbacks("OnTextureCleared")
end
function gui.PFMTextureSlot:GetTexture() return self.m_texPath end
function gui.PFMTextureSlot:ReloadTexture(reloadCache)
	if(asset.exists(self.m_texPath,asset.TYPE_TEXTURE) == false) then return end
	local texLoadFlags = game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY
	if(reloadCache) then texLoadFlags = bit.bor(texLoadFlags,game.TEXTURE_LOAD_FLAG_BIT_RELOAD) end
	local tex = game.load_texture(self.m_texPath,texLoadFlags)
	if(tex == nil) then return end
	self.m_texRect:SetTexture(tex)
end
function gui.PFMTextureSlot:SetGreyscaleChannel(channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_RED,channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_GREEN,channel)
	self.m_texRect:SetChannelSwizzle(gui.TexturedShape.CHANNEL_BLUE,channel)
end
gui.register("WIPFMTextureSlot",gui.PFMTextureSlot)
