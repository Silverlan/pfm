--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local IkRig = util.register_class("util.IkRig")
util.IkRig.extensions = {"pikr","pikr_b"}
function util.IkRig.load(fileName)
	local udmData,err = udm.load(fileName)
	if(udmData == false) then return false end
	return util.IkRig.load_from_udm_data(udmData:GetAssetData():GetData())
end
function util.IkRig.load_from_udm_data(udmData)
	local rig = util.IkRig()
	for _,udmBone in ipairs(udmData:Get("bones"):GetArrayValues()) do
		local name = udmBone:GetValue("name",udm.TYPE_STRING)
		local locked = udmBone:GetValue("locked",udm.TYPE_BOOLEAN)
		rig:AddBone(name)
		if(locked) then rig:SetBoneLocked(name,locked) end
	end
	for _,udmControl in ipairs(udmData:Get("controls"):GetArrayValues()) do
		local bone = udmControl:GetValue("bone",udm.TYPE_STRING)
		local type = udmControl:GetValue("type",udm.TYPE_STRING)
		if(type == "drag") then rig:AddDragControl(bone)
		elseif(type == "state") then rig:AddStateControl(bone) end
	end
	for _,udmConstraint in ipairs(udmData:Get("constraints"):GetArrayValues()) do
		local type = udmConstraint:GetValue("type",udm.TYPE_STRING)
		local bone0 = udmConstraint:GetValue("bone0",udm.TYPE_STRING)
		local bone1 = udmConstraint:GetValue("bone1",udm.TYPE_STRING)
		if(type == "hinge") then
			local min = udmConstraint:GetValue("min",udm.TYPE_FLOAT)
			local max = udmConstraint:GetValue("max",udm.TYPE_FLOAT)
			rig:AddHingeConstraint(bone0,bone1,min,max)
		elseif(type == "ballSocket") then
			local min = udmConstraint:GetValue("min",udm.TYPE_EULER_ANGLES)
			local max = udmConstraint:GetValue("max",udm.TYPE_EULER_ANGLES)
			rig:AddBallSocketConstraint(bone0,bone1,min,max)
		end
	end
	return rig
end
function IkRig:__init()
	self.m_bones = {}
	self.m_controls = {}
	self.m_constraints = {}
end
function IkRig:DebugPrint()
	local el = udm.create_element()
	self:ToUdmData(el)
	print(el:ToAscii())
end
function IkRig:ToUdmData(udmData)
	local udmBones
	if(udmData:HasValue("bones")) then udmBones = udmData:Get("bones")
	else udmBones = udmData:AddArray("bones",0,udm.TYPE_ELEMENT) end
	for _,boneData in ipairs(self.m_bones) do
		udmBones:Resize(udmBones:GetSize() +1)
		local udmBone = udmBones:Get(udmBones:GetSize() -1)
		udmBone:SetValue("name",udm.TYPE_STRING,boneData.name)
		udmBone:SetValue("locked",udm.TYPE_BOOLEAN,boneData.locked)
	end

	local udmControls
	if(udmData:HasValue("controls")) then udmControls = udmData:Get("controls")
	else udmControls = udmData:AddArray("controls",0,udm.TYPE_ELEMENT) end
	for _,controlData in ipairs(self.m_controls) do
		udmControls:Resize(udmControls:GetSize() +1)
		local udmControl = udmControls:Get(udmControls:GetSize() -1)
		udmControl:SetValue("bone",udm.TYPE_STRING,controlData.bone)
		udmControl:SetValue("type",udm.TYPE_STRING,controlData.type)
	end

	local udmConstraints
	if(udmData:HasValue("constraints")) then udmConstraints = udmData:Get("constraints")
	else udmConstraints = udmData:AddArray("constraints",0,udm.TYPE_ELEMENT) end
	for _,constraintData in ipairs(self.m_constraints) do
		udmConstraints:Resize(udmConstraints:GetSize() +1)
		local udmConstraint = udmConstraints:Get(udmConstraints:GetSize() -1)
		udmConstraint:SetValue("type",udm.TYPE_STRING,constraintData.type)
		udmConstraint:SetValue("bone0",udm.TYPE_STRING,constraintData.bone0)
		udmConstraint:SetValue("bone1",udm.TYPE_STRING,constraintData.bone1)
		if(constraintData.type == "hinge") then
			udmConstraint:SetValue("min",udm.TYPE_FLOAT,constraintData.min)
			udmConstraint:SetValue("max",udm.TYPE_FLOAT,constraintData.max)
		elseif(constraintData.type == "ballSocket") then
			udmConstraint:SetValue("min",udm.TYPE_EULER_ANGLES,constraintData.min)
			udmConstraint:SetValue("max",udm.TYPE_EULER_ANGLES,constraintData.max)
		end
	end
end
function IkRig:Save(fileName)
	local filePath = util.Path.CreateFilePath(fileName)
	local udmData,err = udm.create("PIKC",1)
	if(udmData == false) then
		pfm.log("Unable to save ik config '" .. filePath:GetString() .. "': " .. err,pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local assetData = udmData:GetAssetData():GetData()
	self:ToUdmData(assetData)

	if(file.create_path(filePath:GetPath()) == false) then return end
	local f = file.open(filePath:GetString(),file.OPEN_MODE_WRITE)
	if(f == nil) then
		pfm.log("Unable to open file '" .. filePath:GetString() .. "' for writing!",pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local res,err = udmData:SaveAscii(f) -- ,udm.ASCII_SAVE_FLAG_BIT_INCLUDE_HEADER)
	f:Close()
	if(res == false) then
		pfm.log("Failed to save ik config as '" .. filePath:GetString() .. "': " .. err,pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	return true
end
function IkRig:IsBoneLocked(bone)
	for i,boneData in ipairs(self.m_bones) do
		if(boneData.name == bone) then
			return boneData.locked
		end
	end
	return false
end
function IkRig:GetBones() return self.m_bones end
function IkRig:GetControls() return self.m_controls end
function IkRig:GetConstraints() return self.m_constraints end
function IkRig:SetBoneLocked(bone,locked)
	for _,boneData in ipairs(self.m_bones) do
		if(boneData.name == bone) then
			boneData.locked = locked
			break
		end
	end
end
function IkRig:RemoveBone(bone,boneOnly)
	for i,boneData in ipairs(self.m_bones) do
		if(boneData.name == bone) then
			table.remove(self.m_bones,i)
			break
		end
	end
	if(boneOnly) then return end
	self:RemoveControl(bone)
	for i=#self.m_constraints,1,-1 do
		local constraintData = self.m_constraints[i]
		if(constraintData.bone0 == name or constraintData.bone1 == name) then
			table.remove(self.m_constraints,i)
		end
	end
end
function IkRig:HasBone(name)
	for i,boneData in ipairs(self.m_bones) do
		if(boneData.name == name) then
			return true
		end
	end
	return false
end
function IkRig:AddBone(name)
	self:RemoveBone(name,true)
	table.insert(self.m_bones,{
		name = name,
		locked = false
	})
end
function IkRig:HasControl(bone)
	for i,ctrlData in ipairs(self.m_controls) do
		if(ctrlData.bone == bone) then
			return true
		end
	end
	return false
end
function IkRig:RemoveControl(bone)
	for i,ctrlData in ipairs(self.m_controls) do
		if(ctrlData.bone == bone) then
			table.remove(self.m_controls,i)
			break
		end
	end
end
function IkRig:AddDragControl(bone)
	self:RemoveControl(bone)
	table.insert(self.m_controls,{
		bone = bone,
		type = "drag"
	})
end
function IkRig:AddStateControl(bone)
	self:RemoveControl(bone)
	for i,ctrlData in ipairs(self.m_controls) do
		if(ctrlData.bone == bone) then
			table.remove(self.m_controls,i)
			break
		end
	end
	table.insert(self.m_controls,{
		bone = bone,
		type = "state"
	})
end
function IkRig:RemoveConstraints(bone0,bone1)
	for i,constraintData in ipairs(self.m_constraints) do
		if((constraintData.bone0 == bone0 and constraintData.bone1 == bone1) or (constraintData.bone0 == bone1 and constraintData.bone1 == bone0)) then
			table.remove(self.m_constraints,i)
			break
		end
	end
end
function IkRig:RemoveConstraints(c)
	for i,constraintData in ipairs(self.m_constraints) do
		if(constraintData == c) then
			table.remove(self.m_constraints,i)
			break
		end
	end
end
function IkRig:AddFixedConstraint(bone0,bone1)
	self:RemoveConstraint(bone0,bone1)
	table.insert(self.m_constraints,{
		bone0 = bone0,
		bone1 = bone1,
		type = "fixed"
	})
	return self.m_constraints[#self.m_constraints]
end
function IkRig:AddHingeConstraint(bone0,bone1,min,max)
	self:RemoveConstraint(bone0,bone1)
	table.insert(self.m_constraints,{
		bone0 = bone0,
		bone1 = bone1,
		type = "hinge",
		min = min,
		max = max
	})
	return self.m_constraints[#self.m_constraints]
end
function IkRig:AddBallSocketConstraint(bone0,bone1,min,max)
	self:RemoveConstraint(bone0,bone1)
	table.insert(self.m_constraints,{
		bone0 = bone0,
		bone1 = bone1,
		type = "ballSocket",
		min = min,
		max = max
	})
	return self.m_constraints[#self.m_constraints]
end
function IkRig:SetConstraintLimits(c,min,max)
	c.min = min
	c.max = max
end
function IkRig:GetBones() return self.m_bones end
function IkRig:GetControls() return self.m_controls end
function IkRig:GetConstraints() return self.m_constraints end
