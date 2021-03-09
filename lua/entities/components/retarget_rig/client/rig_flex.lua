--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function ents.RetargetRig.Rig.load_flex_controller_map(db,srcMdl,dstMdl)
	local fcm = db:FindBlock("flex_controller_map")
	local translationTable = {}
	if(fcm ~= nil) then
		for fcNameSrc,mappings in pairs(fcm:GetChildBlocks()) do
			local fcIdSrc = srcMdl:LookupFlexController(fcNameSrc)
			if(fcIdSrc == -1) then console.print_warning("Retarget rig has invalid flex controller reference '" .. fcNameSrc .. "' for model '" .. srcMdl:GetName() .. "'! Ignoring...")
			else
				translationTable[fcIdSrc] = {}
				for fcNameDst,mappingData in pairs(mappings:GetChildBlocks()) do
					local fcIdDst = dstMdl:LookupFlexController(fcNameDst)
					if(fcIdDst == -1) then console.print_warning("Retarget rig has invalid flex controller reference '" .. fcNameDst .. "' for model '" .. dstMdl:GetName() .. "'! Ignoring...")
					else
						translationTable[fcIdSrc][fcIdDst] = {
							min_source = mappingData:GetFloat("min_source"),
							max_source = mappingData:GetFloat("max_source"),

							min_target = mappingData:GetFloat("min_target"),
							max_target = mappingData:GetFloat("max_target")
						}
					end
				end
			end
		end
	end
	return translationTable
end

function ents.RetargetRig.Rig.save_flex_controller_map(db,srcMdl,dstMdl,flexControllerTranslationTable)
	local fcm = db:AddBlock("flex_controller_map")
	for flexCId0,mappings in pairs(flexControllerTranslationTable) do
		local flexC0 = srcMdl:GetFlexController(flexCId0)
		if(flexC0 ~= nil) then
			local blockSrc = fcm:AddBlock(flexC0.name)
			for flexCId1,data in pairs(mappings) do
				local flexC1 = dstMdl:GetFlexController(flexCId1)
				if(flexC1 ~= nil) then
					local blockDst = blockSrc:AddBlock(flexC1.name)
					blockDst:SetValue("float","min_source",tostring(data.min_source))
					blockDst:SetValue("float","max_source",tostring(data.max_source))
					blockDst:SetValue("float","min_target",tostring(data.min_target))
					blockDst:SetValue("float","max_target",tostring(data.max_target))
				end
			end
		end
	end
end

function ents.RetargetRig.Rig:GetFlexControllerTranslationTable() return self.m_flexTranslationTable end

function ents.RetargetRig.Rig:ClearFlexControllerTranslation(flexCId0,flexCId1)
	if(self.m_flexTranslationTable[flexCId0] == nil) then return end
	if(flexCId1 == nil) then
		self.m_flexTranslationTable[flexCId0] = nil
		return
	end
	self.m_flexTranslationTable[flexCId0][flexCId1] = nil
end

function ents.RetargetRig.Rig:SetFlexControllerTranslation(flexCId0,flexCId1,minSrc,maxSrc,minDst,maxDst)
	print("SetFlexControllerTranslation: ",flexCId0,flexCId1,minSrc,maxSrc,minDst,maxDst)
	minSrc = minSrc or 0.0
	maxSrc = maxSrc or 1.0
	minDst = minDst or 0.0
	maxDst = maxDst or 1.0
	self.m_flexTranslationTable[flexCId0] = self.m_flexTranslationTable[flexCId0] or {}
	self.m_flexTranslationTable[flexCId0][flexCId1] = self.m_flexTranslationTable[flexCId0][flexCId1] or {}
	local data = self.m_flexTranslationTable[flexCId0][flexCId1]
	data.min_source = minSrc
	data.max_source = maxSrc

	data.min_target = minDst
	data.max_target = maxDst
end
