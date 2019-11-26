--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("actor/components")

udm.ELEMENT_TYPE_PFM_ACTOR = udm.register_element("PFMActor")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"components",udm.Array(udm.ELEMENT_TYPE_ANY))

function udm.PFMActor:AddComponent(pfmComponent)
	self:GetComponentsAttr():PushBack(pfmComponent)
	self:AddChild(pfmComponent)
end

local function apply_parent_pose(el,pose)
	local poseParent = phys.ScaledTransform()
	local parent = (el.GetOverrideParent ~= nil) and el:GetOverrideParent() or nil
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
		poseParent:TransformGlobal(t:GetPose())

		-- TODO: Obsolete? Remove this line!
		-- if(useOverrideParent) then parent = t end -- If we're using an override parent, we'll want to use the transform as base for going up in the hierarchy
		apply_parent_pose(parent,poseParent)
	end

	pose:TransformGlobal(poseParent)
	return pose
end

function udm.PFMActor:GetAbsolutePose()
	local t = self:GetTransform()
	local pose = t:GetPose()
	apply_parent_pose(self,pose)
	return pose
end

function udm.PFMActor:GetPose()
	return self:GetTransform():GetPose()
end
