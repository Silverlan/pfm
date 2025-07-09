-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm.udm.Bookmark.TIME_EPSILON = 0.0001
function pfm.udm.BookmarkSet:FindBookmark(t)
	for _, bm in ipairs(self:GetBookmarks()) do
		local tBm = bm:GetTime()
		if math.abs(tBm - t) < pfm.udm.Bookmark.TIME_EPSILON then
			-- Bookmark already exists at this timestamp
			return bm
		end
	end
end

function pfm.udm.BookmarkSet:AddBookmarkAtTimestamp(t)
	--[[local bm = self:FindBookmark(t)
	if bm ~= nil then
		return bm, false
	end]]

	local bm = self:AddBookmark()
	bm:SetTime(t)
	return bm, true
end

function pfm.udm.BookmarkSet:RemoveBookmarkAtTimestamp(t)
	local bm = self:FindBookmark(t)
	if bm == nil then
		return
	end
	self:RemoveBookmark(bm)
end

function pfm.udm.Bookmark:GetInterfaceTime()
	local t = self:GetTime()
	local parent = self:GetParent()
	while parent ~= nil do
		if parent.GetTimeFrame then
			local tf = parent:GetTimeFrame()
			t = tf:GlobalizeOffset(t)
		end
		parent = parent:GetParent()
	end
	return t
end

function pfm.udm.Bookmark:GetDataTime()
	local t = self:GetTime()
	local parent = self:GetParent()
	while parent ~= nil do
		if parent.GetTimeFrame then
			local tf = parent:GetTimeFrame()
			t = tf:LocalizeOffset(t)
		end
		parent = parent:GetParent()
	end
	return t
end
