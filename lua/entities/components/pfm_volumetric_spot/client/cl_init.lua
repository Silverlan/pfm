--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMVolumetricSpot",BaseEntityComponent)

function ents.PFMVolumetricSpot:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
end

function ents.PFMVolumetricSpot:OnEntitySpawn()
	self:GenerateModel()
end

function ents.PFMVolumetricSpot:GenerateModel()
	local mdl = game.create_model()
	local group = mdl:AddMeshGroup("reference")

	local ent = self:GetEntity()
	local radiusC = ent:GetComponent(ents.COMPONENT_RADIUS)
	local maxDist = (radiusC ~= nil) and radiusC:GetRadius() or 100.0

	local spotC = ent:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	local coneAngle = spotC:GetOuterConeAngle()
	local endRadius = maxDist *math.tan(math.rad(coneAngle))

	--[[auto *mat = static_cast<CMaterial*>(client->CreateMaterial("lightcone","light_cone"));
	auto &data = mat->GetDataBlock();
	data->AddValue("int","alpha_mode",std::to_string(umath::to_integral(AlphaMode::Blend)));
	data->AddValue("float","cone_height",std::to_string(maxDist));
	mat->SetTexture("albedo_map","error");]]

	local coneDetail = 64
	local segmentCount = 1
	local startOffset = 1.0
	local dir = vector.FORWARD:Copy()
	local mesh = game.Model.Mesh.Create()
	for i=0,segmentCount -1 do
		local startSc = i /segmentCount;
		local endSc = (i +1) /segmentCount;
		
		local segEndRadius = endRadius *endSc;
		if(segEndRadius >= startOffset) then
			local segStartRadius = endRadius *startSc;
			if(segStartRadius < startOffset) then
				-- Clamp this segment
				segStartRadius = startOffset;
			end

			local startPos = dir *maxDist *(segStartRadius /endRadius)
			local endPos = dir *maxDist *(segEndRadius /endRadius)
			local subMesh = game.Model.Mesh.Sub.Create()
			local verts,tris,normals = geometry.generate_truncated_cone_mesh(startPos,segStartRadius,dir,startPos:Distance(endPos),segEndRadius,coneDetail,false,true,true)
			for i=1,#tris,3 do
				subMesh:AddTriangle(tris[i],tris[i +1],tris[i +2])
			end

			for idx=1,#verts do
				subMesh:AddVertex(game.Model.Vertex(verts[idx],normals[idx]))
			end

			subMesh:SetSkinTextureIndex(0)
			mesh:AddSubMesh(subMesh)
		end
	end
	group:AddMesh(mesh)
	mdl:AddMaterial(0,game.load_material("volumes/generic_volume"))--mat);
	mdl:Update(game.Model.FUPDATE_ALL)

	ent:SetModel(mdl)
end
ents.COMPONENT_PFM_VOLUMETRIC_SPOT = ents.register_component("pfm_volumetric_spot",ents.PFMVolumetricSpot)
