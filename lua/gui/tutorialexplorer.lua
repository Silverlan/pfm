--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("videoexplorer.lua")

util.register_class("gui.TutorialExplorer",gui.VideoExplorer)
function gui.TutorialExplorer:__init()
	gui.VideoExplorer.__init(self)
end
function gui.TutorialExplorer:OnInitialize()
	gui.VideoExplorer.OnInitialize(self)

	self:SetAssetType(gui.AssetIcon.ASSET_TYPE_CUSTOM)
	self:SetFileExtensions("pvr",{})

	self:AddCallback("OnProjectDoubleClicked",function(el,elIcon,path)
		local filmmaker = tool.get_filmmaker()
		local window = filmmaker:OpenWindow("video_player")
		filmmaker:GoToWindow("video_player")

		local el = window:GetVideoPlayerElement()

		local vp = el:GetVideoPlayer()
		if(vp ~= nil) then
			local projectData = elIcon:GetDataBlock()
			local videoSettings = (projectData ~= nil) and gui.VRVideoPlayer.get_video_settings(projectData) or nil
			if(videoSettings ~= nil) then
				gui.VRVideoPlayer.apply_video_settings(el,videoSettings)
			end
		end

		local playControls = window:GetPlayControls()
		playControls:GetPlayButton():TogglePlay()
	end)
end
gui.register("WITutorialExplorer",gui.TutorialExplorer)
