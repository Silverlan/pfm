--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")
include("/gui/vr_player/video_player.lua")

util.register_class("gui.VideoExplorer", gui.AssetExplorer)
function gui.VideoExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self.m_previewVideo = gui.create("VRVideoPlayer", self)
	self.m_previewVideo:SetAutoAlignToParent(true)
	self.m_previewVideo:SetBackgroundElement(true, true)
	self.m_previewVideo:SetZPos(100)
	self.m_previewVideo:SetVisible(false)
	self.m_previewVideo:SetMouseInputEnabled(false)
	self.m_previewVideo:SetRemoveOnParentRemoval(false)
	self.m_previewVideo:AddCallback("OnTextureSizeChanged", function(el, w, h)
		--self.m_aspectRatioWrapper:SetAspectRatio(w /h)
	end)
	local vp = self.m_previewVideo:GetVideoPlayer()
	if vp ~= nil then
		vp:SetLooping(true)
		vp:SetMuted(true)
	end
	self:AddCallback("OnIconAdded", function(self, el)
		if el.InitializeVideo == nil then
			return
		end
		el:AddCallback("OnCursorEntered", function()
			self:ShowPreview(el)
		end)
		el:AddCallback("OnCursorExited", function()
			self:HidePreview()
		end)
	end)
end
function gui.VideoExplorer:GetIdentifier()
	return "video_explorer"
end
function gui.VideoExplorer:CreateAssetIcon(path, assetName, isDirectory, importAsset)
	if isDirectory then
		return gui.AssetExplorer.CreateAssetIcon(self, path, assetName, isDirectory, importAsset)
	end

	local el = gui.create("WIVideoAssetIcon", self)
	el:SetAsset(path, assetName, importAsset)
	el:SetMouseInputEnabled(true)
	el:AddCallback("OnDoubleClick", function(el)
		local ptPath = util.Path(el:GetAsset())
		ptPath:PopFront()
		self:CallCallbacks("OnProjectDoubleClicked", el, ptPath:GetString())
	end)
	return el
end
function gui.VideoExplorer:OnRemove()
	util.remove(self.m_previewVideo)
end
function gui.VideoExplorer:ShowPreview(el)
	local elBg = el:GetBackgroundElement()
	if util.is_valid(elBg) == false then
		return
	end
	if el.InitializeVideo == nil or el:InitializeVideo(self.m_previewVideo) == false then
		return
	end
	self.m_previewVideo:SetParent(elBg)
	self.m_previewVideo:SetVisible(true)
	local vp = self.m_previewVideo:GetVideoPlayer()
	if vp ~= nil then
		vp:Play()
	end
end
function gui.VideoExplorer:HidePreview()
	--self.m_previewVideo:FadeOut(0.2)
	self.m_previewVideo:SetVisible(false)
	local vp = self.m_previewVideo:GetVideoPlayer()
	if vp ~= nil then
		vp:ClearFile()
	end
end
gui.register("WIVideoExplorer", gui.VideoExplorer)

-----------------

util.register_class("gui.VideoAssetIcon", gui.AssetIcon)
function gui.VideoAssetIcon:__init()
	gui.AssetIcon.__init(self)
end
function gui.VideoAssetIcon:OnInitialize()
	gui.AssetIcon.OnInitialize(self)
end
function gui.VideoAssetIcon:GetUdmData()
	return self.m_udmData
end
function gui.VideoAssetIcon:InitializeVideo(video)
	local projectData = self:GetUdmData()
	if projectData == nil then
		return false
	end
	local videoSettings = gui.VRVideoPlayer.get_video_settings(projectData)
	if videoSettings == false then
		return false
	end
	gui.VRVideoPlayer.apply_video_settings(video, videoSettings)
	--video:FadeIn(0.2)
	local vp = video:GetVideoPlayer()

	local rot = EulerAngles(0, 90, 0):ToQuaternion()
	local zoomLevel = 1.0
	if videoSettings.preview ~= nil then
		if vp ~= nil then
			vp:Seek(videoSettings.preview.startTime)
		end
		local pitch = videoSettings.preview.pitch
		local yaw = videoSettings.preview.yaw + 90.0
		rot = EulerAngles(0, yaw, pitch):ToQuaternion()
		zoomLevel = videoSettings.preview.zoomLevel
	end
	video:SetCameraRotation(rot)
	video:SetZoomLevel(zoomLevel)
	return true
end
function gui.VideoAssetIcon:ApplyAsset(path, importAsset)
	local assetPath = self:GetAsset()
	local udmData, err = udm.load(assetPath)
	if udmData ~= false then
		udmData = udmData:GetAssetData():GetData()
		udmData = udmData:GetChildren()
		udmData = select(2, pairs(udmData)(udmData))
		self.m_udmData = udmData:ClaimOwnership()
		local icon = udmData:GetValue("icon", udm.TYPE_STRING) or ""
		if #icon > 0 then
			icon = file.get_file_path(assetPath) .. icon
			icon = "materials/" .. icon
		end
		if file.exists(icon) then
			local imgBuf = util.load_image(icon) -- TODO: Load asynchronously
			if imgBuf ~= nil then
				local img = prosper.create_image(imgBuf)
				local tex = prosper.create_texture(
					img,
					prosper.TextureCreateInfo(),
					prosper.ImageViewCreateInfo(),
					prosper.SamplerCreateInfo()
				)
				tex:SetDebugName("video_asset_icon_tex")
				self:SetTexture(tex)
			end
		end
		local title = udmData:GetValue("title", udm.TYPE_STRING) or ""
		if #title > 0 then
			self:SetText(title)
		end
	else
		self:SetMaterial("error", self:GetWidth(), self:GetHeight())
	end

	--[[self.m_assetType = asset.TYPE_MATERIAL
	local iconPath = self:GetIconLocation()
	if(asset.exists(iconPath,asset.TYPE_MATERIAL)) then
		self:SetMaterial(iconPath)
		return
	end
	if(gui.AssetIcon.impl.iconGenerator == nil) then
		print("Creating new icon generator...")
		gui.AssetIcon.impl.iconGenerator = gui.AssetIcon.IconGenerator(128,128)
	end
	if(importAsset == true or asset.exists(mat,asset.TYPE_MATERIAL)) then
		local path = util.Path(mat)
		path:RemoveFileExtension()
		self:SetMaterial(path:GetString())
		if(true) then--self.m_useMaterialSphere) then
			gui.AssetIcon.impl.iconGenerator:AddModelToQueue(self:GetPreviewModel(),function()
				if(self:IsValid() == false) then return end
				self:SetMaterial(iconPath)
			end,iconPath,{
				materialOverride = self:GetMaterialOverride()
			})
		end
	else
		self:SetMaterial("third_party/source_engine",100,30)
		-- TODO: We need a way to determine which game the asset is from!
		-- self:SetMaterial("third_party/gamebryo_logo",100,41)
	end]]
end
function gui.VideoAssetIcon:GetTypeIdentifier()
	return "video"
end
function gui.VideoAssetIcon:GetPreviewModel() end
gui.register("WIVideoAssetIcon", gui.VideoAssetIcon)
