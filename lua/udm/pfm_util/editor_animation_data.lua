--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
