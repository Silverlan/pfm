--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMGlobalShaderOverride", BaseEntityComponent)
Component:RegisterMember("ApplyToMap", udm.TYPE_BOOLEAN, false, {
	onChange = function(self)
		self:Reapply()
	end,
}, bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_entities = {}
	self.m_materialCache = {}
	self.m_newMaterials = {}

	self:AddEntityComponent("child")
	self:BindEvent(ents.ChildComponent.EVENT_ON_PARENT_CHANGED, "Reapply")
end
function Component:OnRemove()
	self:Reset()
	util.remove(self.m_onMovedListener)
end
function Component:Reset()
	for _, ent in ipairs(self.m_entities) do
		local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
		if mdlC ~= nil then
			local n = mdlC:GetMaterialOverrideCount()
			for i = n - 1, 0, -1 do
				local matOverride = mdlC:GetMaterialOverride(i)
				if matOverride ~= nil and self.m_newMaterials[matOverride:GetIndex()] ~= nil then
					mdlC:ClearMaterialOverride(i)
				end
			end
			mdlC:UpdateRenderMeshes()
		end
	end
	self.m_entities = {}
	self.m_materialCache = {}
	self.m_newMaterials = {}
	asset.clear_unused(asset.TYPE_MATERIAL)
end
function Component:ApplyToEntity(ent)
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	local targetShader = "bw"
	local mdl = ent:GetModel()
	local n = #mdl:GetTextureGroup(0)
	local matOverrides = {}
	for matIdx = 0, n - 1 do
		local mat = mdlC:GetRenderMaterial(matIdx)
		if mat ~= nil then
			local name = mat:GetName()
			if #name > 0 and mat:GetShaderName() ~= targetShader then
				local newMat = self.m_materialCache[name]
				if newMat == nil then
					newMat = mat:Copy()
					newMat:SetShader(targetShader)
					self.m_materialCache[name] = newMat
					self.m_newMaterials[newMat:GetIndex()] = true
				end
				matOverrides[name] = newMat
			end
		end
	end
	for name, newMat in pairs(matOverrides) do
		mdlC:SetMaterialOverride(name, newMat)
	end
	mdlC:UpdateRenderMeshes()
	table.insert(self.m_entities, ent)
end
function Component:Apply()
	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		local actor = actorC:GetActorData()
		local parent = actor:GetParent()
		local actors = (parent ~= nil) and parent:GetActorList() or {}
		for _, actor in ipairs(actors) do
			local ent = actor:FindEntity()
			if util.is_valid(ent) then
				self:ApplyToEntity(ent)
			end
		end
	end

	local applyToMap = self:GetApplyToMap()
	if applyToMap then
		for ent, c in ents.citerator(ents.COMPONENT_MAP) do
			self:ApplyToEntity(ent)
		end
	end
end
function Component:Reapply()
	self:Reset()
	self:Apply()
end
function Component:OnEntitySpawn()
	self:Apply()
	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		local actor = actorC:GetActorData()
		self.m_onMovedListener = actor:AddChangeListener("OnMoved", function(actor, oldGroup, newGroup)
			self:Reapply()
		end)
	end
end
ents.register_component("pfm_global_shader_override", Component, "pfm")
