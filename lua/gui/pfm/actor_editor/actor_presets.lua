--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP = 0
gui.PFMActorEditor.ACTOR_PRESET_TYPE_DYNAMIC_PROP = 1
gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR = 2
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA = 3
gui.PFMActorEditor.ACTOR_PRESET_TYPE_PARTICLE_SYSTEM = 4
gui.PFMActorEditor.ACTOR_PRESET_TYPE_SPOT_LIGHT = 5
gui.PFMActorEditor.ACTOR_PRESET_TYPE_POINT_LIGHT = 6
gui.PFMActorEditor.ACTOR_PRESET_TYPE_DIRECTIONAL_LIGHT = 7
gui.PFMActorEditor.ACTOR_PRESET_TYPE_VOLUME = 8
gui.PFMActorEditor.ACTOR_PRESET_TYPE_ACTOR = 9
gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER = 10
gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE = 11
gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY = 12
gui.PFMActorEditor.ACTOR_PRESET_TYPE_FOG = 13
gui.PFMActorEditor.ACTOR_PRESET_TYPE_DECAL = 14
gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_MANAGER = 15
gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_TRACKED_DEVICE = 16
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION = 17
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION = 18
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE = 19
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE = 20
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION = 21
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION = 22
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE = 23
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT = 24
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF = 25
gui.PFMActorEditor.ACTOR_PRESET_TYPE_ANIMATION_DRIVER = 26
gui.PFMActorEditor.ACTOR_PRESET_TYPE_SCENEBUILD = 27
gui.PFMActorEditor.ACTOR_PRESET_TYPE_GREENSCREEN = 28

gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_START = gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION
gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_END = gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF

local constraintTypeToName = {
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION] = "copy_location",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION] = "copy_rotation",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE] = "copy_scale",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE] = "limit_distance",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION] = "limit_location",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION] = "limit_rotation",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE] = "limit_scale",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT] = "look_at",
	[gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF] = "child_of",
}
gui.PFMActorEditor.constraint_type_to_name = function(type)
	return constraintTypeToName[type]
end

function gui.PFMActorEditor:CreateGenericActor(name, collection, fInitComponents)
	local function create_new_actor(name, collection, pose)
		if collection ~= nil then
			collection = self:FindCollection(collection, true)
		end
		return self:CreateNewActor(name, pose, nil, collection)
	end
	local actor = create_new_actor(name, collection)
	if actor == nil then
		return
	end
	fInitComponents(actor)

	local newActor = true
	local updateActorComponents = true
	if newActor and updateActorComponents then
		self:UpdateActorComponents(actor)
	end
	return actor
end

function gui.PFMActorEditor:CreatePresetActor(actorType, args)
	args = args or {}
	local actor = args["actor"]
	local mdlName = args["modelName"]
	local updateActorComponents = args["updateActorComponents"]
	local nameOverride = args["name"]
	local collectionOverride = args["collection"]

	if updateActorComponents == nil then
		updateActorComponents = true
	end
	local newActor = (actor == nil)
	local function create_new_actor(name, collection, pose)
		collection = collectionOverride or collection
		if collection ~= nil then
			collection = self:FindCollection(collection, true)
		end
		return self:CreateNewActor(nameOverride or name, pose, nil, collection)
	end
	if actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP then
		actor = actor or create_new_actor("static_prop", gui.PFMActorEditor.COLLECTION_SCENEBUILD)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
			actor:ChangeModel(mdlName)
		end)
		self:CreateNewActorComponent(actor, "model", false)
		self:CreateNewActorComponent(actor, "render", false)
		self:CreateNewActorComponent(actor, "light_map_receiver", false)

		local pfmActorC = actor:FindComponent("pfm_actor")
		if pfmActorC ~= nil then
			pfmActorC:SetMemberValue("static", udm.TYPE_BOOLEAN, true)
		end
		-- self:CreateNewActorComponent(actor,"transform",false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_DYNAMIC_PROP then
		actor = actor or create_new_actor("dynamic_prop", gui.PFMActorEditor.COLLECTION_ACTORS)
		if actor == nil then
			return
		end
		local mdlC = self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
			actor:ChangeModel(mdlName)
		end)
		self:CreateNewActorComponent(actor, "model", false)
		self:CreateNewActorComponent(actor, "render", false)
		-- self:CreateNewActorComponent(actor,"transform",false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR then
		actor = actor or create_new_actor("articulated_actor", gui.PFMActorEditor.COLLECTION_ACTORS)
		if actor == nil then
			return
		end
		local mdlC = self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
			actor:ChangeModel(mdlName)
		end)
		self:CreateNewActorComponent(actor, "model", false)
		self:CreateNewActorComponent(actor, "render", false)
		self:CreateNewActorComponent(actor, "animated", false)
		self:CreateNewActorComponent(actor, "eye", false)
		self:CreateNewActorComponent(actor, "flex", false)

		-- Set up default IK if possible
		if rig == nil then
			engine.load_library("pr_rig")
		end
		if rig ~= nil then
			local mdl = game.load_model(mdlName)
			if mdl ~= nil then
				local ikRigPath = rig.get_ik_rig_cache_path(mdl)
				local filePath = rig.get_ik_rig_base_path() .. ikRigPath
				if ikRigPath == nil or file.exists(filePath) == false then
					file.create_path(file.get_file_path(filePath))
					rig.generate_cached_ik_rig(mdl)
					ikRigPath = rig.get_ik_rig_cache_path(mdl)
				end

				if ikRigPath ~= nil and file.exists(filePath) then
					local ikSolverC = self:CreateNewActorComponent(actor, "ik_solver", false)
					ikSolverC:SetMemberValue("rigConfigFile", udm.TYPE_STRING, ikRigPath)
				end
			end
		end

		-- self:CreateNewActorComponent(actor,"transform",false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA then
		actor = actor or create_new_actor("camera", gui.PFMActorEditor.COLLECTION_CAMERAS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_camera", false)
		-- self:CreateNewActorComponent(actor,"toggle",false)
		self:CreateNewActorComponent(actor, "camera", false)
		-- self:CreateNewActorComponent(actor,"transform",false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_PARTICLE_SYSTEM then
		actor = actor or create_new_actor("particle_system", gui.PFMActorEditor.COLLECTION_EFFECTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_particle_system", false)
		self:CreateNewActorComponent(actor, "particle_system", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_SPOT_LIGHT then
		actor = actor or create_new_actor("spot_light", gui.PFMActorEditor.COLLECTION_LIGHTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_light_spot", false)
		local lightC = self:CreateNewActorComponent(actor, "light", false)
		local lightSpotC = self:CreateNewActorComponent(actor, "light_spot", false)
		local radiusC = self:CreateNewActorComponent(actor, "radius", false)
		self:CreateNewActorComponent(actor, "color", false)
		-- self:CreateNewActorComponent(actor,"transform",false)
		lightSpotC:SetMemberValue("blendFraction", udm.TYPE_FLOAT, 0.1)
		lightSpotC:SetMemberValue("outerConeAngle", udm.TYPE_FLOAT, 60.0)
		lightC:SetMemberValue("intensity", udm.TYPE_FLOAT, 100)
		lightC:SetMemberValue("castShadows", udm.TYPE_BOOLEAN, false)
		radiusC:SetMemberValue("radius", udm.TYPE_FLOAT, 1000)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_POINT_LIGHT then
		actor = actor or create_new_actor("point_light", gui.PFMActorEditor.COLLECTION_LIGHTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_light_point", false)
		local lightC = self:CreateNewActorComponent(actor, "light", false)
		self:CreateNewActorComponent(actor, "light_point", false)
		local radiusC = self:CreateNewActorComponent(actor, "radius", false)
		self:CreateNewActorComponent(actor, "color", false)
		-- self:CreateNewActorComponent(actor,"transform",false)
		lightC:SetMemberValue("intensity", udm.TYPE_FLOAT, 50)
		lightC:SetMemberValue("castShadows", udm.TYPE_BOOLEAN, false)
		radiusC:SetMemberValue("radius", udm.TYPE_FLOAT, 800)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_DIRECTIONAL_LIGHT then
		actor = actor or create_new_actor("dir_light", gui.PFMActorEditor.COLLECTION_LIGHTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_light_directional", false)
		local lightC = self:CreateNewActorComponent(actor, "light", false)
		self:CreateNewActorComponent(actor, "light_directional", false)
		self:CreateNewActorComponent(actor, "color", false)
		-- self:CreateNewActorComponent(actor,"transform",false)
		lightC:SetMemberValue("intensity", udm.TYPE_FLOAT, 30.0)
		lightC:SetMemberValue("intensityType", udm.TYPE_UINT8, ents.LightComponent.INTENSITY_TYPE_LUX)
		lightC:SetMemberValue("castShadows", udm.TYPE_BOOLEAN, false)

		local cActor = actor:FindComponent("pfm_actor")
		if cActor ~= nil then
			local rot = cActor:GetMemberValue("rotation")
			if rot ~= nil then
				rot = rot:ToEulerAngles()
				rot.p = 45.0
				cActor:SetMemberValue("rotation", udm.TYPE_QUATERNION, rot:ToQuaternion())
			end
		end
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_VOLUME then
		actor = actor or create_new_actor("volume", gui.PFMActorEditor.COLLECTION_ENVIRONMENT)
		if actor == nil then
			return
		end
		local mdlC = self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
			actor:ChangeModel("cube")
		end)
		local volC = self:CreateNewActorComponent(actor, "pfm_volumetric", false)
		local boundsC = self:CreateNewActorComponent(actor, "pfm_cuboid_bounds", false)
		self:CreateNewActorComponent(actor, "color", false)

		-- Calc scene extents
		local min = Vector(math.huge, math.huge, math.huge)
		local max = Vector(-math.huge, -math.huge, -math.huge)
		for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_RENDER) }) do
			if ent:HasComponent(ents.COMPONENT_CAMERA) == false then
				local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
				local rMin, rMax = renderC:GetAbsoluteRenderBounds()
				for i = 0, 2 do
					min:Set(i, math.min(min:Get(i), rMin:Get(i)))
					max:Set(i, math.max(max:Get(i), rMax:Get(i)))
				end
			end
		end
		if min.x == math.huge then
			min = Vector()
			max = Vector()
		end
		boundsC:SetMemberValue("minBounds", udm.TYPE_VECTOR3, min)
		boundsC:SetMemberValue("maxBounds", udm.TYPE_VECTOR3, max)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_ACTOR then
		if self:IsValid() == false then
			return
		end
		actor = actor or create_new_actor("actor", gui.PFMActorEditor.COLLECTION_MISC)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_SCENEBUILD then
		actor = actor or create_new_actor("scenebuild", gui.PFMActorEditor.COLLECTION_ENVIRONMENT)
		if actor == nil then
			return
		end
		local sceneC = self:CreateNewActorComponent(actor, "pfm_scene", false)
		sceneC:SetMemberValue("scenebuild", udm.TYPE_BOOLEAN, true)
		local project = args["project"]
		if project ~= nil then
			sceneC:SetMemberValue("project", udm.TYPE_STRING, project)
		end
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_GREENSCREEN then
		actor = actor or create_new_actor("greenscreen", gui.PFMActorEditor.COLLECTION_EFFECTS)
		if actor == nil then
			return
		end
		local modelC = self:CreateNewActorComponent(actor, "model", false)
		self:CreateNewActorComponent(actor, "render", false)
		modelC:SetMemberValue("model", udm.TYPE_STRING, "rect_unlit")
		local colorC = self:CreateNewActorComponent(actor, "color", false)
		colorC:SetMemberValue("color", udm.TYPE_VECTOR3, Color.Lime:ToVector())

		local pfmActorC = actor:FindComponent("pfm_actor")
		if pfmActorC ~= nil then
			pfmActorC:SetMemberValue("static", udm.TYPE_BOOLEAN, true)
		end
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER then
		actor = actor or create_new_actor("lightmapper", gui.PFMActorEditor.COLLECTION_BAKING)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_baked_lighting", false)
		self:CreateNewActorComponent(actor, "light_map_data_cache", false)
		self:CreateNewActorComponent(actor, "light_map", false)
		self:CreateNewActorComponent(actor, "pfm_cuboid_bounds", false)
		self:CreateNewActorComponent(actor, "pfm_region_carver", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE then
		actor = actor or create_new_actor("reflection_probe", gui.PFMActorEditor.COLLECTION_BAKING)
		if actor == nil then
			return
		end
		local c = self:CreateNewActorComponent(actor, "reflection_probe", false)
		c:SetMemberValue("iblStrength", udm.TYPE_FLOAT, 1.4)
		c:SetMemberValue("iblMaterial", udm.TYPE_STRING, "pbr/ibl/venice_sunset")
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY then
		actor = actor or create_new_actor("sky", gui.PFMActorEditor.COLLECTION_ENVIRONMENT)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "skybox", false)
		self:CreateNewActorComponent(actor, "pfm_sky", false)
		self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
			actor:ChangeModel("maps/empty_sky/skybox_3")
		end)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_FOG then
		actor = actor or create_new_actor("fog", gui.PFMActorEditor.COLLECTION_ENVIRONMENT)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "fog_controller", false)
		self:CreateNewActorComponent(actor, "color", false)
		local toggleC = self:CreateNewActorComponent(actor, "toggle", false)
		toggleC:SetMemberValue("enabled", udm.TYPE_BOOLEAN, true)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_DECAL then
		local pm = pfm.get_project_manager()
		local vp = util.is_valid(pm) and pm:GetViewport() or nil
		local cam = util.is_valid(vp) and vp:GetActiveCamera() or nil
		if util.is_valid(cam) then
			local pos = cam:GetEntity():GetPos()
			local dir = cam:GetEntity():GetForward()
			pose = pfm.calc_decal_target_pose(pos, dir)
		end

		actor = actor or create_new_actor("decal", gui.PFMActorEditor.COLLECTION_EFFECTS, pose)
		if actor == nil then
			return
		end
		local decalC = self:CreateNewActorComponent(actor, "decal", false)
		decalC:SetMemberValue("size", udm.TYPE_FLOAT, 20.0)
		decalC:SetMemberValue("material", udm.TYPE_STRING, "logo/test_spray")
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_MANAGER then
		actor = actor or create_new_actor("vr_manager", gui.PFMActorEditor.COLLECTION_VR)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_vr_manager", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_TRACKED_DEVICE then
		actor = actor or create_new_actor("vr_tracked_device", gui.PFMActorEditor.COLLECTION_VR)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "pfm_vr_tracked_device", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION then
		actor = actor or create_new_actor("ct_copy_location", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_copy_location", false)
		self:CreateNewActorComponent(actor, "constraint", false)
		self:CreateNewActorComponent(actor, "constraint_space", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION then
		actor = actor or create_new_actor("ct_copy_rotation", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_copy_rotation", false)
		self:CreateNewActorComponent(actor, "constraint", false)
		self:CreateNewActorComponent(actor, "constraint_space", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE then
		actor = actor or create_new_actor("ct_copy_scale", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_copy_scale", false)
		self:CreateNewActorComponent(actor, "constraint", false)
		self:CreateNewActorComponent(actor, "constraint_space", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE then
		actor = actor or create_new_actor("ct_limit_distance", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_limit_distance", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION then
		actor = actor or create_new_actor("ct_limit_location", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_limit_location", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION then
		actor = actor or create_new_actor("ct_limit_rotation", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_limit_rotation", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE then
		actor = actor or create_new_actor("ct_limit_scale", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_limit_scale", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT then
		actor = actor or create_new_actor("ct_look_at", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_look_at", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
		actor = actor or create_new_actor("ct_child_of", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "constraint_child_of", false)
		self:CreateNewActorComponent(actor, "constraint", false)
	elseif actorType == gui.PFMActorEditor.ACTOR_PRESET_TYPE_ANIMATION_DRIVER then
		actor = actor or create_new_actor("ct_driver", gui.PFMActorEditor.COLLECTION_CONSTRAINTS)
		if actor == nil then
			return
		end
		self:CreateNewActorComponent(actor, "animation_driver", false)
	end

	if newActor and updateActorComponents then
		self:UpdateActorComponents(actor)
	end
	return actor
end
