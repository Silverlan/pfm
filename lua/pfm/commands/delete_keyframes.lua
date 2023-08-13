--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandDeleteKeyframes", pfm.Command)
function Command:DoExecute()
	local session = tool.get_filmmaker():GetSession()
	local filmClip = session:GetActiveClip()
	pfm.log("Deleting " .. #dpsData .. " keyframes...", pfm.LOG_CATEGORY_PFM)
	for _, dpRef in ipairs(dpsData) do
		local actor = filmClip:FindActorByUniqueId(tostring(dpRef:GetActorUuid()))
		if actor ~= nil then
			local graphData = self:FindGraphData(actor, dpRef:GetPropertyPath(), dpRef:GetTypeComponentIndex())
			if graphData ~= nil and util.is_valid(graphData.curve) then
				local dp = graphData.curve:FindDataPoint(dpRef:GetTime())
				if util.is_valid(dp) then
					self:RemoveDataPoint(dp)
				else
					pfm.log(
						"Failed to delete keyframe for '"
							.. dpRef:GetPropertyPath()
							.. "' of actor '"
							.. tostring(dpRef:GetActorUuid())
							.. "' at timestamp '"
							.. dpRef:GetTime()
							.. "': No keyframe found at this timestamp!",
						pfm.LOG_CATEGORY_PFM,
						pfm.LOG_SEVERITY_WARNING
					)
				end
			else
				pfm.log(
					"Failed to delete keyframe for '"
						.. dpRef:GetPropertyPath()
						.. "' of actor '"
						.. tostring(dpRef:GetActorUuid())
						.. "' at timestamp '"
						.. dpRef:GetTime()
						.. "': Graph for type component index "
						.. dpRef:GetTypeComponentIndex()
						.. " not found!",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_WARNING
				)
			end
		else
			pfm.log(
				"Failed to delete keyframe for '"
					.. dpRef:GetPropertyPath()
					.. "' at timestamp '"
					.. dpRef:GetTime()
					.. "': Actor '"
					.. tostring(dpRef:GetActorUuid())
					.. "' not found!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
		end
	end
end
function Command:DoUndo()
	local session = tool.get_filmmaker():GetSession()
	local filmClip = session:GetActiveClip()
	for _, dpRef in ipairs(dpsData) do
		local actor = filmClip:FindActorByUniqueId(tostring(dpRef:GetActorUuid()))
		if actor ~= nil then
			pfm.get_project_manager():SetActorAnimationComponentProperty(
				actor,
				dpRef:GetPropertyPath(),
				dpRef:GetTime(),
				dpRef:GetValue(),
				dpRef:GetValueType(),
				dpRef:GetTypeComponentIndex()
			)
		else
			pfm.log(
				"Failed to create keyframe for '"
					.. dpRef:GetPropertyPath()
					.. "' at timestamp '"
					.. dpRef:GetTime()
					.. "': Actor '"
					.. tostring(dpRef:GetActorUuid())
					.. "' not found!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_WARNING
			)
		end
	end
end
pfm.register_command("delete_keyframes", Command)
