--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util = util or {}

util.register_class("util.UpdateChecker")
local Class = util.UpdateChecker
function Class:__init(url, callback)
	if pfm.util.init_curl() == false then
		return
	end

	local requestData = curl.RequestData()
	local request = curl.request(url, requestData)
	request:Start()
	self.m_checkForUpdatesQuery = request
	self.m_checkForUpdatesVerbose = verbose or false

	self.m_cbTick = game.add_callback("Tick", function()
		self:Update()
	end)
	self.m_callback = callback
	self.m_valid = true
end

function Class:__finalize()
	self:Clear()
end

function Class:IsValid()
	return self.m_valid or false
end

function Class:Update()
	if self.m_checkForUpdatesQuery == nil or self.m_checkForUpdatesQuery:IsComplete() == false then
		return
	end
	if self.m_checkForUpdatesQuery:IsSuccessful() then
		local data = string.split(self.m_checkForUpdatesQuery:GetResult():ReadString(), ";")
		if #data > 0 then
			local version = util.Version(data[1])
			self.m_callback(version)
		end
	else
		-- Failed to check for updates
	end
	self:Clear()
end

function Class:Clear()
	util.remove(self.m_cbTick)
	self.m_checkForUpdatesQuery = nil
	self.m_checkForUpdatesVerbose = nil
	self.m_valid = false
end
