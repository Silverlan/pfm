--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_TRANSFORM = udm.register_element("Transform")
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"position",udm.Vector3(Vector()))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"rotation",udm.Quaternion(Quaternion()))

function udm.Transform:__eq(other)
	print(util.get_type_name(self),util.get_type_name(other))
	return self:GetPosition() == other:GetPosition() and self:GetRotation() == other:GetRotation()
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

function udm.Transform:Initialize()
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
end

function udm.Transform:ApplyTransformGlobal(t)
	local tThis = self:GetPose()
	tThis = t *tThis
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
end

function udm.Transform:ApplyTransformLocal(t)
	local tThis = self:GetPose()
	tThis = tThis *t
	self:SetPosition(tThis:GetOrigin())
	self:SetRotation(tThis:GetRotation())
end

function udm.Transform:GetPose()
	return phys.Transform(self:GetPosition(),self:GetRotation())
end
