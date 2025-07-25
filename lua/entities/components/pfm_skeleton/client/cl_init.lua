-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include_component("debug_skeleton_draw")

util.register_class("ents.PFMSkeleton", BaseEntityComponent)

function ents.PFMSkeleton:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_bones = {}
	self.m_clickCallbacks = {}
	self.m_bonesInitialized = false
	self:BindEvent(ents.DebugSkeletonDraw.EVENT_ON_BONES_CREATED, "OnBonesCreated")
	self:AddEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)

	self.m_pmCallbacks = {}
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		table.insert(
			self.m_pmCallbacks,
			pm:AddCallback("OnActorPropertySelected", function(fm, udmComponent, item, path, selected)
				self:OnActorPropertySelected(udmComponent, item, path, selected)
			end)
		)

		table.insert(
			self.m_pmCallbacks,
			pm:AddCallback("OnManipulatorModeChanged", function(fm, manipMode)
				self:OnManipulatorModeChanged(manipMode)
			end)
		)
	end
end

function ents.PFMSkeleton:GetManipulatorMode()
	local pm = tool.get_filmmaker()
	local vp = util.is_valid(pm) and pm:GetViewport() or nil
	if util.is_valid(vp) == false then
		return
	end
	return vp:GetManipulatorMode()
end

function ents.PFMSkeleton:IsIkControlManipulatorMode(manipMode)
	return manipMode == gui.PFMCoreViewportBase.MANIPULATOR_MODE_MOVE
		or manipMode == gui.PFMCoreViewportBase.MANIPULATOR_MODE_ROTATE
end

function ents.PFMSkeleton:OnManipulatorModeChanged(manipMode)
	if self:IsIkControlManipulatorMode(manipMode) == false then
		self:ClearIkControls()
	else
		self:InitializeIkControls()
	end
end

function ents.PFMSkeleton:OnActorPropertySelected(udmComponent, item, path, selected)
	local actor = udmComponent:GetActor()
	if actor:IsValid() == false or tostring(actor:GetUniqueId()) ~= tostring(self:GetEntity():GetUuid()) then
		return
	end
	local type = udmComponent:GetType()
	if type ~= "animated" and type ~= "ik_solver" then
		return
	end
	local t = string.split(path, "/")
	if t[1] ~= "bone" and t[1] ~= "control" then
		return
	end
	local mdl = self:GetEntity():GetModel()
	if mdl == nil then
		return
	end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(t[2])
	if boneId == -1 or self.m_bones[boneId] == nil then
		return
	end
	for childBoneId, ent in pairs(self.m_bones[boneId]) do
		if ent:IsValid() then
			local boneC = ent:GetComponent(ents.COMPONENT_PFM_BONE)
			if boneC ~= nil then
				boneC:SetSelected(selected)
				boneC:SetPersistent(selected)
			end
		end
	end

	if util.is_valid(self.m_ikControls[boneId]) then
		local ikControlC = self.m_ikControls[boneId]:GetComponent(ents.COMPONENT_PFM_IK_CONTROL)
		if ikControlC ~= nil then
			ikControlC:SetSelected(selected)
		end
	end
end

function ents.PFMSkeleton:OnRemove()
	util.remove(self.m_pmCallbacks)
	util.remove(self.onControlStrengthChanged)
	self:ClearCallbacks()
	self:ClearIkControls()
	self:GetEntity():RemoveComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
end

function ents.PFMSkeleton:ClearCallbacks()
	for boneId, ent in pairs(self.m_clickCallbacks) do
		util.remove(ent)
	end
	self.m_clickCallbacks = {}
end

function ents.PFMSkeleton:ClearIkControls()
	if self.m_ikControls == nil then
		return
	end
	for boneId, entCtrl in pairs(self.m_ikControls) do
		util.remove(entCtrl)
	end
	self.m_ikControls = {}
end

function ents.PFMSkeleton:OnBoneClicked(boneId, ent) end

function ents.PFMSkeleton:OnControlStrengthChanged(boneId, strength)
	self:UpdateIkControl(boneId)
end

function ents.PFMSkeleton:UpdateBoneColor(boneId, handle)
	local c = self:GetEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
	if c == nil then
		return
	end
	local col = Color.White
	if handle ~= nil then
		col = (handle.type == util.IkRigConfig.Control.TYPE_STATE) and Color.Crimson or Color.Orange
	end
	local tEnts = c:GetBoneEntities(boneId)
	for _, ent in ipairs(tEnts) do
		if ent:IsValid() then
			ent:SetColor(col)
		end
	end
end

function ents.PFMSkeleton:UpdateIkControl(boneId)
	local solverC = self:GetEntity():GetComponent(ents.COMPONENT_IK_SOLVER)
	if solverC == nil then
		return
	end
	local handle = solverC:GetControl(boneId)
	if handle == nil or handle:IsEnabled() == false then
		if util.is_valid(self.m_ikControls[boneId]) then
			util.remove(self.m_ikControls[boneId])
			self.m_ikControls[boneId] = nil

			self:UpdateBoneColor(boneId)
		end
		return
	end

	if util.is_valid(self.m_ikControls[boneId]) then
		return
	end

	local entControl = self:GetEntity():CreateChild("entity")
	self.m_ikControls[boneId] = entControl
	local c = entControl:AddComponent("pfm_ik_control")
	entControl:Spawn()
	c:SetIkControl(solverC, boneId)

	self:UpdateBoneColor(boneId, handle)
end

function ents.PFMSkeleton:InitializeIkControls()
	if self.m_bonesInitialized == false then
		return
	end
	local c = self:GetEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
	if c == nil then
		return
	end
	local solverC = self:GetEntity():GetComponent(ents.COMPONENT_IK_SOLVER)
	if solverC == nil then
		return
	end
	util.remove(self.onControlStrengthChanged)
	self.onControlStrengthChanged = solverC:AddEventCallback(
		ents.IkSolverComponent.EVENT_ON_CONTROL_STRENGTH_CHANGED,
		function(boneId, strength)
			self:OnControlStrengthChanged(boneId, strength)
		end
	)
	for boneId, tEnts in pairs(c:GetBones()) do
		for boneIdChild, ent in pairs(tEnts) do
			if ent:IsValid() then
				self:UpdateIkControl(boneId)
			end
		end
	end
end

function ents.PFMSkeleton:OnBonesCreated()
	local c = self:GetEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
	if c == nil then
		return
	end
	self:ClearCallbacks()
	self:ClearIkControls()
	self.m_bones = {}
	self.m_ikControls = {}
	for boneId, tEnts in pairs(c:GetBones()) do
		for boneIdChild, ent in pairs(tEnts) do
			if ent:IsValid() then
				self.m_bones[boneId] = self.m_bones[boneId] or {}
				self.m_bones[boneId][boneIdChild] = ent

				local boneC = ent:AddComponent("pfm_bone")
				boneC:SetBoneId(boneId)

				local enableBvh = false -- Disabled due to performance issues
				if enableBvh then
					ent:AddComponent(ents.COMPONENT_BVH)
					local clickC = ent:AddComponent(ents.COMPONENT_CLICK)
					util.remove(self.m_clickCallbacks[boneId])
					self.m_clickCallbacks[boneId] = clickC:AddEventCallback(
						ents.ClickComponent.EVENT_ON_CLICK,
						function()
							if ent:IsValid() then
								self:OnBoneClicked(boneId, ent)
							end
						end
					)
				end
			end
		end
	end
	self.m_bonesInitialized = true
	if self:IsIkControlManipulatorMode(self:GetManipulatorMode()) then
		self:InitializeIkControls()
	end
end
ents.register_component("pfm_skeleton", ents.PFMSkeleton, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
