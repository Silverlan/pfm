--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVolumetric", BaseEntityComponent)

Component.TYPE_HOMOGENEOUS = 0
Component.TYPE_HETEROGENEOUS = 1

local function update_material(c)
	c:UpdateMaterial()
end
Component:RegisterMember("MaterialName", udm.TYPE_STRING, "", {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = update_material,
	metaData = {
		rootPath = "materials/",
		initialPath = "volumes",
		extensions = asset.get_supported_extensions(asset.TYPE_MATERIAL),
		stripExtension = true,
	},
})
Component:RegisterMember("Density", udm.TYPE_FLOAT, 0.1, {
	onChange = update_material,
	min = 0.0,
	max = 1.0,
})
Component:RegisterMember("Anisotropy", udm.TYPE_FLOAT, 0.0, {
	onChange = update_material,
	min = 0.0,
	max = 1.0,
})
Component:RegisterMember("AbsorptionColor", udm.TYPE_VECTOR3, Color.Black:ToVector(), {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR,
	onChange = update_material,
})
Component:RegisterMember("EmissionStrength", udm.TYPE_FLOAT, 0.0, {
	onChange = update_material,
	min = 0.0,
	max = 1.0,
})
Component:RegisterMember("EmissionColor", udm.TYPE_VECTOR3, Color.Black:ToVector(), {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR,
	onChange = update_material,
})
Component:RegisterMember("BlackbodyIntensity", udm.TYPE_FLOAT, 0.0, {
	onChange = update_material,
	min = 0.0,
	max = 1.0,
})
Component:RegisterMember("BlackbodyTint", udm.TYPE_VECTOR3, Color.Black:ToVector(), {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR,
	onChange = update_material,
})
Component:RegisterMember("Temperature", udm.TYPE_FLOAT, 1000.0, {
	onChange = update_material,
	min = 0.0,
	max = 10000.0,
})

Component:RegisterMember("Type", udm.TYPE_UINT32, Component.TYPE_HOMOGENEOUS, {
	enumValues = {
		["Homogeneous"] = Component.TYPE_HOMOGENEOUS,
		["Heterogeneous"] = Component.TYPE_HETEROGENEOUS,
	},
})
Component:RegisterMember("Absorption", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = update_material,
})
Component:RegisterMember("ScatteringFactor", udm.TYPE_VECTOR3, Vector(0.01, 0.01, 0.01), {
	onChange = update_material,
})
Component:RegisterMember("AsymmetryFactor", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = update_material,
})
Component:RegisterMember("MultiScattering", udm.TYPE_BOOLEAN, false, {
	onChange = update_material,
})
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local colorC = self:AddEntityComponent(ents.COMPONENT_COLOR)
	self:AddEntityComponent("pfm_cuboid_bounds")

	self:BindEvent(ents.PFMCuboidBounds.EVENT_ON_BOUNDS_CHANGED, "OnBoundsChanged")
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED, "OnModelChanged")

	colorC:SetColor(Color(Vector(0.5, 0.5, 0.5)))
	self.m_usingCustomMaterial = nil
end

function Component:OnBoundsChanged(min, max)
	if self.m_cubeModel == false then
		return
	end
	local center = (min + max) / 2.0
	min = min - center
	max = max - center
	local extents = (max - min) / 2.0

	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	if actor == nil then
		return
	end
	local pose = math.ScaledTransform()
	pose:SetOrigin(center)
	pose:SetScale(extents)
	actor:SetTransform(pose)
	self:GetEntity():SetPose(pose)
end

function Component:OnModelChanged()
	local mdl = self:GetEntity():GetModelName()
	self.m_cubeModel = (mdl == "cube")
	self.m_usingCustomMaterial = nil

	if self.m_cubeModel == false then
		self:GetEntity():SetScale(Vector(1, 1, 1))
	end
	self:UpdateMaterial()
end

function Component:UpdateMaterial()
	local matName = self:GetMaterialName()
	if #matName > 0 then
		local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
		if mdlC == nil then
			return
		end
		local matOverrideC = self:GetEntity():GetComponent(ents.COMPONENT_MATERIAL_OVERRIDE)
		if matOverrideC ~= nil then
			matOverrideC:SetMaterialOverride(0, matName)
		end
		mdlC:UpdateRenderMeshes()

		self.m_usingCustomMaterial = false
		return
	end
	self.m_customMaterial = (self.m_customMaterial ~= nil) and self.m_customMaterial or game.create_material("volume")
	local mat = self.m_customMaterial
	local strType = (self:GetType() == Component.TYPE_HOMOGENEOUS) and "homogeneous" or "heterogeneous"
	mat:SetPropertyByPath("volumetric/type", udm.TYPE_STRING, strType)
	mat:SetPropertyByPath("volumetric/absorption", udm.TYPE_VECTOR3, self:GetAbsorption())
	mat:SetPropertyByPath("volumetric/scattering_factor", udm.TYPE_VECTOR3, self:GetScatteringFactor())
	mat:SetPropertyByPath("volumetric/asymmetry_factor", udm.TYPE_VECTOR3, self:GetAsymmetryFactor())
	mat:SetPropertyByPath("volumetric/multiscattering", udm.TYPE_BOOLEAN, self:GetMultiScattering())
	mat:SetPropertyByPath("volumetric/color", udm.TYPE_VECTOR3, self:GetEntity():GetColor():ToVector())
	mat:SetPropertyByPath("volumetric/density", udm.TYPE_FLOAT, self:GetDensity())
	mat:SetPropertyByPath("volumetric/anisotropy", udm.TYPE_FLOAT, self:GetAnisotropy())
	mat:SetPropertyByPath("volumetric/absorption_color", udm.TYPE_VECTOR3, self:GetAbsorptionColor())
	mat:SetPropertyByPath("volumetric/emission_strength", udm.TYPE_FLOAT, self:GetEmissionStrength())
	mat:SetPropertyByPath("volumetric/emission_color", udm.TYPE_VECTOR3, self:GetEmissionColor())
	mat:SetPropertyByPath("volumetric/blackbody_intensity", udm.TYPE_FLOAT, self:GetBlackbodyIntensity())
	mat:SetPropertyByPath("volumetric/blackbody_tint", udm.TYPE_VECTOR3, self:GetBlackbodyTint())
	mat:SetPropertyByPath("volumetric/temperature", udm.TYPE_FLOAT, self:GetTemperature())

	self.m_customMaterial:SetLoaded(true)
	if self.m_usingCustomMaterial == true then
		return
	end
	self.m_usingCustomMaterial = true
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	local matOverrideC = self:GetEntity():GetComponent(ents.COMPONENT_MATERIAL_OVERRIDE)
	if matOverrideC ~= nil then
		matOverrideC:SetMaterialOverride(0, self.m_customMaterial)
	end
	mdlC:UpdateRenderMeshes()
end
function Component:OnEntitySpawn()
	self:UpdateMaterial()
end
ents.register_component("pfm_volumetric", Component, "rendering/lighting")
