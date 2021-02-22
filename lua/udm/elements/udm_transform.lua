--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_TRANSFORM = fudm.register_element("Transform")
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"position",fudm.Vector3(Vector()))
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"rotation",fudm.Quaternion(Quaternion()))
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"scale",fudm.Vector3(Vector(1.0,1.0,1.0)))
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"overrideParent",fudm.ELEMENT_TYPE_ANY)
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"overridePos",fudm.Bool(false))
fudm.register_element_property(fudm.ELEMENT_TYPE_TRANSFORM,"overrideRot",fudm.Bool(false))

function fudm.Transform:__eq(other)
	return self:GetPosition() == other:GetPosition() and self:GetRotation() == other:GetRotation() and self:GetScale() == other:GetScale()
end

local function invoke_pos_change_listeners(el)
	local t = el:GetProperty("transform")
	if(t == nil) then return end
	t:GetPositionAttr():InvokeChangeListeners()

	for name,child in pairs(el) do
		invoke_pos_change_listeners(child)
	end
end

local function invoke_rot_change_listeners(el)
	local t = el:GetProperty("transform")
	if(t == nil) then return end
	t:GetRotationAttr():InvokeChangeListeners()

	for name,child in pairs(el) do
		invoke_rot_change_listeners(child)
	end
end

local function invoke_scale_change_listeners(el)
	local t = el:GetProperty("transform")
	if(t == nil) then return end
	t:GetScaleAttr():InvokeChangeListeners()

	for name,child in pairs(el) do
		invoke_scale_change_listeners(child)
	end
end

function fudm.Transform:Initialize()
	fudm.BaseElement.Initialize(self)
	-- Note: Whenever the position and rotation of this element changes, it will also affect the transforms that
	-- lie below this transform in the hierarchy. That's why we'll make sure to invoke the change listeners for
	-- all of those transforms as well.
	self:GetPositionAttr():AddChangeListener(function(newValue)
		for name,child in pairs(self:GetChildren()) do
			if(child:IsElement()) then
				invoke_pos_change_listeners(child)
			end
		end
	end)
	self:GetRotationAttr():AddChangeListener(function(newValue)
		for name,child in pairs(self:GetChildren()) do
			if(child:IsElement()) then
				invoke_rot_change_listeners(child)
			end
		end
	end)
	self:GetScaleAttr():AddChangeListener(function(newValue)
		for name,child in pairs(self:GetChildren()) do
			if(child:IsElement()) then
				invoke_scale_change_listeners(child)
			end
		end
	end)
end

function fudm.Transform:ApplyTransformGlobal(t)
	local tThis = self:GetPose()
	tThis = t *tThis
	local scale = tThis:GetScale()
	if(type(scale) == "number") then scale = Vector(scale,scale,scale) end
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
	self:SetScale(scale)
end

function fudm.Transform:ApplyTransformLocal(t)
	local tThis = self:GetPose()
	tThis = tThis *t
	local scale = tThis:GetScale()
	if(type(scale) == "number") then scale = Vector(scale,scale,scale) end
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
	self:SetScale(scale)
end

function fudm.Transform:GetPose()
	local scale = self:GetScale()
	if(type(scale) == "number") then scale = Vector(scale,scale,scale) end
	return phys.ScaledTransform(self:GetPosition(),self:GetRotation(),scale)
end

function fudm.Transform:SetPose(pose)
	self:SetPosition(pose:GetOrigin())
	self:SetRotation(pose:GetRotation())
	if(pose.GetScale) then self:SetScale(pose:GetScale()) end
end

local function apply_parent_pose(el,pose,filter)
	local transform = el:GetTransform()
	local parent = (transform.GetOverrideParent ~= nil) and transform:GetOverrideParent() or nil
	-- TODO: Take into account whether overridePos or overrideRot are enabled or not!
	local useOverrideParent = (parent ~= nil)
	if(useOverrideParent == false) then
		parent = el:FindParentElement(filter)
		if(parent ~= nil and parent:GetType() == fudm.ELEMENT_TYPE_PFM_MODEL) then
			parent = parent:FindParentElement(filter) -- If the element is a model component, we'll want to redirect to the parent actor instead.
		end
	end

	if(parent ~= nil and parent.GetTransform ~= nil) then
		local t = parent:GetTransform()
		pose:TransformGlobal(t:GetAbsolutePose(filter))
	end
end

function fudm.Transform:GetAbsolutePose(filter)
	local pose = self:GetPose()
	local parent = self:FindParentElement(filter)
	if(parent == nil) then return pose end
	apply_parent_pose(parent,pose,filter)
	return pose
end
