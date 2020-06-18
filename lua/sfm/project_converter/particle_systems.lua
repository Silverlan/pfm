--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local sfmFieldIdToFieldName = {
	[0] = "pos",
	[1] = "life",
	[2] = nil, -- previous position
	[3] = "radius",

	[4] = "rot",
	-- [5] = "rotation_speed",
	[6] = "color",
	[7] = "alpha",

	[8] = "creation_time",
	-- [9] = "sequence_number",
	[10] = "length",
	-- [11] = "particle_id",

	[12] = "rot_yaw",
	-- [13] = "sequence_number_1",
	[14] = nil, -- HITBOX_INDEX
	[15] = nil, -- HITBOX_XYZ_RELATIVE

	-- [16] = "alpha_alternate", -- ALPHA2
	[17] = nil,
	[18] = nil,
	[19] = nil,

	[20] = nil,
	[21] = nil,
	[22] = nil,
	[23] = nil,

	[24] = nil,
	[25] = nil,
	[26] = nil,
	[27] = nil,

	[28] = nil,
	[29] = nil,
	[30] = nil,
	[31] = nil
}

local sfmOpFields = {
	["oscillate vector"] = {"oscillation field"},
	["oscillate scalar"] = {"oscillation field"},
	["remap initial scalar"] = {"input field","output field"},
	["remap scalar to vector"] = {"input field","output field"},
}

local sfmOperatorToPragma = {
	-- Initializers
	["position within sphere random"] = {
		pragmaName = "source_position_random_sphere",
		keyValues = {
			["bias in local system"] = "bias_in_local_system",
			["control_point_number"] = "control_point_id",
			["create in model"] = "create_in_model",
			["randomly distribute to highest supplied control point"] = "randomly_distribute_to_cp",
			["randomly distribution growth time"] = "random_distribution_growth_time"
		}
	},
	["velocity noise"] = {
		pragmaName = "source_velocity_random_noise",
		keyValues = {
			["control point number"] = "control_point_id",
			["time noise coordinate scale"] = "time_noise_coordinate_scale",
			["spatial noise coordinate scale"] = "spatial_noise_coordinate_scale",
			["time coordinate offset"] = "time_coordinate_offset",
			["spatial coordinate offset"] = "spatial_coordinate_offset",
			["absolute value"] = "absolute_value",
			["invert abs value"] = "invert_abs_value",
			["output minimum"] = "output_minimum",
			["output maximum"] = "output_maximum",
			["apply velocity in local space (0/1)"] = "apply_velocity_in_local_space"
		}
	},
	["position within box random"] = {
		pragmaName = "source_position_random_box",
		keyValues = {
			["control point number"] = "control_point_id"
		}
	},
	["position modify offset random"] = {
		pragmaName = "source_position_modify_random_offset",
		keyValues = {
			["control_point_number"] = "control_point_id",
			["offset min"] = "offset_min",
			["offset max"] = "offset_max",
			["offset in local space 0/1"] = "offset_in_local_space",
			["offset proportional to radius 0/1"] = "offset_proportional_to_radius"
		}
	},
	["trail length random"] = {
		pragmaName = "source_trail_length_random"
	},
	["color random"] = {
		pragmaName = "source_color_random",
		keyValues = {
			["tint control point"] = "tint_control_point",
			["tint clamp min"] = "tint_clamp_min",
			["tint clamp max"] = "tint_clamp_max",
			["tint update movement threshold"] = "tint_update_movement_threshold"
		}
	},
	["alpha random"] = {
		pragmaName = "source_alpha_random"
	},
	["rotation yaw flip random"] = {
		pragmaName = "source_rotation_yaw_flip_random",
		keyValues = {
			["flip percentage"] = "flip_percentage"
		}
	},
	["rotation random"] = {
		pragmaName = "source_rotation_random"
	},
	["sequence random"] = {
		pragmaName = "source_sequence_random"
	},
	["lifetime from sequence"] = {
		pragmaName = "source_lifetime_from_sequence",
		keyValues = {
			["frames per second"] = "frames_per_second"
		}
	},
	["lifetime random"] = {
		pragmaName = "source_lifetime_random"
	},
	["radius random"] = {
		pragmaName = "source_radius_random"
	},
	-- Operators
	["movement basic"] = {
		pragmaName = "source_movement_basic",
		keyValues = {
			["max constraint passes"] = "max_constraint_passes"
		}
	},
	["movement rotate particle around axis"] = {
		pragmaName = "source_movement_rotate_particle_around_axis",
		keyValues = {
			["rotation axis"] = "rotation_axis",
			["rotation rate"] = "rotation_rate",
			["control point"] = "control_point_id",
			["use local space"] = "use_local_space"
		}
	},
	["random force"] = {
		pragmaName = "source_force_random",
		keyValues = {
			["min force"] = "min_force",
			["max force"] = "max_force"
		}
	},
	["twist around axis"] = {
		pragmaName = "source_twist_around_axis",
		keyValues = {
			["amount of force"] = "amount_of_force",
			["twist axis"] = "twist_axis",
			["object local space axis 0/1"] = "local_space_axis"
		}
	},
	["pull towards control point"] = {
		pragmaName = "source_pull_towards_control_point",
		keyValues = {
			["amount of force"] = "amount_of_force",
			["falloff power"] = "falloff_power",
			["control point number"] = "control_point_id"
		}
	},
	["oscillate vector"] = {
		pragmaName = "source_oscillate_vector",
		keyValues = {
			["oscillation field"] = "oscillation_field",
			["oscillation rate min"] = "oscillation_rate_min",
			["oscillation rate max"] = "oscillation_rate_max",
			["oscillation frequency min"] = "oscillation_frequency_min",
			["oscillation frequency max"] = "oscillation_frequency_max",
			["proportional 0/1"] = "proportional",
			["start time min"] = "start_time_min",
			["start time max"] = "start_time_max",
			["end time min"] = "end_time_min",
			["end time max"] = "end_time_max",
			["start/end proportional"] = "start_end_proportional",
			["oscillation multiplier"] = "oscillation_multiplier",
			["oscillation start phase"] = "oscillation_start_phase"
		}
	},
	["oscillate scalar"] = {
		pragmaName = "source_oscillate_scalar",
		keyValues = {
			["oscillation field"] = "oscillation_field",
			["oscillation rate min"] = "oscillation_rate_min",
			["oscillation rate max"] = "oscillation_rate_max",
			["oscillation frequency min"] = "oscillation_frequency_min",
			["oscillation frequency max"] = "oscillation_frequency_max",
			["proportional 0/1"] = "proportional",
			["start time min"] = "start_time_min",
			["start time max"] = "start_time_max",
			["end time min"] = "end_time_min",
			["end time max"] = "end_time_max",
			["start/end proportional"] = "start_end_proportional",
			["oscillation multiplier"] = "oscillation_multiplier",
			["oscillation start phase"] = "oscillation_start_phase"
		}
	},
	["alpha fade and decay"] = {
		pragmaName = "source_alpha_fade_and_decay"
	},
	["color fade"] = {
		pragmaName = "source_color_fade"
	},
	["animation"] = {
		pragmaName = "source_animation",
		keyValues = {
			["animation rate"] = "animation_rate",
			["use animation rate as fps"] = "use_animation_rate_as_fps"
		}
	},
	["radius scale"] = {
		pragmaName = "source_radius_scale"
	},
	-- Renderers
	["render_animated_sprites"] = {
		pragmaName = "source_render_animated_sprites",
		keyValues = {
			["orientation control point"] = "control_point_id",
			["second sequence animation rate"] = "second_sequence_animation_rate"
		}
	},
	["render_sprite_trail"] = {
		pragmaName = "source_render_sprite_trail",
		keyValues = {
			["min length"] = "min_length",
			["max length"] = "max_length",
			["length fade in time"] = "length_fade_in_time",
			["animation rate"] = "animation_rate"
		}
	},
	["remap initial scalar"] = {
		pragmaName = "source_remap_initial_scalar",
		keyValues = {
			["emitter lifetime start time (seconds)"] = "emitter_lifetime_start_time",
			["emitter lifetime end time (seconds)"] = "emitter_lifetime_end_time",
			["input field"] = "input_field",
			["input minimum"] = "input_minimum",
			["input maximum"] = "input_maximum",
			["output field"] = "output_field",
			["output minimum"] = "output_minimum",
			["output maximum"] = "output_maximum",
			["output is scalar of initial random range"] = "output_scalar_of_initial_random_range",
			["only active within specified input range"] = "only_active_within_specified_input_range"
		}
	},
	["remap scalar to vector"] = {
		pragmaName = "source_remap_scalar_to_vector",
		keyValues = {
			["emitter lifetime start time (seconds)"] = "emitter_lifetime_start_time",
			["emitter lifetime end time (seconds)"] = "emitter_lifetime_end_time",
			["input field"] = "input_field",
			["input minimum"] = "input_minimum",
			["input maximum"] = "input_maximum",
			["output field"] = "output_field",
			["output minimum"] = "output_minimum",
			["output maximum"] = "output_maximum",
			["output is scalar of initial random range"] = "output_scalar_of_initial_random_range",
			["use local system"] = "use_local_system",
			["control_point_number"] = "control_point_id"
		}
	}
}

local function is_operator_type(type)
	return type == "initializers" or type == "operators" or type == "renderers" or type == "emitters" or type == "forces"
end

local function translate_color(strCol)
	local col = Color(strCol)
	--[[col.r = col.r *col.r *2.0
	col.g = col.g *col.g *2.0
	col.b = col.b *col.b *2.0]]
	-- Arbitrary factors, but they match the original Source Engine colors more closely (not sure why)
	--col.r = col.r *0.5
	--col.g = col.g *0.5
	--col.b = col.b *0.5
	return tostring(col)
end

local function read_key_values(el)
	local keyValues = {}
	for name,data in pairs(el:GetAttributes()) do
		keyValues[name] = tostring(data:GetValue())
	end
	return keyValues
end

local function read_element_array_data(attr)
	local arrayData = {}
	if(attr:GetType() ~= dmx.Attribute.TYPE_ELEMENT_ARRAY) then return end
	for _,attr in ipairs(attr:GetValue()) do
		local el = attr:GetValue()
		read_key_values(el)

		local keyValues = read_key_values(el)
		table.insert(arrayData,keyValues)
		arrayData[#arrayData].operatorType = (keyValues["functionName"] or el:GetName())
	end
	return arrayData
end

local function parse_particle_system_definition(el)
	local ptData = {
		keyValues = {}
	}
	for name,data in pairs(el:GetAttributes()) do
		if(name == "initializers") then
			ptData["initializers"] = read_element_array_data(data)
		elseif(name == "operators") then
			ptData["operators"] = read_element_array_data(data)
		elseif(name == "emitters") then
			ptData["emitters"] = read_element_array_data(data)
		elseif(name == "forces") then
			ptData["forces"] = read_element_array_data(data)
		elseif(name == "constraints") then
			ptData["constraints"] = read_element_array_data(data)
		elseif(name == "renderers") then
			ptData["renderers"] = read_element_array_data(data)
		elseif(name == "children") then
			ptData.children = {}
			if(data:GetType() == dmx.Attribute.TYPE_ELEMENT_ARRAY) then
				for _,attr in ipairs(data:GetValue()) do
					if(attr:GetType() == dmx.Attribute.TYPE_ELEMENT) then
						table.insert(ptData.children,attr:GetValue())
					end
				end
			end
		else
			ptData.keyValues[name] = tostring(data:GetValue())
		end
	end
	return ptData
end

local function load_particle_systems(fileName)
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	local dmxData = dmx.load(f)
	f:Close()
	if(dmxData == false) then return false end

	local root = dmxData:GetRootAttribute()
	if(root:GetType() ~= dmx.Attribute.TYPE_ELEMENT) then return false end
	local particleSystems = {}
	local el = root:GetValue()
	local particleSystemDefinitions = el:GetAttrV("particleSystemDefinitions")
	for _,ptDef in ipairs(particleSystemDefinitions) do
		if(ptDef:GetType() == dmx.Attribute.TYPE_ELEMENT) then
			local elPt = ptDef:GetValue()
			if(elPt:GetType() == "DmeParticleSystemDefinition") then
				local ptData = parse_particle_system_definition(elPt)
				local ptName = elPt:GetName()
				particleSystems[ptName] = ptData
			end
		end
	end
	for name,ptData in pairs(particleSystems) do
		for k,v in pairs(ptData.keyValues) do
			if(is_operator_type(k) == false) then
				ptData[k] = v
			end
		end
		ptData.keyValues = nil

		if(ptData.children ~= nil) then
			for i,child in ipairs(ptData.children) do
				local childName = child:GetAttrV("child"):GetName()
				if(particleSystems[childName] ~= nil) then
					ptData.children[i] = {
						childName = childName,
						delay = child:GetAttrV("delay")
					}
				else
					pfm.log("Child particle system '" .. childName .. "' of particle system '" .. name .. "' not found in list of particle systems!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
				end
			end
		end
	end
	return particleSystems
end

sfm.convert_particle_system = function(ptData)
	local tVectorKeyValues = {
		initializers = {
			["position modify offset random"] = {"offset min","offset max"},
			["position within box random"] = {"min","max"},
			["position within sphere random"] = {"distance_bias","distance_bias_absolute_value","speed_in_local_coordinate_system_min","speed_in_local_coordinate_system_max"},
			["velocity noise"] = {"spatial coordinate offset","absolute value","invert abs value","output minimum","output maximum"},
			["position modify offset random"] = {"offset min","offset max"},
			["remap scalar to vector"] = {"output minimum","output maximum"}
		},
		operators = {
			["movement basic"] = {"gravity"},
			["movement rotate particle around axis"] = {"rotation axis"},
			["oscillate vector"] = {"oscillation rate min","oscillation rate max","oscillation frequency min","oscillation frequency max"}
		},
		forces = {
			["twist around axis"] = {"twist axis"},
			["random force"] = {"min force","max force"}
		}
	}
	local tColorKeyValues = {
		initializers = {
			["color random"] = {"color1","color2"}
		},
		operators = {
			["color fade"] = {"color_fade"}
		}
	}

	local renameTable = {
		["alpha_fade"] = "Alpha Fade and Decay",
		["alpha_fade_in_random"] = "Alpha Fade In Random",
		["alpha_fade_out_random"] = "Alpha Fade Out Random",
		["basic_movement"] = "Movement Basic",
		["color_fade"] = "Color Fade",
		["controlpoint_light"] = "Color Light From Control Point",
		["Dampen Movement Relative to Control Point"] = "Movement Dampen Relative to Control Point",
		["Distance Between Control Points Scale"] = "Remap Distance Between Two Control Points to Scalar",
		["Distance to Control Points Scale"] = "Remap Distance to Control Point to Scalar",
		["lifespan_decay"] = "Lifespan Decay",
		["lock to bone"] = "Movement Lock to Bone",
		["postion_lock_to_controlpoint"] = "Movement Lock to Control Point",
		["maintain position along path"] = "Movement Maintain Position Along Path",
		["Match Particle Velocities"] = "Movement Match Particle Velocities",
		["Max Velocity"] = "Movement Max Velocity",
		["noise"] = "Noise Scalar",
		["vector noise"] = "Noise Vector",
		["oscillate_scalar"] = "Oscillate Scalar",
		["oscillate_vector"] = "Oscillate Vector",
		["Orient Rotation to 2D Direction"] = "Rotation Orient to 2D Direction",
		["radius_scale"] = "Radius Scale",
		["Random Cull"] = "Cull Random",
		["remap_scalar"] = "Remap Scalar",
		["rotation_movement"] = "Rotation Basic",
		["rotation_spin"] = "Rotation Spin Roll",
		["rotation_spin yaw"] = "Rotation Spin Yaw",
		["alpha_random"] = "Alpha Random",
		["color_random"] = "Color Random",
		["create from parent particles"] = "Position From Parent Particles",
		["Create In Hierarchy"] = "Position In CP Hierarchy",
		["random position along path"] = "Position Along Path Random",
		["random position on model"] = "Position on Model Random",
		["sequential position along path"] = "Position Along Path Sequential",
		["position_offset_random"] = "Position Modify Offset Random",
		["position_warp_random"] = "Position Modify Warp Random",
		["position_within_box"] = "Position Within Box Random",
		["position_within_sphere"] = "Position Within Sphere Random",
		["Inherit Velocity"] = "Velocity Inherit from Control Point",
		["Initial Repulsion Velocity"] = "Velocity Repulse from World",
		["Initial Velocity Noise"] = "Velocity Noise",
		["Initial Scalar Noise"] = "Remap Noise to Scalar",
		["Lifespan from distance to world"] = "Lifetime from Time to Impact",
		["Pre-Age Noise"] = "Lifetime Pre-Age Noise",
		["lifetime_random"] = "Lifetime Random",
		["radius_random"] = "Radius Random",
		["random yaw"] = "Rotation Yaw Random",
		["Randomly Flip Yaw"] = "Rotation Yaw Flip Random",
		["rotation_random"] = "Rotation Random",
		["rotation_speed_random"] = "Rotation Speed Random",
		["sequence_random"] = "Sequence Random",
		["second_sequence_random"] = "Sequence Two Random",
		["trail_length_random"] = "Trail Length Random",
		["velocity_random"] = "Velocity Random"
	}
	for k,v in pairs(renameTable) do
		renameTable[k] = nil
		renameTable[k:lower()] = v:lower()
	end

	-- Lower keyvalues
	local function to_lower_keys(t)
		for k,v in pairs(t) do
			if(k ~= "operatorType") then
				t[k] = nil
				t[k:lower()] = v
			end
		end
	end

	for k,v in pairs(ptData) do
		if(is_operator_type(k)) then
			for _,opData in ipairs(v) do
				to_lower_keys(opData)
			end
		else
			ptData[k] = nil
			ptData[k:lower()] = v
		end
	end

	for name,data in pairs(ptData) do
		if(is_operator_type(name)) then
			for _,keyValues in ipairs(data) do
				local opName = keyValues.operatorType
				opName = opName:lower()
				opName = renameTable[opName] or opName
				keyValues.operatorType = opName
			end
		end
	end
	-- Convert coordinate system for vector attributes
	for opCat,t in pairs(tVectorKeyValues) do
		if(ptData[opCat] ~= nil) then
			for vectorOpType,vectorOpKeyValues in pairs(t) do
				for _,opData in ipairs(ptData[opCat]) do
					if(opData.operatorType == vectorOpType) then
						for _,key in ipairs(vectorOpKeyValues) do
							if(opData[key] ~= nil) then
								local v = vector.create_from_string(opData[key])
								v = sfm.convert_source_position_to_pragma(v)
								opData[key] = tostring(v)
							end
						end
					end
				end
			end
		end
	end

	-- Move forces to operators
	if(ptData.forces) then
		ptData.operators = ptData.operators or {}
		for _,v in ipairs(ptData.forces) do
			table.insert(ptData.operators,v)
		end
		ptData.forces = nil
	end
	--

	-- Convert colors
	if(ptData["color"] ~= nil) then ptData["color"] = translate_color(ptData["color"]) end
	for opCat,t in pairs(tColorKeyValues) do
		if(ptData[opCat] ~= nil) then
			for vectorOpType,vectorOpKeyValues in pairs(t) do
				for _,opData in ipairs(ptData[opCat]) do
					if(opData.operatorType == vectorOpType) then
						for _,key in ipairs(vectorOpKeyValues) do
							if(opData[key] ~= nil) then
								opData[key] = translate_color(opData[key])
							end
						end
					end
				end
			end
		end
	end

	-- Note: Particle systems in Source have a default lifetime of 1,
	-- however this lifetime has no effect unless a "decay" operator is added.
	-- Pragma kills the particle regardless of such an operator, so we'll need a minor work-around.
	local defaultLifetime = math.huge
	if(ptData.operators ~= nil and ptData.operators["alpha fade and decay"] ~= nil) then
		defaultLifetime = 1.0
	end

	if(ptData.renderers ~= nil) then
		for _,renderer in ipairs(ptData.renderers) do
			if(renderer.operatorType == "render_animated_sprites") then
				local animKeys = {
					"animation rate","animation_fit_lifetime","use animation rate as fps"
				}
				table.insert(ptData.operators,{operatorType = "animation"})
				local opAnim = ptData.operators[#ptData.operators]
				for _,k in ipairs(animKeys) do
					opAnim[k] = renderer[k]
					renderer[k] = nil
				end
				break
			end
		end
	end

	local emissionRate = 100
	local particleLimit
	if(ptData.emitters ~= nil) then
		for _,emitter in ipairs(ptData.emitters) do
			local opType = emitter.operatorType
			if(opType == "emit_continuously") then
				emissionRate = tonumber(emitter["emission_rate"])
			elseif(opType == "emit_instantaneously") then
				particleLimit = emitter["num_to_emit"]
				-- Just emit everything immediately
				emissionRate = 10000000
			end
		end
	end

	local sortParticles = false
	if(ptData["sort particles"] ~= nil) then
		sortParticles = toboolean(ptData["sort particles"])
	end

	local material = util.Path(ptData["material"])
	material:RemoveFileExtension()
	ptData["maxparticles"] = ptData["max_particles"]
	ptData["material"] = material:GetString()
	ptData["lifetime"] = tostring(defaultLifetime)
	ptData["sort_particles"] = sortParticles and "1" or "0"
	ptData["emission_rate"] = tostring(emissionRate)
	if(particleLimit ~= nil) then ptData["limit_particle_count"] = tostring(particleLimit) end
	-- ptData["loop"] = "1"
	-- ptData["auto_simulate"] = "1"
	-- ptData["transform_with_emitter"] = "1"
	-- ptData["alpha_mode"] = "additive"

	-- ptData["radius"] = ptData["radius"]
	-- ptData["color"] = ptData["color"]

	ptData["max_particles"] = nil
	ptData["sort particles"] = nil

	for k,v in pairs(ptData) do
		if(is_operator_type(k)) then
			for _,opData in ipairs(v) do
				local opName = opData.operatorType
				if(sfmOpFields[opName] ~= nil) then
					for _,fieldKey in ipairs(sfmOpFields[opName]) do
						local fieldId = tonumber(opData[fieldKey])
						local fieldName = sfmFieldIdToFieldName[fieldId]
						if(fieldName == nil) then pfm.log("Unsupported oscillation field id: " .. fieldId .. "!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
						else opData[fieldKey] = fieldName end
					end
				end
			end
		end
	end

	-- Convert operator and keyvalue names
	for opType,operators in pairs(ptData) do
		if(is_operator_type(opType)) then
			for _,opData in ipairs(operators) do
				local opName = opData.operatorType
				if(sfmOperatorToPragma[opName] ~= nil) then
					local translationData = sfmOperatorToPragma[opName]
					if(translationData.pragmaName ~= nil) then
						opData.operatorType = translationData.pragmaName
					end
					if(translationData.keyValues ~= nil) then
						for k,v in pairs(opData) do
							if(translationData.keyValues[k] ~= nil) then
								opData[k] = nil
								opData[translationData.keyValues[k]] = v
							end
						end
					end
				end
			end
		end
	end
end

sfm.convert_particle_systems = function(pcfFile)
	local particleSystems = load_particle_systems(pcfFile)
	if(particleSystems == false) then return false end

	for name,ptDef in pairs(particleSystems) do
		sfm.convert_particle_system(ptDef)
	end

	-- Save in Pragma's format
	local pragmaFileName = util.Path(pcfFile)
	pragmaFileName:RemoveFileExtension()
	pragmaFileName = pragmaFileName:GetFileName()
	local success = game.save_particle_system(pragmaFileName,particleSystems)
	if(success == false) then
		pfm.log("Unable to save particle system file '" .. pragmaFileName .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
	end
	return particleSystems
end

local function dmx_value_to_string(val)
	local type = val:GetType()
	if(type == dmx.Attribute.TYPE_STRING) then return val:GetValue() end
	if(
		type == dmx.Attribute.TYPE_INT or type == dmx.Attribute.TYPE_FLOAT or type == dmx.Attribute.TYPE_VECTOR2 or type == dmx.Attribute.TYPE_VECTOR3 or type == dmx.Attribute.TYPE_VECTOR4 or
		type == dmx.Attribute.TYPE_ANGLE or type == dmx.Attribute.TYPE_COLOR or type == dmx.Attribute.TYPE_UINT64 or type == dmx.Attribute.TYPE_UINT8
	) then
		return tostring(val:GetValue())
	end
	if(type == dmx.Attribute.TYPE_BOOL) then return val:GetValue() and "1" or "0" end
	if(type == dmx.Attribute.TYPE_QUATERNION) then
		val = val:GetValue()
		return val.w .. " " .. val.x .. " " .. val.y .. " " .. val.z
	end
	console.print_warning("Unhandled type '" .. dmx.type_to_string(type) .. "'!")
end

sfm.convert_dmx_particle_system = function(el,keyValues)
	keyValues = keyValues or {}
	for k,v in pairs(el:GetAttributes()) do
		if(v:GetType() == dmx.Attribute.TYPE_ELEMENT_ARRAY) then
			keyValues[k] = {}
			for _,el in ipairs(v:GetValue()) do
				el = el:GetValue()
				if(el ~= nil) then
					if(k == "children") then
						local ptData = el:GetAttrV("child")
						local delay = el:GetAttrV("delay")
						local name = ptData:GetName() -- el:GetName()
						keyValues[k][name] = {
							delay = delay,
							childData = {}
						}
						sfm.convert_dmx_particle_system(ptData,keyValues[k][name].childData)
					elseif(is_operator_type(k)) then
						local name = el:GetName()
						keyValues[k] = keyValues[k] or {}
						table.insert(keyValues[k],{
							operatorType = name
						})
						sfm.convert_dmx_particle_system(el,keyValues[k][#keyValues[k]])
					else
						local name = el:GetName()
						keyValues[k][name] = {}
						sfm.convert_dmx_particle_system(el,keyValues[k][name])
					end
				end
			end
		else
			keyValues[k] = dmx_value_to_string(v)
		end
	end
	return keyValues
end
