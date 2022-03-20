--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.AnimationClip:OnInitialize()

end
function pfm.udm.AnimationClip:FindChannel(path)
	for _,channel in ipairs(self:GetAnimation():GetChannels()) do
		if(channel:GetTargetPath() == path) then return channel end
	end
end

function pfm.udm.EditorAnimationData:FindChannel(targetPath,addIfNotExists)
	for _,channel in ipairs(self:GetChannels()) do
		if(channel:GetTargetPath() == targetPath) then return channel end
	end
	if(addIfNotExists) then
		local channel = self:AddChannel()
		channel:SetTargetPath(targetPath)
		return channel
	end
end

pfm.udm.Bookmark.TIME_EPSILON = 0.0001
function pfm.udm.BookmarkSet:FindBookmark(t)
	for _,bm in ipairs(self:GetBookmarks()) do
		local tBm = bm:GetTime()
		if(math.abs(tBm -t) < pfm.udm.Bookmark.TIME_EPSILON) then
			-- Bookmark already exists at this timestamp
			return bm
		end
	end
end

function pfm.udm.BookmarkSet:AddBookmarkAtTimestamp(t)
	local bm = self:FindBookmark(t)
	if(bm ~= nil) then return bm,false end

	local bm = self:AddBookmark()
	bm:SetTime(t)
	return bm,true
end

function pfm.udm.BookmarkSet:RemoveBookmarkAtTimestamp(t)
	local bm = self:FindBookmark(t)
	if(bm == nil) then return end
	self:RemoveBookmark(bm)
end

function pfm.udm.AnimationClip:AddEditorDataPoint(targetPath,time)
	local editorData = self:GetEditorData()
	local channel = editorData:FindChannel(targetPath,true)
	local bms = channel:GetBookmarkSet()
	local bm,newBookmark = bms:AddBookmarkAtTimestamp(time)
	if(newBookmark == false) then return end
	-- TODO: Add animation data value?
end

function pfm.udm.AnimationClip:MoveEditorDataPoint(path,oldTime,newTime)
	-- TODO: Move bookmark and animation data?
end

function pfm.udm.AnimationClip:RemoveEditorDataPoint(path,time)
	-- Remove bookmark
	-- Remove editor data

	local editorData = self:GetEditorData()
	local channel = editorData:FindChannel(targetPath)
	if(channel == nil) then return end
	local bms = channel:GetBookmarkSet()
	bms:RemoveBookmarkAtTimestamp(time)
end

function pfm.udm.AnimationClip:GetChannel(path,type,addIfNotExists)
	local channel = self:FindChannel(path)
	if(channel ~= nil) then return channel end
	if(addIfNotExists ~= true) then return end
	channel = self:AddChannel(type)
	channel:SetTargetPath(path)
	return channel
end

function pfm.udm.AnimationClip:RemoveChannel(path)
	local channel = self:FindChannel(path)
	if(channel == nil) then return end
	self:GetAnimation():RemoveChannel(channel)
end

function pfm.udm.AnimationClip:AddChannel(type)
	local anim = self:GetAnimation()
	local channel = anim:AddChannel()
	channel:SetValuesValueType(type)
	self.m_panimaAnim = nil
	return channel
end

function pfm.udm.AnimationClip:SetPanimaAnimationDirty()
	self.m_panimaAnim = nil
end

function pfm.udm.AnimationClip:GetPanimaAnimation()
	if(self.m_panimaAnim == nil) then
		self.m_panimaAnim = panima.Animation.load(self:GetAnimation():GetUdmData())
		self.m_panimaAnim:UpdateDuration()
	end
	return self.m_panimaAnim
end
