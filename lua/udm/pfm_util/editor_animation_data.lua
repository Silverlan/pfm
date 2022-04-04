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

pfm.udm.EditorGraphCurveKeyData.HANDLE_IN = 0
pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT = 1
local function get_other_handle(handle)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT end
	return pfm.udm.EditorGraphCurveKeyData.HANDLE_IN
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleDelta(keyIndex,handle)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return self:GetInDelta(keyIndex) end
	return self:GetOutDelta(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleDelta(keyIndex,handle,dela)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return self:SetInDelta(keyIndex,dela) end
	return self:SetOutDelta(keyIndex,dela)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleTimeOffset(keyIndex,handle)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return self:GetInTime(keyIndex) end
	return self:GetOutTime(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleTimeOffset(keyIndex,handle,offset)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return self:SetInTime(keyIndex,offset) end
	return self:SetOutTime(keyIndex,offset)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleType(keyIndex,handle)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then return self:GetInHandleType(keyIndex) end
	return self:GetOutHandleType(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleType(keyIndex,handle,type)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then self:SetInHandleType(keyIndex,type)
	else self:SetOutHandleType(keyIndex,type) end
	if(type == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR) then self:UpdateVectorHandle(keyIndex,handle)
	elseif(type == pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED) then self:UpdateAlignedHandle(keyIndex,handle) end
end
function pfm.udm.EditorGraphCurveKeyData:UpdateKeyframeDependencies(keyIndex,updateIn,updateOut,affectedKeyframeHandles)
	if(updateIn == nil) then updateIn = true end
	if(updateOut == nil) then updateOut = true end
	if(updateIn) then
		local neighborKeyIndex = keyIndex -1
		if(self:GetHandleType(neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT) == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR) then
			self:UpdateVectorHandle(neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
			if(affectedKeyframeHandles ~= nil) then table.insert(affectedKeyframeHandles,1,{neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT}) end
		end
	end
	if(updateOut) then
		local neighborKeyIndex = keyIndex +1
		if(self:GetHandleType(neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR) then
			self:UpdateVectorHandle(neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
			if(affectedKeyframeHandles ~= nil) then table.insert(affectedKeyframeHandles,1,{neighborKeyIndex,pfm.udm.EditorGraphCurveKeyData.HANDLE_IN}) end
		end
	end
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleData(keyIndex,handle,time,delta)
	if(handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) then time = math.min(time,-0.0001)
	else time = math.max(time,0.0001) end

	local affectedKeyframeHandles = {{keyIndex,handle}}
	self:SetHandleTimeOffset(keyIndex,handle,time)
	self:SetHandleDelta(keyIndex,handle,delta)

	local handleType = self:GetHandleType(keyIndex,handle)
	if(handleType == pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED) then
		self:UpdateAlignedHandle(keyIndex,handle)
		table.insert(affectedKeyframeHandles,{keyIndex,get_other_handle(handle)})
	end

	self:UpdateKeyframeDependencies(keyIndex,handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN,handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT,affectedKeyframeHandles)
	return affectedKeyframeHandles
end
function pfm.udm.EditorGraphCurveKeyData:UpdateVectorHandle(keyIndex,handle)
	local otherOffset = (handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) and -1 or 1
	local otherIndex = keyIndex +otherOffset
	if(otherIndex < 0 or otherIndex >= self:GetTimeCount()) then return false end

	local pos = Vector2(self:GetTime(keyIndex),self:GetValue(keyIndex))
	local posTgt = Vector2(
		self:GetTime(otherIndex) +self:GetHandleTimeOffset(otherIndex,get_other_handle(handle)),
		self:GetValue(otherIndex) +self:GetHandleDelta(otherIndex,get_other_handle(handle))
	)
	local dir = (posTgt -pos):GetNormal()
	local dist = pos:Distance(posTgt)
	if(dist > 0.001) then dir = dir *(dist *(1.0 /3.0)) end
	self:SetHandleTimeOffset(keyIndex,handle,dir.x)
	self:SetHandleDelta(keyIndex,handle,dir.y)
end
function pfm.udm.EditorGraphCurveKeyData:UpdateAlignedHandle(keyIndex,handle)
	local time = self:GetHandleTimeOffset(keyIndex,handle)
	local delta = self:GetHandleDelta(keyIndex,handle)
	local otherHandle = get_other_handle(handle)
	-- TODO: Re-calculate length?
	self:SetHandleTimeOffset(keyIndex,otherHandle,-time)
	self:SetHandleDelta(keyIndex,otherHandle,-delta)
end
