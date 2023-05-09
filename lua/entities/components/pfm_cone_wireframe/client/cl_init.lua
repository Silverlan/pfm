--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_wireframe_line.lua")

local Component = util.register_class("ents.PFMConeWireframe", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent("pfm_overlay_object")

	self.m_listeners = {}
end
function Component:OnRemove()
	util.remove(self.m_listeners)
end
function Component:InitializeModel()
	if self.m_coneModel ~= nil then
		return self.m_coneModel
	end
	-- Generate model
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local subMesh = game.Model.Mesh.Sub.create()
	subMesh:SetGeometryType(game.Model.Mesh.Sub.GEOMETRY_TYPE_LINES)

	local mat = game.create_material("pfm_wireframe_line")
	mat:SetTexture("albedo_map", "white")
	mat:UpdateTextures()
	mat:InitializeShaderDescriptorSet()
	mat:SetLoaded(true)
	local matIdx = mdl:AddMaterial(0, mat)
	subMesh:SetSkinTextureIndex(matIdx)

	local mesh = game.Model.Mesh.Create()
	mesh:AddSubMesh(subMesh)
	meshGroup:AddMesh(mesh)

	self.m_coneModel = mdl
	self:UpdateModel()
	mdl:Update(game.Model.FUPDATE_ALL)
	self:SetConeModelDirty()
	return mdl
end
function Component:UpdateModel(updateBuffers)
	if self.m_coneModel == nil then
		return
	end
	if updateBuffers == nil then
		updateBuffers = true
	end
	local meshGroup = self.m_coneModel:GetMeshGroup(0) or nil
	local mesh = (meshGroup ~= nil) and meshGroup:GetMesh(0) or nil
	local subMesh = (mesh ~= nil) and mesh:GetSubMesh(0) or nil
	if subMesh == nil then
		return
	end

	local radiusC = self:GetEntity():GetComponent(ents.COMPONENT_RADIUS)
	local radius = (radiusC ~= nil) and radiusC:GetRadius() or 100.0

	local lightSpotC = self:GetEntity():GetComponent(ents.COMPONENT_LIGHT_SPOT)
	local coneAngle = (lightSpotC ~= nil) and lightSpotC:GetOuterConeAngle() or 45.0

	local startPos = Vector()
	local dir = Vector(0, 0, 1)
	local endPos = dir * radius
	local segStartRadius = 0.0
	local segEndRadius = radius * math.tan(math.rad(coneAngle / 2.0))
	local coneDetail = 8
	local verts, tris, normals = geometry.generate_truncated_cone_mesh(
		startPos,
		segStartRadius,
		dir,
		startPos:Distance(endPos),
		segEndRadius,
		coneDetail,
		false,
		true,
		true
	)
	if subMesh:GetIndexCount() == 0 then
		-- First time initialization
		for i = 1, #tris, 3 do
			subMesh:AddLine(tris[i], tris[i + 1])
			subMesh:AddLine(tris[i + 1], tris[i + 2])
		end
		for i = 1, #verts do
			local v = game.Model.Vertex(Vector(), Vector2(0, 0), Vector(0, 0, 0))
			subMesh:AddVertex(v)
		end
	end

	for idx = 1, #verts do
		subMesh:SetVertexPosition(idx - 1, verts[idx])
	end

	if updateBuffers then
		subMesh:Update(game.Model.FUPDATE_VERTEX_BUFFER)
	end
end
function Component:SetConeModelVisible(visible)
	if visible then
		self:GetEntity():AddComponent(ents.COMPONENT_RENDER)
	end

	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if renderC ~= nil then
		renderC:SetSceneRenderPass(visible and game.SCENE_RENDER_PASS_WORLD or game.SCENE_RENDER_PASS_NONE)
	end

	if visible == false then
		return
	end
	self:SetConeModelDirty()

	local mdlC = self:GetEntity():AddComponent(ents.COMPONENT_MODEL)
	if mdlC == nil or mdlC:GetModel() ~= nil then
		return
	end
	local model = self:InitializeModel()
	if model == nil then
		return
	end
	mdlC:SetModel(model)
end
function Component:UpdateRenderData()
	if self.m_updateFrustumModel ~= true then
		return
	end
	self.m_updateFrustumModel = nil
	self:UpdateModel()
	local mdl = self:GetEntity():GetModel()
	if mdl ~= nil then
		mdl:Update(game.Model.FUPDATE_BOUNDS)
	end
end
function Component:SetConeModelDirty()
	self.m_updateFrustumModel = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnTick(dt)
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	self:UpdateRenderData()
	pfm.tag_render_scene_as_dirty()
end
ents.COMPONENT_PFM_CONE_WIREFRAME = ents.register_component("pfm_cone_wireframe", Component)
