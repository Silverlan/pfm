--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_flat.lua")

util.register_class("ents.PFMBone",BaseEntityComponent)

function ents.PFMBone:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local colorC = self:AddEntityComponent(ents.COMPONENT_COLOR)
	if(colorC ~= nil) then colorC:SetColor(Color.White) end
end

function ents.PFMBone:InitializeModel()
	--[[
	-- Generate model
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local subMesh = game.Model.Mesh.Sub.Create()
	local v0 = subMesh:AddVertex(game.Model.Vertex(Vector(0,0,0),Vector2(0,0),Vector(0,-1,0)))
	local v1 = subMesh:AddVertex(game.Model.Vertex(Vector(10,10,10) /65.0,Vector2(0,0),Vector(0.57735,-0.57735,0.57735)))
	local v2 = subMesh:AddVertex(game.Model.Vertex(Vector(-10,10,10) /65.0,Vector2(0,0),Vector(-0.57735,-0.57735,0.57735)))
	local v3 = subMesh:AddVertex(game.Model.Vertex(Vector(-10,-10,10) /65.0,Vector2(0,0),Vector(-0.57735,-0.57735,-0.57735)))
	local v4 = subMesh:AddVertex(game.Model.Vertex(Vector(10,-10,10) /65.0,Vector2(0,0),Vector(0.57735,-0.57735,-0.57735)))
	local v5 = subMesh:AddVertex(game.Model.Vertex(Vector(0,0,65) /65.0,Vector2(0,0),Vector(0,1,0)))

	subMesh:AddTriangle(v0,v2,v1)
	subMesh:AddTriangle(v0,v3,v2)
	subMesh:AddTriangle(v0,v4,v3)
	subMesh:AddTriangle(v0,v1,v4)

	subMesh:AddTriangle(v2,v5,v1)
	subMesh:AddTriangle(v3,v5,v2)
	subMesh:AddTriangle(v4,v5,v3)
	subMesh:AddTriangle(v1,v5,v4)

	local matIdx = mdl:AddMaterial(0,game.load_material("pfm/skeleton_bone.wmi"))
	subMesh:SetSkinTextureIndex(matIdx)

	local mesh = game.Model.Mesh.Create()
	mesh:AddSubMesh(subMesh)
	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)]]
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if(mdlC ~= nil) then mdlC:SetModel("pfm/bone.wmd") end
end

function ents.PFMBone:OnEntitySpawn()
	self:InitializeModel()
end
ents.COMPONENT_PFM_BONE = ents.register_component("pfm_bone",ents.PFMBone)
