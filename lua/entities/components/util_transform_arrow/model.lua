--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = ents.UtilTransformArrowComponent

local function create_arrow_mesh(tex, cylinderWidth)
	local scale = 1.2
	scale = Vector(scale, scale, scale)
	local mesh = game.Model.Mesh.Create()
	local meshBase = game.Model.Mesh.Sub.create_cylinder(game.Model.CylinderCreateInfo(cylinderWidth, 16.0))
	meshBase:SetSkinTextureIndex(tex or 0)
	meshBase:Scale(scale)
	mesh:AddSubMesh(meshBase)

	local meshTip = game.Model.Mesh.Sub.create_cone(game.Model.ConeCreateInfo(
		0.8, -- startRadius
		5.0, -- length
		0.0 -- endRadius
	))
	meshTip:SetSkinTextureIndex(tex or 0)
	meshTip:Translate(Vector(0.0, 0.0, 16.0))
	meshTip:Scale(scale)
	mesh:AddSubMesh(meshTip)
	return mesh
end

local arrowModel
function Component:GetArrowModel()
	if arrowModel ~= nil then
		return arrowModel
	end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local mesh = create_arrow_mesh(0, 0.2)
	local meshInteract = create_arrow_mesh(1, 2)

	meshGroup:AddMesh(mesh)
	meshGroup:AddMesh(meshInteract)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0, "pfm/gizmo")
	mdl:AddMaterial(0, "tools/toolsnodraw")

	arrowModel = mdl
	return mdl
end

local function create_model(subMesh, subMeshInteract, scale)
	if type(subMesh) ~= "table" then
		subMesh = { subMesh }
	end
	if type(subMeshInteract) ~= "table" then
		subMeshInteract = { subMeshInteract }
	end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	scale = Vector(scale, scale, scale)
	local mesh = game.Model.Mesh.Create()

	for _, sm in ipairs(subMesh) do
		sm:SetSkinTextureIndex(0)
		sm:Scale(scale)
		mesh:AddSubMesh(sm)
	end

	for _, sm in ipairs(subMeshInteract) do
		sm:SetSkinTextureIndex(1)
		sm:Scale(scale)
		mesh:AddSubMesh(sm)
	end

	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0, "pfm/gizmo")
	mdl:AddMaterial(0, "tools/toolsnodraw")
	return mdl
end

local diskModel
function Component:GetDiskModel()
	if diskModel ~= nil then
		return diskModel
	end
	local scale = 2
	local mesh = game.Model.Mesh.Sub.create_ring(game.Model.RingCreateInfo(9, 8.5, true))
	local meshInteract = game.Model.Mesh.Sub.create_ring(game.Model.RingCreateInfo(10, 7, true))
	diskModel = create_model(mesh, meshInteract, scale)
	return diskModel
end

local scaleModel
function Component:GetScaleModel()
	if scaleModel ~= nil then
		return scaleModel
	end
	local scale = 0.8
	local meshScale = 2.0
	local mesh = game.Model.Mesh.Sub.create_cylinder(game.Model.CylinderCreateInfo(0.5 * meshScale, 10.0 * meshScale))
	local mesh2 = game.Model.Mesh.Sub.create_cylinder(game.Model.CylinderCreateInfo(1 * meshScale, 3 * meshScale))
	local zOffset = 5
	for i = 0, mesh:GetVertexCount() - 1 do
		local v = mesh:GetVertexPosition(i)
		v.z = v.z + zOffset
		mesh:SetVertexPosition(i, v)
	end
	for i = 0, mesh2:GetVertexCount() - 1 do
		local v = mesh2:GetVertexPosition(i)
		v.z = v.z + 10 * meshScale + zOffset
		mesh2:SetVertexPosition(i, v)
	end
	scaleModel = create_model({ mesh, mesh2 }, { mesh:Copy(true), mesh2:Copy(true) }, scale)
	return scaleModel
end

local planeModel
function Component:GetPlaneModel()
	if planeModel ~= nil then
		return planeModel
	end
	local scale = 1.2
	local offset = Vector(5, 0, 5)
	local meshBox = game.Model.Mesh.Sub.create_box(
		game.Model.BoxCreateInfo(offset + Vector(-1.5, -0.1, -1.5), offset + Vector(1.5, 0.1, 1.5))
	)
	local meshBoxInteract = game.Model.Mesh.Sub.create_box(
		game.Model.BoxCreateInfo(offset + Vector(-5, -0.1, -5), offset + Vector(5, 0.1, 5))
	)
	planeModel = create_model(meshBox, meshBoxInteract, scale)
	return planeModel
end

local boxModel
function Component:GetBoxModel()
	if boxModel ~= nil then
		return boxModel
	end
	local scale = 0.8
	local meshBox = game.Model.Mesh.Sub.create_box(game.Model.BoxCreateInfo(Vector(-2, -2, -2), Vector(2, 2, 2)))
	local meshBoxInteract =
		game.Model.Mesh.Sub.create_box(game.Model.BoxCreateInfo(Vector(-4, -4, -4), Vector(4, 4, 4)))
	boxModel = create_model(meshBox, meshBoxInteract, scale)
	return boxModel
end
