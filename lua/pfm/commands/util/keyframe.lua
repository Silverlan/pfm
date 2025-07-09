-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}
pfm.util.store_keyframe_data = function(data, key)
	data:SetArrayValues("times", udm.TYPE_FLOAT, key:GetTimes())
	data:SetArrayValues("values", udm.TYPE_FLOAT, key:GetValues())
	data:SetArrayValues("inTimes", udm.TYPE_FLOAT, key:GetInTimes())
	data:SetArrayValues("inDeltas", udm.TYPE_FLOAT, key:GetInDeltas())
	data:SetArrayValues("inHandleTypes", udm.TYPE_UINT8, key:GetInHandleTypes())
	data:SetArrayValues("outTimes", udm.TYPE_FLOAT, key:GetOutTimes())
	data:SetArrayValues("outDeltas", udm.TYPE_FLOAT, key:GetOutDeltas())
	data:SetArrayValues("outHandleTypes", udm.TYPE_UINT8, key:GetOutHandleTypes())
end
pfm.util.restore_keyframe_data = function(data, key)
	local times = data:GetArrayValues("times", udm.TYPE_FLOAT)
	local values = data:GetArrayValues("values", udm.TYPE_FLOAT)
	local inTimes = data:GetArrayValues("inTimes", udm.TYPE_FLOAT)
	local inDeltas = data:GetArrayValues("inDeltas", udm.TYPE_FLOAT)
	local inHandleTypes = data:GetArrayValues("inHandleTypes", udm.TYPE_UINT8)
	local outTimes = data:GetArrayValues("outTimes", udm.TYPE_FLOAT)
	local outDeltas = data:GetArrayValues("outDeltas", udm.TYPE_FLOAT)
	local outHandleTypes = data:GetArrayValues("outHandleTypes", udm.TYPE_UINT8)
	for i = 0, #times - 1 do
		key:SetTime(i, times[i + 1])
		key:SetValue(i, values[i + 1])
		key:SetInTime(i, inTimes[i + 1])
		key:SetInDelta(i, inDeltas[i + 1])
		key:SetInHandleType(i, inHandleTypes[i + 1])
		key:SetOutTime(i, outTimes[i + 1])
		key:SetOutDelta(i, outDeltas[i + 1])
		key:SetOutHandleType(i, outHandleTypes[i + 1])
	end
end
