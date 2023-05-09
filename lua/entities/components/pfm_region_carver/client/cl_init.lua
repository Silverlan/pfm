--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_region_carge_target")

local Component = util.register_class("ents.PFMRegionCarver", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_cuboid_bounds")
end
function Component:SetCarveModel(ent, mdl)
	local pm = pfm.get_project_manager()
	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) == false then
		return
	end

	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	if actor ~= nil then
		if #mdl > 0 then
			ent:AddComponent("pfm_region_carve_target")
			local component = actor:FindComponent("pfm_region_carve_target")
			if component == nil then
				actorEditor:CreateNewActorComponent(actor, "pfm_region_carve_target", false)
			end
			pm:SetActorGenericProperty(actorC, "ec/pfm_region_carve_target/carvedModel", mdl, udm.TYPE_STRING)
			actorEditor:UpdateActorComponents(actor)
		else
			ent:RemoveComponent("pfm_region_carve_target")
			actor:RemoveComponentType("pfm_region_carve_target")
			actorEditor:UpdateActorComponents(actor)
		end
	end
end
function Component:CarveModel(ent)
	local pm = pfm.get_project_manager()
	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) == false then
		return
	end

	local mdlName = ent:GetModelName()
	local mdl = game.load_model(mdlName)
	if mdl == nil then
		return
	end

	local bodygroups = {}
	local skin = ent:GetSkin()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC ~= nil then
		bodygroups = mdlC:GetBodyGroups()
	end

	ent:ClearModel()
	ent:SetModel(mdlName) -- Reset original model

	ent:SetSkin(skin)
	if util.is_valid(mdlC) then
		for k, v in pairs(bodygroups) do
			mdlC:SetBodyGroup(k, v)
		end
	end

	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC ~= nil then
		mdlC:UpdateRenderMeshes()
	end
	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	if renderC == nil then
		return
	end
	local meshes = renderC:GetRenderMeshes()

	local cuboidC = self:GetEntityComponent(ents.COMPONENT_PFM_CUBOID_BOUNDS)
	if cuboidC == nil then
		return
	end
	local min, max = cuboidC:GetBounds()

	mdl = mdl:Copy(bit.bor(game.Model.FCOPY_DEEP, game.Model.FCOPY_BIT_COPY_UNIQUE_IDS))

	local keepIds = {}
	for _, subMesh in ipairs(meshes) do
		if subMesh:GetGeometryType() == game.Model.Mesh.Sub.GEOMETRY_TYPE_TRIANGLES then
			keepIds[tostring(subMesh:GetUuid())] = true
		end
	end

	local subMeshes = {}
	for _, mg in ipairs(mdl:GetMeshGroups()) do
		for _, m in ipairs(mg:GetMeshes()) do
			for _, sm in ipairs(m:GetSubMeshes()) do
				local uuid = tostring(sm:GetUuid())
				if keepIds[uuid] == nil then
					m:RemoveSubMesh(uuid)
				else
					table.insert(subMeshes, sm)
				end
			end
		end
	end

	local entPose = ent:GetPose()
	local newMeshes = {}
	local hasOutsideTriangles = false
	local hasInsideTriangles = false
	for _, sm in ipairs(subMeshes) do
		local indices = sm:GetIndices()
		local verts = sm:GetVertices()
		local inMeshData = {
			newVerts = {},
			newIndices = {},
			oldIndexToNewIndex = {},
		}
		local exMeshData = {
			newVerts = {},
			newIndices = {},
			oldIndexToNewIndex = {},
		}
		local function add_vertex(meshData, idx)
			if meshData.oldIndexToNewIndex[idx] ~= nil then
				table.insert(meshData.newIndices, meshData.oldIndexToNewIndex[idx])
				return meshData.oldIndexToNewIndex[idx]
			end
			local newIdx = #meshData.newVerts
			table.insert(meshData.newVerts, sm:GetVertex(idx))
			table.insert(meshData.newIndices, newIdx)
			meshData.oldIndexToNewIndex[idx] = newIdx
			return newIdx
		end
		for i = 1, #indices, 3 do
			local idx0 = indices[i]
			local idx1 = indices[i + 1]
			local idx2 = indices[i + 2]
			local v0 = verts[idx0 + 1]
			local v1 = verts[idx1 + 1]
			local v2 = verts[idx2 + 1]
			local v0g = entPose * v0
			local v1g = entPose * v1
			local v2g = entPose * v2
			local hasIntersect = intersect.aabb_with_triangle(min, max, v0g, v1g, v2g)
			if hasIntersect == true then
				hasInsideTriangles = true
				add_vertex(inMeshData, idx0)
				add_vertex(inMeshData, idx1)
				add_vertex(inMeshData, idx2)
			else
				hasOutsideTriangles = true
				add_vertex(exMeshData, idx0)
				add_vertex(exMeshData, idx1)
				add_vertex(exMeshData, idx2)
			end
		end

		local function buildMesh(meshData)
			local newMesh = sm:Copy(true)
			newMesh:SetUuid(sm:GetUuid())
			newMesh:ClearVertices()
			newMesh:ClearVertexWeights()
			newMesh:ClearIndices()
			for _, v in ipairs(meshData.newVerts) do
				newMesh:AddVertex(v)
			end
			for i = 1, #meshData.newIndices, 3 do
				local idx0 = meshData.newIndices[i]
				local idx1 = meshData.newIndices[i + 1]
				local idx2 = meshData.newIndices[i + 2]
				newMesh:AddTriangle(idx0, idx1, idx2)
			end
			newMesh:Update(game.Model.FUPDATE_ALL_DATA)
			return newMesh
		end
		local inMesh = buildMesh(inMeshData)
		-- local exMesh = buildMesh(exMeshData)

		newMeshes[tostring(sm:GetUuid())] = inMesh
	end

	if hasOutsideTriangles == false then
		self:SetCarveModel(ent, "")
		return
	end

	if hasInsideTriangles == false then
		self:SetCarveModel(ent, "empty")
		return
	end

	for _, mg in ipairs(mdl:GetMeshGroups()) do
		for _, m in ipairs(mg:GetMeshes()) do
			local smIds = {}
			for _, sm in ipairs(m:GetSubMeshes()) do
				table.insert(smIds, tostring(sm:GetUuid()))
			end

			for _, uuid in ipairs(smIds) do
				m:RemoveSubMesh(uuid)
				local newMesh = newMeshes[uuid]
				if newMesh ~= nil then
					m:AddSubMesh(newMesh)
				end
			end
		end
	end

	mdl:Update(game.Model.FUPDATE_ALL)

	-- Save model
	local projectUuid = tostring(pm:GetProject():GetSession():GetUniqueId())
	local entUuid = tostring(ent:GetUuid())
	local basePath = "projects/" .. projectUuid .. "/carved/" .. entUuid
	local path = "models/" .. basePath
	local res = mdl:Save(path)
	if res ~= true then
		console.print_warning("Failed to save carved model at location '" .. path .. "'!")
	else
		asset.reload(basePath, asset.TYPE_MODEL)
	end

	self:SetCarveModel(ent, basePath)
end
function Component:Carve()
	local cuboidC = self:GetEntityComponent(ents.COMPONENT_PFM_CUBOID_BOUNDS)
	if cuboidC == nil then
		return
	end
	local min, max = cuboidC:GetBounds()

	for ent, c in ents.citerator(ents.COMPONENT_PFM_ACTOR) do
		if c:IsStatic() then
			self:CarveModel(ent)
		elseif ent:HasComponent("pfm_region_carve_target") then
			ent:RemoveComponent("pfm_region_carve_target")
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			local actor = (actorC ~= nil) and actorC:GetActorData() or nil
			if actor ~= nil then
				actor:RemoveComponentType("pfm_region_carve_target")

				local pm = pfm.get_project_manager()
				local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
				if util.is_valid(actorEditor) then
					actorEditor:UpdateActorComponents(actor)
				end
			end
		end
	end
end
ents.COMPONENT_PFM_REGION_CARVER = ents.register_component("pfm_region_carver", Component)
