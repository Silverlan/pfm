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
		mdlC:SetMaterialOverride(0, matName)
		mdlC:UpdateRenderMeshes()

		self.m_usingCustomMaterial = false
		return
	end
	self.m_customMaterial = (self.m_customMaterial ~= nil) and self.m_customMaterial or game.create_material("volume")
	local data = self.m_customMaterial:GetDataBlock()
	local strType = (self:GetType() == Component.TYPE_HOMOGENEOUS) and "homogeneous" or "heterogeneous"
	local volData = data:AddBlock("volumetric")
	volData:SetValue("string", "type", strType)
	volData:SetValue("vector", "absorption", tostring(self:GetAbsorption()))
	volData:SetValue("vector", "scattering_factor", tostring(self:GetScatteringFactor()))
	volData:SetValue("vector", "asymmetry_factor", tostring(self:GetAsymmetryFactor()))
	volData:SetValue("bool", "multiscattering", tostring(self:GetMultiScattering()))

	local color = self:GetEntity():GetColor()
	volData:SetValue("vector", "color", tostring(color:ToVector()))
	volData:SetValue("float", "density", tostring(self:GetDensity()))
	volData:SetValue("float", "anisotropy", tostring(self:GetAnisotropy()))
	volData:SetValue("vector", "absorption_color", tostring(self:GetAbsorptionColor()))
	volData:SetValue("float", "emission_strength", tostring(self:GetEmissionStrength()))
	volData:SetValue("vector", "emission_color", tostring(self:GetEmissionColor()))
	volData:SetValue("float", "blackbody_intensity", tostring(self:GetBlackbodyIntensity()))
	volData:SetValue("vector", "blackbody_tint", tostring(self:GetBlackbodyTint()))
	volData:SetValue("float", "temperature", tostring(self:GetTemperature()))

	self.m_customMaterial:SetLoaded(true)
	if self.m_usingCustomMaterial == true then
		return
	end
	self.m_usingCustomMaterial = true
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	mdlC:SetMaterialOverride(0, self.m_customMaterial)
	mdlC:UpdateRenderMeshes()
end
function Component:OnEntitySpawn()
	self:UpdateMaterial()
end
ents.COMPONENT_PFM_VOLUMETRIC = ents.register_component("pfm_volumetric", Component)
