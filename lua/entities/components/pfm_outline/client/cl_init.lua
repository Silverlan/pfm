--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMOutline", BaseEntityComponent)

Component:RegisterMember("OutlineColor", udm.TYPE_VECTOR3, Color.White:ToVector(), {
	onChange = function(self)
		self:UpdateSettings()
	end,
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR,
})
Component:RegisterMember("OutlineWidth", udm.TYPE_FLOAT, 0.004, {
	onChange = function(self)
		self:UpdateSettings()
	end,
	min = 0.0,
	max = 0.01,
})
Component:RegisterMember("GlowFactor", udm.TYPE_FLOAT, 0.0, {
	onChange = function(self)
		self:UpdateSettings()
	end,
	min = 0.0,
	max = 4.0,
})
Component:RegisterMember("ScaleByDistance", udm.TYPE_BOOLEAN, false, {
	onChange = function(self)
		self:UpdateSettings()
	end,
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_material = game.create_material("pfm_selection_outline")
	self:UpdateSettings()
end
function Component:OnEntitySpawn()
	self:UpdateWireframe()

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	self.m_onRenderMeshesUpdated = mdlC:AddEventCallback(
		ents.ModelComponent.EVENT_ON_RENDER_MESHES_UPDATED,
		function(mdl)
			self:UpdateWireframe()
		end
	)
end
function Component:OnRemove()
	util.remove({ self.m_material, self.m_onRenderMeshesUpdated })

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	mdlC:SetRenderMeshesDirty()
	mdlC:UpdateRenderMeshes()
end
function Component:UpdateSettings()
	local mat = self.m_material
	local db = mat:GetDataBlock()
	db:SetValue("float", "outline_width", tostring(self:GetOutlineWidth()))
	db:SetValue("vector", "color_factor", tostring(self:GetOutlineColor()))
	db:SetValue("float", "glow_factor", tostring(self:GetGlowFactor()))
	db:SetValue("float", "scale_by_distance_factor", self:GetScaleByDistance() and "1" or "0")
	mat:UpdateTextures()
	mat:InitializeShaderDescriptorSet()
	mat:SetLoaded(true)
end
function Component:UpdateWireframe()
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	local mat = self.m_material
	if util.is_valid(mat) == false then
		return
	end
	local renderMeshes = mdlC:GetRenderMeshes()
	for _, mesh in ipairs(renderMeshes) do
		if mesh:GetGeometryType() == game.Model.Mesh.Sub.GEOMETRY_TYPE_TRIANGLES then
			mdlC:AddRenderMesh(mesh, mat, false)
		end
	end
end
ents.COMPONENT_PFM_OUTLINE = ents.register_component("pfm_outline", Component)
