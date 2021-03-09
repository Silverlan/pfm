--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("fudm.PFMSceneElement",fudm.BaseElement)
function fudm.PFMSceneElement:__init(...)
	fudm.BaseElement.__init(self,...)
end

function fudm.PFMSceneElement:GetSceneParent()
	local el = self:GetProperty("sceneParent")
	if(el ~= nil and el:GetType() == fudm.ELEMENT_TYPE_REFERENCE) then el = el:GetTarget() end
	return el
end
function fudm.PFMSceneElement:SetSceneParent(parent) self:SetProperty("sceneParent",fudm.create_reference(parent)) end

function fudm.PFMSceneElement:AddConstraint(constraint)
	local prop = self:GetProperty("constraints")
	if(prop == nil) then
		prop = fudm.Array(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE)
		self:SetProperty("constraints",prop)
	end
	prop:PushBack(constraint)
end
function fudm.PFMSceneElement:GetConstraints() return self:GetProperty("constraints") end
function fudm.PFMSceneElement:GetSceneChildren() return {} end

function fudm.PFMSceneElement:BuildSceneParents(parent)
	local constraints = self:GetProperty("constraints")
	if(constraints ~= nil) then constraints:Clear() end
	for _,parent in ipairs(self:GetParents()) do
		if(parent:GetType() == fudm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE) then
			self:AddConstraint(parent)
		end
	end
	self:SetSceneParent(parent)
	for _,child in pairs(self:GetSceneChildren()) do
		if(child:GetType() == fudm.ELEMENT_TYPE_REFERENCE) then child = child:GetTarget() end
		if(child ~= nil and child.BuildSceneParents) then
			child:BuildSceneParents(self)
		end
	end
end

function fudm.PFMSceneElement:GetPose()
	local transform = self:GetProperty("transform")
	if(transform) then return transform:GetPose() end
	return phys.ScaledTransform()
end

function fudm.PFMSceneElement:GetAbsolutePose(filter)
	local pose = self:GetPose()
	local sceneParent = self:GetSceneParent()
	if(sceneParent ~= nil and (filter == nil or filter(sceneParent) == true)) then pose = sceneParent:GetAbsolutePose(filter) *pose end
	return pose
end

function fudm.PFMSceneElement:GetAbsoluteParentPose(filter)
	local sceneParent = self:GetSceneParent()
	if(sceneParent == nil or (filter ~= nil and filter(sceneParent) ~= true)) then return phys.ScaledTransform() end
	return sceneParent:GetAbsolutePose(filter)
end

function fudm.PFMSceneElement:FindSceneParent(filter)
	local parent = self:GetSceneParent()
	if(parent == nil or filter(parent) == true) then return filter end
	while(parent ~= nil and filter(parent) ~= true) do parent = parent:GetSceneParent() end
	return parent
end

function fudm.PFMSceneElement:GetConstraintPose()
	return self:GetParentConstraintPose() *self:GetPose()
end

function fudm.PFMSceneElement:GetParentConstraintPose()
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
