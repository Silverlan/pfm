--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_wireframe_line.lua")

util.register_class("ents.PFMCamera",BaseEntityComponent)

ents.PFMCamera.impl = util.get_class_value(ents.PFMCamera,"impl") or {
	activeCamera = nil,
	cameraEnabled = false,
	vrEnabled = false
}
ents.PFMCamera.get_active_camera = function() return ents.PFMCamera.impl.activeCamera end
ents.PFMCamera.is_camera_enabled = function() return ents.PFMCamera.impl.cameraEnabled end
ents.PFMCamera.set_camera_enabled = function(enabled)
	if(enabled) then pfm.log("Enabling camera...",pfm.LOG_CATEGORY_PFM_GAME)
	else pfm.log("Disabling camera...",pfm.LOG_CATEGORY_PFM_GAME) end
	ents.PFMCamera.impl.cameraEnabled = enabled
	ents.PFMCamera.set_active_camera(ents.PFMCamera.impl.activeCamera)
end
ents.PFMCamera.set_active_camera = function(cam)
	if(util.is_valid(ents.PFMCamera.impl.activeCamera)) then
		local toggleC = ents.PFMCamera.impl.activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if(toggleC ~= nil) then toggleC:TurnOff() end
		ents.PFMCamera.impl.activeCamera = nil
	end
	if(util.is_valid(cam) == false) then
		pfm.log("Setting active camera to: None",pfm.LOG_CATEGORY_PFM_GAME)
		return
	end
	pfm.log("Setting active camera to: " .. cam:GetEntity():GetName(),pfm.LOG_CATEGORY_PFM_GAME)
	ents.PFMCamera.impl.activeCamera = cam
	local toggleC = ents.PFMCamera.impl.activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:SetTurnedOn(ents.PFMCamera.impl.cameraEnabled) end
	ents.PFMCamera.impl.activeCamera:UpdateVRView()
end
ents.PFMCamera.set_vr_view_enabled = function(enabled)
	if(enabled) then pfm.log("Enabling VR view...",pfm.LOG_CATEGORY_PFM_GAME)
	else pfm.log("Disabling VR view...",pfm.LOG_CATEGORY_PFM_GAME) end
	ents.PFMCamera.impl.vrEnabled = enabled
	if(util.is_valid(ents.PFMCamera.impl.activeCamera)) then
		ents.PFMCamera.impl.activeCamera:UpdateVRView()
	end
end
ents.PFMCamera.is_vr_view_enabled = function() return ents.PFMCamera.impl.vrEnabled end

function ents.PFMCamera:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_CAMERA)
	local toggleC = self:AddEntityComponent(ents.COMPONENT_TOGGLE)
	self:AddEntityComponent("pfm_actor")

	if(toggleC ~= nil) then
		self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON,"OnTurnOn")
		self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF,"OnTurnOff")
	end

	self.m_listeners = {}
end
function ents.PFMCamera:OnTurnOn()
	if(self.m_frustumModel == nil) then return end
	self:SetFrustumModelVisible(false)
end
function ents.PFMCamera:OnTurnOff()
	if(self.m_frustumModel == nil) then return end
	self:SetFrustumModelVisible(true)
end
function ents.PFMCamera:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
	if(util.is_valid(self.m_cbFrustumModelUpdate)) then self.m_cbFrustumModelUpdate:Remove() end
end
function ents.PFMCamera:UpdateVRView()
	if(ents.PFMCamera.is_vr_view_enabled()) then
		self:GetEntity():AddComponent("pfm_vr_camera")
	else
		self:GetEntity():RemoveComponent("pfm_vr_camera")
	end
end
function ents.PFMCamera:UpdateAspectRatio()
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(camC == nil) then return end
	local camData = self:GetCameraData()
	camC:SetAspectRatio(camData:GetAspectRatio())
	camC:UpdateProjectionMatrix()
end
function ents.PFMCamera:GetCameraData() return self.m_cameraData end
local MODEL_VERTEX_COUNT = 32
function ents.PFMCamera:InitializeModel()
	if(self.m_frustumModel ~= nil) then return self.m_frustumModel end
	-- Generate model
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local subMesh = game.Model.Mesh.Sub.Create()
	subMesh:SetGeometryType(game.Model.Mesh.Sub.GEOMETRY_TYPE_LINES)

	local indices = {}
	for i=1,MODEL_VERTEX_COUNT do
		local v = game.Model.Vertex(Vector(),Vector2(0,0),Vector(0,0,0))
		local idx = subMesh:AddVertex(v)
		table.insert(indices,idx)
	end

	for i=1,#indices,2 do
		subMesh:AddLine(indices[i],indices[i +1])
	end

	local mat = game.create_material("pfm_wireframe_line")
	mat:SetTexture("albedo_map","white")
	local matIdx = mdl:AddMaterial(0,mat)
	subMesh:SetSkinTextureIndex(matIdx)

	local mesh = game.Model.Mesh.Create()
	mesh:AddSubMesh(subMesh)
	meshGroup:AddMesh(mesh)
	
	mdl:Update(game.Model.FUPDATE_ALL)
	self.m_frustumModel = mdl
	self:UpdateModel()
	self:SetFrustumModelDirty()
	return mdl
end
function ents.PFMCamera:UpdateModel()
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(camC == nil or self.m_frustumModel == nil) then return end
	local meshGroup = self.m_frustumModel:GetMeshGroup(0) or nil
	local mesh = (meshGroup ~= nil) and meshGroup:GetMesh(0) or nil
	local subMesh = (mesh ~= nil) and mesh:GetSubMesh(0) or nil
	if(subMesh == nil) then return end

	local pos = Vector()
	local nearPlaneBoundaries = math.get_frustum_plane_boundaries(pos,vector.FORWARD,vector.UP,camC:GetFOVRad(),camC:GetAspectRatio(),camC:GetNearZ())
	local farPlaneBoundaries = math.get_frustum_plane_boundaries(pos,vector.FORWARD,vector.UP,camC:GetFOVRad(),camC:GetAspectRatio(),camC:GetFarZ())
	local vertIdx = 0

	-- Near plane
	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[1]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[2]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[2]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[3]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[3]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[4]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[4]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,nearPlaneBoundaries[1]) vertIdx = vertIdx +1

	-- Far plane
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[1]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[2]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[2]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[3]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[3]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[4]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[4]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[1]) vertIdx = vertIdx +1

	-- Cam pos to far plane
	subMesh:SetVertexPosition(vertIdx,pos) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[1]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,pos) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[2]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,pos) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[3]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,pos) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,farPlaneBoundaries[4]) vertIdx = vertIdx +1

	-- Focal distance plane
	local focalDistance = self:GetCameraData():GetFocalDistance()
	local focalPlaneBoundaries = math.get_frustum_plane_boundaries(pos,vector.FORWARD,vector.UP,camC:GetFOVRad(),camC:GetAspectRatio(),focalDistance)

	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[1]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[2]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[2]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[3]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[3]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[4]) vertIdx = vertIdx +1

	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[4]) vertIdx = vertIdx +1
	subMesh:SetVertexPosition(vertIdx,focalPlaneBoundaries[1]) vertIdx = vertIdx +1

	subMesh:Update(game.Model.FUPDATE_VERTEX_BUFFER)
end
function ents.PFMCamera:SetFrustumModelVisible(visible)
	if(visible) then self:GetEntity():AddComponent(ents.COMPONENT_RENDER) end

	local actorC = self:GetEntity():GetComponent("pfm_actor")
	if(actorC ~= nil) then actorC:SetDefaultRenderMode(visible and ents.RenderComponent.RENDERMODE_WORLD or ents.RenderComponent.RENDERMODE_NONE) end

	if(visible == false) then return end
	local mdlC = self:GetEntity():AddComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil or mdlC:GetModel() ~= nil) then return end
	local model = self:InitializeModel()
	if(model == nil) then return end
	mdlC:SetModel(model)
end
function ents.PFMCamera:SetFrustumModelDirty()
	if(util.is_valid(self.m_cbFrustumModelUpdate)) then return end
	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if(renderC == nil) then return end
	self.m_cbFrustumModelUpdate = renderC:AddEventCallback(ents.RenderComponent.EVENT_ON_UPDATE_RENDER_DATA,function()
		if(util.is_valid(self.m_cbFrustumModelUpdate)) then self.m_cbFrustumModelUpdate:Remove() end
		self:UpdateModel()
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function ents.PFMCamera:Setup(actorData,cameraData)
	self.m_cameraData = cameraData
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(camC ~= nil) then
		camC:SetNearZ(cameraData:GetZNear())
		camC:SetFarZ(cameraData:GetZFar())
		camC:SetFOV(cameraData:GetFov())
		camC:UpdateProjectionMatrix()

		table.insert(self.m_listeners,cameraData:GetZNearAttr():AddChangeListener(function(newZNear)
			if(camC:IsValid()) then
				camC:SetNearZ(newZNear)
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,cameraData:GetZFarAttr():AddChangeListener(function(newZFar)
			if(camC:IsValid()) then
				camC:SetFarZ(newZFar)
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,cameraData:GetFovAttr():AddChangeListener(function(newFov)
			if(camC:IsValid()) then
				camC:SetFOV(newFov)
				camC:UpdateProjectionMatrix()
			end
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,cameraData:GetAspectRatioAttr():AddChangeListener(function(newAspectRatio)
			self:UpdateAspectRatio()
			self:SetFrustumModelDirty()
		end))
		table.insert(self.m_listeners,cameraData:GetFocalDistanceAttr():AddChangeListener(function(newFocalDistance)
			self:SetFrustumModelDirty()
		end))
		self:UpdateAspectRatio()
	end
end
function ents.PFMCamera:OnEntitySpawn()
	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOff() end
end
ents.COMPONENT_PFM_CAMERA = ents.register_component("pfm_camera",ents.PFMCamera)
