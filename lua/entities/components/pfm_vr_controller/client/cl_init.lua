--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/vr/vr_interface.lua")
include_component("gui_3d")

util.register_class("ents.PFMVRController",BaseEntityComponent)

function ents.PFMVRController:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent("vr_controller")
	self:AddEntityComponent(ents.COMPONENT_OWNABLE)

	self:BindEvent(ents.VRController.EVENT_ON_TRIGGER_STATE_CHANGED,"OnTriggerStateChanged")
end

function ents.PFMVRController:OnTriggerStateChanged(triggerState)
	local playButton = util.is_valid(self.m_guiInterface) and self.m_guiInterface:GetPlayButton() or nil
	if(util.is_valid(playButton) == false) then return end
	if(triggerState == ents.VRController.TRIGGER_STATE_RELEASE) then
		playButton:SetActivated(false)
	elseif(triggerState == ents.VRController.TRIGGER_STATE_TOUCH) then
		playButton:SetActivated(true)
	else
		playButton:TogglePlay()
	end
end

function ents.PFMVRController:OnRemove()
	if(util.is_valid(self.m_guiInterface)) then self.m_guiInterface:Remove() end
	if(util.is_valid(self.m_guiEnt)) then self.m_guiEnt:Remove() end
end

function ents.PFMVRController:CreateGUIModel()
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local subMesh = game.Model.Mesh.Sub.Create()
	local origin = Vector(0,0,0)
	local p0 = origin +Vector(0,1,-1)
	local p1 = origin +Vector(0,1,1)
	local p2 = origin +Vector(0,-1,1)
	local p3 = origin +Vector(0,-1,-1)

	local v0 = game.Model.Vertex(p0,Vector2(0,0),Vector(-1,0,0))
	local v1 = game.Model.Vertex(p1,Vector2(1,0),Vector(-1,0,0))
	local v2 = game.Model.Vertex(p2,Vector2(1,1),Vector(-1,0,0))
	local v3 = game.Model.Vertex(p3,Vector2(0,1),Vector(-1,0,0))
	local idx0 = subMesh:AddVertex(v0)
	local idx1 = subMesh:AddVertex(v1)
	local idx2 = subMesh:AddVertex(v2)
	local idx3 = subMesh:AddVertex(v3)
	subMesh:AddTriangle(idx0,idx3,idx1)
	subMesh:AddTriangle(idx1,idx3,idx2)

	local mesh = game.Model.Mesh.Create()
	mesh:AddSubMesh(subMesh)
	meshGroup:AddMesh(mesh)
	
	mdl:Update(game.Model.FUPDATE_ALL)
	return mdl,subMesh
end

function ents.PFMVRController:GetGUIElement() return self.m_guiInterface end

function ents.PFMVRController:InitializeInterface()
	self.m_guiInterface = gui.create("WIPFMVRInterface")
	self.m_guiInterface:SetAlwaysUpdate(true) -- The element will not be drawn on screen, but we need it to update anyway
	self.m_guiInterface:SetVisible(false)

	self.m_guiEnt = ents.create("entity")
	local mdlC = self.m_guiEnt:AddComponent(ents.COMPONENT_MODEL)
	self.m_guiEnt:AddComponent(ents.COMPONENT_RENDER)
	self.m_guiEnt:AddComponent(ents.COMPONENT_TRANSFORM)

	local mdl,subMesh = self:CreateGUIModel()
	if(mdlC ~= nil) then mdlC:SetModel(mdl) end

	local gui3dC = self.m_guiEnt:AddComponent("gui_3d")
	if(gui3dC ~= nil) then gui3dC:Setup(self.m_guiInterface,subMesh) end
	self.m_guiEnt:Spawn()

	local ent = self:GetEntity()
	local origin = ent:GetPos() +ent:GetUp() *0.5 +ent:GetForward() *4
	self.m_guiEnt:SetPos(origin)
	self.m_guiEnt:SetRotation(EulerAngles(0,90,-90):ToQuaternion() *ent:GetRotation())

	local attInfo = ents.AttachableComponent.AttachmentInfo()
	attInfo.flags = ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME
	self.m_guiEnt:AddComponent(ents.COMPONENT_ATTACHABLE):AttachToEntity(ent,attInfo)
end

function ents.PFMVRController:OnEntitySpawn()
	local ent = self:GetEntity()
	local ownableC = ent:GetComponent(ents.COMPONENT_OWNABLE)
	local pl = ents.get_local_player()
	if(ownableC ~= nil and pl ~= nil) then
		ownableC:SetOwner(pl:GetEntity())
	end

	self:InitializeInterface()
end
ents.COMPONENT_PFM_VR_CONTROLLER = ents.register_component("pfm_vr_controller",ents.PFMVRController)
