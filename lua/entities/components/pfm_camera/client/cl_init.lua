--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_wireframe_line.lua")

local Component = util.register_class("ents.PFMCamera", BaseEntityComponent)

Component.impl = util.get_class_value(Component, "impl")
	or {
		activeCamera = nil,
		cameraEnabled = false,
		vrEnabled = false,
	}
Component.get_active_camera = function()
	return Component.impl.activeCamera
end
Component.is_camera_enabled = function()
	return Component.impl.cameraEnabled
end
Component.set_camera_enabled = function(enabled)
	if enabled then
		pfm.log("Enabling camera...", pfm.LOG_CATEGORY_PFM_GAME)
	else
		pfm.log("Disabling camera...", pfm.LOG_CATEGORY_PFM_GAME)
	end
	Component.impl.cameraEnabled = enabled
	Component.set_active_camera(Component.impl.activeCamera)
end
Component.set_active_camera = function(cam)
	pfm.tag_render_scene_as_dirty()
	if util.is_valid(Component.impl.activeCamera) then
		local toggleC = Component.impl.activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		-- if(toggleC ~= nil) then toggleC:TurnOff() end
		local prevActiveCamera = Component.impl.activeCamera
		Component.impl.activeCamera = nil
	end
	if util.is_valid(cam) == false then
		pfm.log("Setting active camera to: None", pfm.LOG_CATEGORY_PFM_GAME)
		return
	end
	pfm.log("Setting active camera to: " .. cam:GetEntity():GetName(), pfm.LOG_CATEGORY_PFM_GAME)
	Component.impl.activeCamera = cam
	local toggleC = Component.impl.activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	-- if(toggleC ~= nil) then toggleC:SetTurnedOn(Component.impl.cameraEnabled) end
	Component.impl.activeCamera:UpdateVRView()
end
Component.set_vr_view_enabled = function(enabled)
	if enabled then
		pfm.log("Enabling VR view...", pfm.LOG_CATEGORY_PFM_GAME)
	else
		pfm.log("Disabling VR view...", pfm.LOG_CATEGORY_PFM_GAME)
	end
	Component.impl.vrEnabled = enabled
	if util.is_valid(Component.impl.activeCamera) then
		Component.impl.activeCamera:UpdateVRView()
	end
end
Component.is_vr_view_enabled = function()
	return Component.impl.vrEnabled
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local camC = self:AddEntityComponent(ents.COMPONENT_CAMERA)
	local toggleC = self:AddEntityComponent(ents.COMPONENT_TOGGLE)
	self:AddEntityComponent("pfm_actor")
	self:AddEntityComponent("pfm_overlay_object")

	local gameScene = game.get_scene()
	local gameRenderer = util.is_valid(gameScene) and gameScene:GetRenderer() or nil
	if gameRenderer ~= nil then
		camC:SetAspectRatio(gameRenderer:GetWidth() / gameRenderer:GetHeight())
		camC:UpdateProjectionMatrix()
	end

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "OnTurnOff")

	camC:GetFOVProperty():AddCallback(function()
		self:SetFrustumModelDirty()
	end)
	camC:GetNearZProperty():AddCallback(function()
		self:SetFrustumModelDirty()
	end)
	camC:GetFarZProperty():AddCallback(function()
		self:SetFrustumModelDirty()
	end)

	self.m_listeners = {}
end
function Component:OnTurnOn()
	if self.m_frustumModel == nil then
		return
	end
	self:SetFrustumModelVisible(false)
end
function Component:OnTurnOff()
	if self.m_frustumModel == nil then
		return
	end
	self:SetFrustumModelVisible(true)
end
function Component:OnRemove()
	for _, cb in ipairs(self.m_listeners) do
		if cb:IsValid() then
			cb:Remove()
		end
	end
end
function Component:UpdateVRView()
	--[[if Component.is_vr_view_enabled() then
		self:GetEntity():AddComponent("pfm_vr_camera")
	else
		self:GetEntity():RemoveComponent("pfm_vr_camera")
	end]]
end
function Component:UpdateAspectRatio()
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if camC == nil then
		return
	end
	local camData = self:GetCameraData()
	camC:SetAspectRatio(camData:GetActor():FindComponent("camera"):GetMemberValue("aspectRatio"))
	camC:UpdateProjectionMatrix()
end
function Component:GetCameraData()
	return self.m_cameraData
end
local MODEL_VERTEX_COUNT = 32
function Component:InitializeModel()
	if self.m_frustumModel ~= nil then
		return self.m_frustumModel
	end
	-- Generate model
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local subMesh = game.Model.Mesh.Sub.create()
	subMesh:SetGeometryType(game.Model.Mesh.Sub.GEOMETRY_TYPE_LINES)

	local indices = {}
	for i = 1, MODEL_VERTEX_COUNT do
		local v = game.Model.Vertex(Vector(), Vector2(0, 0), Vector(0, 0, 0))
		local idx = subMesh:AddVertex(v)
		table.insert(indices, idx)
	end

	for i = 1, #indices, 2 do
		subMesh:AddLine(indices[i], indices[i + 1])
	end

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

	self.m_frustumModel = mdl
	self:UpdateModel()
	mdl:Update(game.Model.FUPDATE_ALL)
	self:SetFrustumModelDirty()
	return mdl
end
function Component:UpdateModel(updateBuffers)
	if updateBuffers == nil then
		updateBuffers = true
	end
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if camC == nil or self.m_frustumModel == nil then
		return
	end
	local meshGroup = self.m_frustumModel:GetMeshGroup(0) or nil
	local mesh = (meshGroup ~= nil) and meshGroup:GetMesh(0) or nil
	local subMesh = (mesh ~= nil) and mesh:GetSubMesh(0) or nil
	if subMesh == nil then
		return
	end

	local pos = Vector()
	local fov = camC:GetFOVRad()
	local nearPlaneBoundaries =
		math.get_frustum_plane_boundaries(pos, vector.FORWARD, vector.UP, fov, camC:GetAspectRatio(), camC:GetNearZ())
	local farPlaneBoundaries =
		math.get_frustum_plane_boundaries(pos, vector.FORWARD, vector.UP, fov, camC:GetAspectRatio(), camC:GetFarZ())
	local vertIdx = 0

	-- Near plane
	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[1])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[2])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[2])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[3])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[3])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[4])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[4])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, nearPlaneBoundaries[1])
	vertIdx = vertIdx + 1

	-- Far plane
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[1])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[2])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[2])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[3])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[3])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[4])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[4])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[1])
	vertIdx = vertIdx + 1

	-- Cam pos to far plane
	subMesh:SetVertexPosition(vertIdx, pos)
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[1])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, pos)
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[2])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, pos)
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[3])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, pos)
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, farPlaneBoundaries[4])
	vertIdx = vertIdx + 1

	-- Focal distance plane
	local focalDistance = 0 -- self:GetCameraData():GetFocalDistance() -- TODO
	local focalPlaneBoundaries =
		math.get_frustum_plane_boundaries(pos, vector.FORWARD, vector.UP, fov, camC:GetAspectRatio(), focalDistance)

	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[1])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[2])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[2])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[3])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[3])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[4])
	vertIdx = vertIdx + 1

	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[4])
	vertIdx = vertIdx + 1
	subMesh:SetVertexPosition(vertIdx, focalPlaneBoundaries[1])
	vertIdx = vertIdx + 1

	if updateBuffers then
		subMesh:Update(game.Model.FUPDATE_VERTEX_BUFFER)
	end
end
function Component:SetFrustumModelVisible(visible)
	local actorC = self:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil and actorC:IsInEditor() then
		-- Don't display wireframe model if we're not in the editor
		return
	end
	if visible then
		local renderC = self:GetEntity():AddComponent(ents.COMPONENT_RENDER)
		renderC:SetCastShadows(false)
		renderC:AddToRenderGroup("pfm_editor_overlay")
	end

	if actorC ~= nil then
		actorC:SetDefaultRenderMode(visible and game.SCENE_RENDER_PASS_WORLD or game.SCENE_RENDER_PASS_NONE, true)
	end

	if visible == false then
		return
	end
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
function Component:SetFrustumModelDirty()
	self.m_updateFrustumModel = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnTick(dt)
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	self:UpdateRenderData()
	pfm.tag_render_scene_as_dirty()
end
function Component:Setup(actorData, cameraData)
	self.m_cameraData = cameraData
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	local camComponentData = actorData:FindComponent("camera")
	--[[if(camComponentData ~= nil and camC ~= nil) then
		camC:SetNearZ(math.max(camComponentData:GetMemberValue("nearz"),1))
		camC:SetFarZ(math.max(camComponentData:GetMemberValue("farz"),1))
		camC:SetFOV(camComponentData:GetMemberValue("fov"))
		camC:SetAspectRatio(camComponentData:GetMemberValue("aspectRatio"))
		camC:SetFocalDistance(camComponentData:GetMemberValue("focalDistance"))
		camC:UpdateProjectionMatrix()

		table.insert(self.m_listeners,camComponentData:AddChangeListener("nearz",function(c,newZNear)
			if(camC:IsValid()) then
				camC:SetNearZ(math.max(newZNear,1))
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,camComponentData:AddChangeListener("farz",function(c,newZFar)
			if(camC:IsValid()) then
				camC:SetFarZ(math.max(newZFar,1))
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,camComponentData:AddChangeListener("fov",function(c,newFov)
			if(camC:IsValid()) then
				camC:SetFOV(newFov)
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,camComponentData:AddChangeListener("aspectRatio",function(c,newAspectRatio)
			if(camC:IsValid()) then camC:SetAspectRatio(newAspectRatio) end
		end))
		table.insert(self.m_listeners,camComponentData:AddChangeListener("focalDistance",function(c,newFocalDistance)
			if(camC:IsValid()) then camC:SetFocalDistance(newFocalDistance) end
		end))
		self:UpdateAspectRatio()
	end]]
end
function Component:OnEntitySpawn()
	--local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	--if(toggleC ~= nil) then toggleC:TurnOff() end

	local pl = ents.get_local_player()
	if pl ~= nil then
		pl:SetObserverMode(ents.PlayerComponent.OBSERVERMODE_FIRSTPERSON)
	end
end
ents.COMPONENT_PFM_CAMERA = ents.register_component("pfm_camera", Component)
Component.EVENT_ON_ACTIVE_STATE_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_CAMERA, "on_active_state_changed")
