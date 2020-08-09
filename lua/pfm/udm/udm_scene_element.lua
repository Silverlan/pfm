--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.PFMSceneElement",udm.BaseElement)
function udm.PFMSceneElement:__init(...)
	udm.BaseElement.__init(self,...)
end

function udm.PFMSceneElement:GetSceneParent()
	local el = self:GetProperty("sceneParent")
	if(el ~= nil and el:GetType() == udm.ELEMENT_TYPE_REFERENCE) then el = el:GetTarget() end
	return el
end
function udm.PFMSceneElement:SetSceneParent(parent) self:SetProperty("sceneParent",udm.create_reference(parent)) end

function udm.PFMSceneElement:AddConstraint(constraint)
	local prop = self:GetProperty("constraints")
	if(prop == nil) then
		prop = udm.Array(udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE)
		self:SetProperty("constraints",prop)
	end
	prop:PushBack(constraint)
end
function udm.PFMSceneElement:GetConstraints() return self:GetProperty("constraints") end
function udm.PFMSceneElement:GetSceneChildren() return {} end

function udm.PFMSceneElement:BuildSceneParents(parent)
	local constraints = self:GetProperty("constraints")
	if(constraints ~= nil) then constraints:Clear() end
	for _,parent in ipairs(self:GetParents()) do
		if(parent:GetType() == udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE) then
			self:AddConstraint(parent)
		end
	end
	self:SetSceneParent(parent)
	for _,child in pairs(self:GetSceneChildren()) do
		if(child:GetType() == udm.ELEMENT_TYPE_REFERENCE) then child = child:GetTarget() end
		if(child ~= nil and child.BuildSceneParents) then
			child:BuildSceneParents(self)
		end
	end
end

function udm.PFMSceneElement:GetPose()
	local transform = self:GetProperty("transform")
	if(transform) then return transform:GetPose() end
	return phys.ScaledTransform()
end

function udm.PFMSceneElement:GetAbsolutePose(filter)
	local pose = self:GetPose()
	local sceneParent = self:GetSceneParent()
	if(sceneParent ~= nil and (filter == nil or filter(sceneParent) == true)) then pose = sceneParent:GetAbsolutePose(filter) *pose end
	return pose
end

function udm.PFMSceneElement:GetAbsoluteParentPose(filter)
	local sceneParent = self:GetSceneParent()
	if(sceneParent == nil or (filter ~= nil and filter(sceneParent) ~= true)) then return phys.ScaledTransform() end
	return sceneParent:GetAbsolutePose(filter)
end

function udm.PFMSceneElement:FindSceneParent(filter)
	local parent = self:GetSceneParent()
	if(parent == nil or filter(parent) == true) then return filter end
	while(parent ~= nil and filter(parent) ~= true) do parent = parent:GetSceneParent() end
	return parent
end

function udm.PFMSceneElement:GetConstraintPose()
	return self:GetParentConstraintPose() *self:GetPose()
end

function udm.PFMSceneElement:GetParentConstraintPose()
	local parentPose
	local sceneParent = self:GetSceneParent()
	if(sceneParent ~= nil) then parentPose = sceneParent:GetParentConstraintPose() *sceneParent:GetPose()
	else parentPose = phys.Transform() end

	--[[local constraints = self:GetConstraints()
	if(constraints ~= nil) then
		for _,constraint in ipairs(constraints:GetTable()) do
			constraint:ApplyConstraint(parentPose)
		end
	end]]
	return parentPose
end
