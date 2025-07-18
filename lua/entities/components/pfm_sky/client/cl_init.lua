-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMSky", BaseEntityComponent)

local Component = ents.PFMSky
Component:RegisterMember("Strength", udm.TYPE_FLOAT, 0.3, {
	min = 0.0,
	max = 10.0,
})
Component:RegisterMember("Transparent", udm.TYPE_BOOLEAN, false)
Component:RegisterMember("SkyTexture", udm.TYPE_STRING, "skies/dusk379.hdr", {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:UpdateSkyTexture()
	end,
	metaData = {
		rootPath = "materials/skies/",
		basePath = "skies/",
		extensions = { "hdr", "png" },
		stripExtension = true,
	},
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.TransformComponent.EVENT_ON_POSE_CHANGED, "OnPoseChanged")

	self.m_callbacks = {}
	table.insert(
		self.m_callbacks,
		ents.add_component_creation_listener("unirender", function(c)
			table.insert(
				self.m_callbacks,
				c:AddEventCallback(ents.UnirenderComponent.EVENT_INITIALIZE_SCENE, function(scene, renderSettings)
					self:ApplySceneSkySettings(scene)
				end)
			)
		end)
	)

	self:BindEvent(ents.MaterialOverrideComponent.EVENT_ON_MATERIAL_OVERRIDES_CLEARED, "UpdateSkyTexture")
end
function Component:ApplySceneSkySettings(scene)
	scene:SetSkyAngles(self:GetEntity():GetAngles())
	scene:SetSkyStrength(self:GetStrength())
	local tex = self:GetSkyTexture()
	if #tex > 0 then
		scene:SetSky(util.FilePath("materials", tex):GetString())
	end
	scene:SetSkyTransparent(self:GetTransparent())
	-- settings:SetSkyYaw(self.m_ctrlSkyYaw:GetValue())
end
function Component:OnPoseChanged()
	local ang = self:GetEntity():GetAngles()
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_SKYBOX) }) do
		ent:GetComponent(ents.COMPONENT_SKYBOX):SetSkyAngles(ang)
	end
end
function Component:OnEntitySpawn()
	self:UpdateSkyTexture()
end
function Component:UpdateSkyTexture(clear)
	if self:GetEntity():IsSpawned() == false then
		return
	end
	local mat
	if clear ~= true then
		local skyTex = self:GetSkyTexture()

		mat = asset.create_material("skybox")
		mat:SetTexture("skybox", skyTex)
		mat:UpdateTextures()
		mat:InitializeShaderDescriptorSet()
		mat:SetLoaded(true)
	end

	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_SKYBOX) }) do
		ent:GetComponent(ents.COMPONENT_SKYBOX):SetSkyMaterial(mat)
	end
end
function Component:OnRemove()
	util.remove(self.m_callbacks)
	self:UpdateSkyTexture(true)
end
ents.register_component("pfm_sky", Component, "rendering")
