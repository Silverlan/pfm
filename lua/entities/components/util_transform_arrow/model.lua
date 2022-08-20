--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = ents.UtilTransformArrowComponent

local arrowModel
function Component:GetArrowModel()
	if(arrowModel ~= nil) then return arrowModel end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local scale = 1.0
	scale = Vector(scale,scale,scale)
	local mesh = game.Model.Mesh.Create()
	local meshBase = game.Model.Mesh.Sub.CreateCylinder(0.4,16.0,12)
	meshBase:SetSkinTextureIndex(0)
	meshBase:Scale(scale)
	mesh:AddSubMesh(meshBase)

	local meshTip = game.Model.Mesh.Sub.CreateCone(
		1.0, -- startRadius
		5.0, -- length
		0.0, -- endRadius
		12 -- segmentCount
	)
	meshTip:SetSkinTextureIndex(0)
	meshTip:Translate(Vector(0.0,0.0,16.0))
	meshTip:Scale(scale)
	mesh:AddSubMesh(meshTip)


	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0,"pfm/gizmo")

	arrowModel = mdl
	return mdl
end

local function create_model(subMesh,scale)
	if(type(subMesh) ~= "table") then subMesh = {subMesh} end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	scale = Vector(scale,scale,scale)
	local mesh = game.Model.Mesh.Create()

	for _,sm in ipairs(subMesh) do
		sm:SetSkinTextureIndex(0)
		sm:Scale(scale)
		mesh:AddSubMesh(sm)
	end

	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0,"pfm/gizmo")
	return mdl
end

local diskModel
function Component:GetDiskModel()
	if(diskModel ~= nil) then return diskModel end
	local scale = 1.5
	local mesh = game.Model.Mesh.Sub.CreateRing(7.5,8,true)
	diskModel = create_model(mesh,scale)
	return diskModel
end

local scaleModel
function Component:GetScaleModel()
	if(scaleModel ~= nil) then return scaleModel end
	local scale = 1.0
	local meshScale = 2.0

	local scale0 = 0.5 *meshScale
	local length0 = 10.0 *meshScale
	local scale1 = 1 *meshScale
	local length1 = 3 *meshScale
	local mesh = game.Model.Mesh.Sub.CreateCylinder(scale0,length0,12)
	local mesh2 = game.Model.Mesh.Sub.CreateCylinder(scale1,length1,12)

	local zOffset = 5
	for i=0,mesh:GetVertexCount() -1 do
		local v = mesh:GetVertexPosition(i)
		v.z = v.z -zOffset
		v.z = v.z -scale0 -length0
		mesh:SetVertexPosition(i,v)
	end
	for i=0,mesh2:GetVertexCount() -1 do
		local v = mesh2:GetVertexPosition(i)
		v.z = v.z -9.5 *meshScale -zOffset
		v.z = v.z -scale1 -length1
		mesh2:SetVertexPosition(i,v)
	end
	scaleModel = create_model({mesh,mesh2},scale)
	return scaleModel
end

local planeModel
function Component:GetPlaneModel()
	if(planeModel ~= nil) then return planeModel end
	local scale = 1.0
	local offset = Vector(5,0,5)
	local meshBox = game.Model.Mesh.Sub.CreateBox(offset +Vector(-3,-0.1,-3),offset +Vector(3,0.1,3))
	planeModel = create_model(meshBox,scale)
	return planeModel
end

local boxModel
function Component:GetBoxModel()
	if(boxModel ~= nil) then return boxModel end
	local scale = 1.0
	local meshBox = game.Model.Mesh.Sub.CreateBox(Vector(-2,-2,-2),Vector(2,2,2))
	boxModel = create_model(meshBox,scale)
	return boxModel
end
