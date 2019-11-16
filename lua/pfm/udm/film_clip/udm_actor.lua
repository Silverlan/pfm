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
end

local function apply_parent_pose(el,pose)
	-- TODO: We need to apply the pose of the parent Dag (group) elements, up to the
	-- scene of the film clip. An element may belong to multiple groups though, so
	-- the code below may not work correctly in all cases.
	for _,parent in ipairs(el:GetParents()) do
		if(parent:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then
			local t = parent:GetTransform()
			pose:TransformGlobal(t:GetPose())
			apply_parent_pose(parent,pose)
			break
		end
	end
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
