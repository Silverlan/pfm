--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_TRANSFORM = udm.register_element("Transform")
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"position",udm.Vector3(Vector()))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"rotation",udm.Quaternion(Quaternion()))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"scale",udm.Vector3(Vector(1.0,1.0,1.0)))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"overrideParent",udm.ELEMENT_TYPE_ANY)
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"overridePos",udm.Bool(false))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"overrideRot",udm.Bool(false))

function udm.Transform:__eq(other)
	print(util.get_type_name(self),util.get_type_name(other))
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

function udm.Transform:Initialize()
	udm.BaseElement.Initialize(self)
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

function udm.Transform:ApplyTransformGlobal(t)
	local tThis = self:GetPose()
	tThis = t *tThis
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
	self:SetScale(tThis:GetScale())
end

function udm.Transform:ApplyTransformLocal(t)
	local tThis = self:GetPose()
	tThis = tThis *t
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
	self:SetScale(tThis:GetScale())
end

function udm.Transform:GetPose()
	return phys.ScaledTransform(self:GetPosition(),self:GetRotation(),self:GetScale())
end

function udm.Transform:SetPose(pose)
	self:SetPosition(pose:GetOrigin())
	self:SetRotation(pose:GetRotation())
	self:SetScale(pose:GetScale())
end

local function apply_parent_pose(el,pose)
	local transform = el:GetTransform()
	local parent = (transform.GetOverrideParent ~= nil) and transform:GetOverrideParent() or nil
	-- TODO: Take into account whether overridePos or overrideRot are enabled or not!
	local useOverrideParent = (parent ~= nil)
	if(useOverrideParent == false) then
		parent = el:FindParentElement()
		if(parent ~= nil and parent:GetType() == udm.ELEMENT_TYPE_PFM_MODEL) then
			parent = parent:FindParentElement() -- If the element is a model component, we'll want to redirect to the parent actor instead.
		end
	end

	if(parent ~= nil and parent.GetTransform ~= nil) then
		local t = parent:GetTransform()
		pose:TransformGlobal(t:GetAbsolutePose())
	end
end

function udm.Transform:GetAbsolutePose()
	local pose = self:GetPose()
	local parent = self:FindParentElement()
	if(parent == nil) then return pose end
	apply_parent_pose(parent,pose)
	return pose
end
