--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm.lua")
include("/pfm/pfm.lua")

pfm.register_log_category("sfm_converter")

local function log_sfm_project_debug_info(project)
	local numSessions = 0
	local numClips = 0
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numAnimationSets = 0
	for _,session in ipairs(project:GetSessions()) do
		numSessions = numSessions +1
		for _,clipSet in ipairs({session:GetClipBin(),session:GetMiscBin()}) do
			for _,clip in ipairs(clipSet) do
				numClips = numClips +1
				local subClipTrackGroup = clip:GetSubClipTrackGroup()
				for _,track in ipairs(subClipTrackGroup:GetTracks()) do
					numTracks = numTracks +1
					for _,filmClip in ipairs(track:GetFilmClips()) do
						numFilmClips = numFilmClips +1
						-- numAnimationSets = numAnimationSets +#filmClip:GetAnimationSets() -- TODO: Obsolete
					end
					numAudioClips = numAudioClips +#track:GetSoundClips()
				end
			end
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("SFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of sessions: " .. numSessions,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of clips: " .. numClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of tracks: " .. numTracks,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of sound clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of animation sets: " .. numAnimationSets,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

local function log_pfm_project_debug_info(project)
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numChannelClips = 0
	local numActors = 0
	local function iterate_film_clip(filmClip)
		numFilmClips = numFilmClips +1
		numActors = numActors +#filmClip:GetActorList()
		for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
			for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
				for _,filmClipOther in ipairs(track:GetFilmClips():GetTable()) do
					iterate_film_clip(filmClipOther)
				end
				numAudioClips = numAudioClips +#track:GetAudioClips()
				numChannelClips = numChannelClips +#track:GetChannelClips()
			end
		end
	end
	for _,session in ipairs(project:GetSessions()) do
		for _,clip in ipairs(session:GetClips():GetTable()) do
			iterate_film_clip(clip)
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("PFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of audio clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of channel clips: " .. numChannelClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of actors: " .. numActors,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

function sfm.is_udm_element_entity_component(el)
	local type = el:GetType()
	-- We only have to check the component types that have a corresponding type in SFM
	return (type == udm.ELEMENT_TYPE_PFM_MODEL or type == udm.ELEMENT_TYPE_PFM_CAMERA or type == udm.ELEMENT_TYPE_PFM_SPOT_LIGHT or type == udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM)
end

local sfm_attr_to_pragma_table = {
	[udm.ELEMENT_TYPE_PFM_CAMERA] = {
		["fieldofview"] = "fov"
	}
}

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmProject = sfm.import_scene(projectFilePath)
	if(sfmProject == nil) then return false end
	log_sfm_project_debug_info(sfmProject)

	local converter = sfm.ProjectConverter(sfmProject)
	local pfmProject = converter:GetPFMProject()
	log_pfm_project_debug_info(pfmProject)

	-- Clear the SFM session data from memory immediately
	converter = nil
	collectgarbage()

	return pfmProject
end
sfm.assign_generic_attribute = function(name,attr,pfmObj)
	local type = attr:GetType()
	local v = attr:GetValue()
	if(type == dmx.Attribute.TYPE_INT) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
	elseif(type == dmx.Attribute.TYPE_FLOAT) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_FLOAT,v))
	elseif(type == dmx.Attribute.TYPE_BOOL) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_BOOL,v))
	elseif(type == dmx.Attribute.TYPE_STRING) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_STRING,v))
	elseif(type == dmx.Attribute.TYPE_COLOR) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_COLOR,v))
	elseif(type == dmx.Attribute.TYPE_VECTOR3) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_VECTOR3,v))
	elseif(type == dmx.Attribute.TYPE_ANGLE) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_ANGLE,v))
	elseif(type == dmx.Attribute.TYPE_QUATERNION) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_QUATERNION,v))
	elseif(type == dmx.Attribute.TYPE_UINT64) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
	elseif(type == dmx.Attribute.TYPE_UINT8) then pfmObj:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
	else
		pfm.log("Unsupported attribute type '" .. dmx.type_to_string(type) .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
	end
end
function sfm.ProjectConverter:__init(sfmProject)
	self.m_sfmProject = sfmProject -- Input project
	self.m_pfmProject = pfm.create_project() -- Output project
	self.m_sfmElementToPfmElement = {} -- Cache of converted elements
	self.m_sfmObjectToPfmActor = {}
	self.m_ptConversions = {}

	for _,session in ipairs(sfmProject:GetSessions()) do
		self:ConvertSession(session)
	end
	collectgarbage()
	self:ApplyPostProcessing()
	pfm.log("Conversion of SFM project to PFM project has been completed!",pfm.LOG_CATEGORY_PFM_CONVERTER)
end
function sfm.ProjectConverter:GetSFMProject() return self.m_sfmProject end
function sfm.ProjectConverter:GetPFMProject() return self.m_pfmProject end
function sfm.ProjectConverter:AddParticleSystemDefinitionForConversion(pfmParticle,sfmSystemDef)
	table.insert(self.m_ptConversions,{pfmParticle,sfmSystemDef})
end
function sfm.ProjectConverter:GenerateEmbeddedParticleSystemFile()
	if(#self.m_ptConversions == 0) then return end
	local project = self:GetPFMProject()
	local projectName = project:GetName()
	local ptPrefix = projectName .. "_"
	local particleSystems = {}
	local function extract_children(particleSystems,t)
		local children = {}
		if(t.children ~= nil) then
			for name,child in pairs(t.children) do
				local delay = child.delay
				local childData = child.childData
				local newName = ptPrefix .. name
				table.insert(children,{
					delay = delay,
					childName = newName
				})
				extract_children(particleSystems,childData)
				particleSystems[newName] = childData
			end
		else
			-- No children?
		end
		t.children = children
	end
	for _,ptData in ipairs(self.m_ptConversions) do
		local pfmParticle = ptData[1]
		local sfmSystemDef = ptData[2]
		local name = sfmSystemDef:GetName()
		local dmxEl = sfmSystemDef:GetDMXElement()
		local keyValues = sfm.convert_dmx_particle_system(dmxEl)

		extract_children(particleSystems,keyValues)
		particleSystems[ptPrefix .. name] = keyValues

		pfmParticle:SetParticleSystemName(ptPrefix .. name)
	end

	-- Convert particle systems to Pragma
	for name,ptDef in pairs(particleSystems) do
		sfm.convert_particle_system(ptDef)
	end

	-- Save in Pragma's format
	local fileName = util.Path("sessions/" .. projectName .. "_instanced")
	-- console.print_table(particleSystems)
	local success = game.save_particle_system(fileName:GetString(),particleSystems)
	if(success == false) then
		pfm.log("Unable to save particle system file '" .. fileName:GetString() .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
	end
end
function sfm.ProjectConverter:ConvertSession(sfmSession)
	local pfmSession = self:ConvertNewElement(sfmSession)
	self.m_pfmProject:AddSession(pfmSession)
end
function sfm.ProjectConverter:GetPFMActor(pfmComponent)
	return self.m_sfmObjectToPfmActor[pfmComponent]
end
function sfm.ProjectConverter:CachePFMActor(pfmComponent,pfmActor)
	self.m_sfmObjectToPfmActor[pfmComponent] = pfmActor
end
function sfm.ProjectConverter:CreateActor(sfmComponent,pfmParentDag)
	local pfmComponent = self:ConvertNewElement(sfmComponent)
	local actor = self:GetPFMActor(pfmComponent) -- Check if this component has already been associated with an actor
	if(actor ~= nil) then return actor,false end
	actor = udm.create_element(udm.ELEMENT_TYPE_PFM_ACTOR)
	if(pfmParentDag ~= nil) then actor:ChangeName(pfmParentDag:GetName()) end -- pfmComponent:GetName()) -- TODO: Remove suffix (e.g. _model)
	actor:SetVisible(sfmComponent:IsVisible())

	local transformType = sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL
	-- TODO: Unsure about light sources; Confirm that this is correct!
	if(sfmComponent:GetType() == "DmeCamera" or sfmComponent:GetType() == "DmeGameParticleSystem" or sfmComponent:GetType() == "DmeProjectedLight") then transformType = sfm.ProjectConverter.TRANSFORM_TYPE_ALT end

	actor:SetTransformAttr(self:ConvertNewElement(sfmComponent:GetTransform(),transformType))
	actor:AddComponent(pfmComponent)
	self:CachePFMActor(pfmComponent,actor)

	if(sfmComponent:GetType() == "DmeGameModel") then
		-- Locate animation set associated with this actor
		local elFilmClip
		local filmClipParentLevel = math.huge
		local iterated = {}
		local function find_parent_film_clip(el,level)
			if(iterated[el] ~= nil) then return end
			iterated[el] = true
			if(el:GetType() == "DmeFilmClip") then
				if(level < filmClipParentLevel) then
					elFilmClip = el
					filmClipParentLevel = level
				end
				return
			end
			for _,parent in ipairs(el:GetParents()) do
				find_parent_film_clip(parent,level +1)
			end
		end
		find_parent_film_clip(sfmComponent,0)
		if(elFilmClip ~= nil) then
			local animSets = elFilmClip:GetAnimationSets()
			for _,animSet in ipairs(animSets) do
				if(util.is_same_object(animSet:GetGameModel(),sfmComponent)) then
					-- Found animation set. Now we'll move the operators from the animation set to our new actor.
					for _,op in ipairs(animSet:GetOperators()) do
						actor:GetOperatorsAttr():PushBack(self:ConvertNewElement(op))
					end
					break
				end
			end
		end
	end
	return actor,true
end
function sfm.ProjectConverter:GetPFMElement(element)
	return self.m_sfmElementToPfmElement[element]
end
local rotN90Yaw = EulerAngles(0,-90,0):ToQuaternion()
local function convert_root_bone_pos(pos)
	-- Root bones seem to be in a different coordinate system than everything else in the source engine?
	-- I don't know why that is the case, but we have to take it into account here.
	pos:Set(pos.x,-pos.y,-pos.z)

	if(isStaticModel == true) then return end
	-- Dynamic models and static models require different rotations, I am not sure why that is the case though.
	pos:Rotate(rotN90Yaw)
end
local rot180Pitch = EulerAngles(180,0,0):ToQuaternion()
local function convert_root_bone_rot(rot,isStaticModel)
	local newRot = rot180Pitch *rot
	rot:Set(newRot.w,newRot.x,newRot.y,newRot.z)

	if(isStaticModel == true) then return end
	-- Dynamic models and static models require different rotations, I am not sure why that is the case though.
	rot:Set(rotN90Yaw *rot)
end
local function convert_bone_transforms(filmClip,processedObjects,mdlMsgCache)
	for _,actor in ipairs(filmClip:GetActorList()) do
		if(processedObjects[actor] == nil) then
			processedObjects[actor] = true
			for _,component in ipairs(actor:GetComponents():GetTable()) do
				if(component:GetType() == udm.ELEMENT_TYPE_PFM_MODEL) then
					local mdlName = component:GetModelName()
					local mdl = game.load_model(mdlName)
					if(mdl == nil and mdlMsgCache[mdlName] == nil) then
						mdlMsgCache[mdlName] = true
						pfm.log("Unable to load model '" .. mdlName .. "'! Bone transforms for this model will be incorrect!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
					end
					for boneId,bone in ipairs(component:GetBoneList():GetTable()) do
						bone = bone:GetTarget()
						-- TODO: I'm not sure if the index actually corresponds to the bone id, keep this under observation
						local isRootBone = (mdl ~= nil) and mdl:IsRootBone(boneId -1) or false

						local t = bone:GetTransform()
						local pos = t:GetPosition():Copy()
						local rot = t:GetRotation():Copy()
						pos = sfm.convert_source_anim_set_position_to_pragma(pos)
						rot = sfm.convert_source_anim_set_rotation_to_pragma(rot)
						if(isRootBone) then
							convert_root_bone_pos(pos,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
							convert_root_bone_rot(rot,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
						end
						t:SetPosition(pos)
						t:SetRotation(rot)
					end
				end
			end
		end
	end
end
local function apply_post_processing(project,filmClip,processedObjects)
	-- Root bones in the source engine use a different coordinate system for whatever reason, so we
	-- have to do some additional conversion in post-processing.
	processedObjects = processedObjects or {}
	local mdlMsgCache = {}
	convert_bone_transforms(filmClip,processedObjects,mdlMsgCache)
	
	for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
		pfm.log("Processing track group '" .. tostring(trackGroup) .. "'...",pfm.LOG_CATEGORY_PFM_CONVERTER)
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			pfm.log("Processing track '" .. tostring(track) .. "'...",pfm.LOG_CATEGORY_PFM_CONVERTER)
			for _,channelClip in ipairs(track:GetChannelClips():GetTable()) do
				local channels = channelClip:GetChannels()
				local numChannels = #channels
				pfm.log("Processing channel clip '" .. tostring(channelClip) .. "' with " .. numChannels .. " channels...",pfm.LOG_CATEGORY_PFM_CONVERTER)

				-- Note: This is commented because it causes issues with some channels that use expression operators (e.g. fov/dof/etc.)
				-- I don't remember what this block was for in the first place, if any problems should occur by this being commented,
				-- uncomment it, but also make sure it works properly with expression operators!
				local i = 1
				while(i < numChannels) do
					local channel = channels:Get(i)
					local name = channel:GetName()
					-- We have no use for scaled channels, so we'll get rid of them to make things easier for us.
					if(name:sub(1,7) == "scaled_" and name:sub(-8) == "_channel") then
						local fromElement = channel:GetFromElement()
						local lo = fromElement:GetProperty("lo"):GetValue()
						local hi = fromElement:GetProperty("hi"):GetValue()
						for _,channelOther in ipairs(channelClip:GetChannels():GetTable()) do
							if(util.is_same_object(channelOther:GetToElement(),channel:GetFromElement())) then
								local log = channelOther:GetLog()
								for _,layer in ipairs(log:GetLayers():GetTable()) do
									local values = layer:GetValues()
									for i=1,#values do
										local value = math.lerp(lo,hi,values:Get(i))
										values:Set(i,value)
									end
								end
							end
						end
						channels:Remove(i)
						numChannels = numChannels -1
					else i = i +1 end
				end

				for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
					-- pfm.log("Processing channel '" .. tostring(channel) .. "'...",pfm.LOG_CATEGORY_PFM_CONVERTER)
					local toElement = channel:GetToElement()
					local toAttr = channel:GetToAttribute()
					if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_PFM_CAMERA) then
						if(string.compare(toAttr,"focalDistance",false)) then toElement:SetDepthOfFieldEnabled(true)
						elseif(string.compare(toAttr,"fov",false)) then
							local log = channel:GetLog()
							log:SetDefaultValue(sfm.convert_source_fov_to_pragma(log:GetDefaultValue()))
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									local values = layer:GetValues()
									for i,value in ipairs(values:GetTable()) do
										values:Set(i,sfm.convert_source_fov_to_pragma(value))
									end
								end
							end
						end
					end

					if(toElement ~= nil and sfm.is_udm_element_entity_component(toElement) and toElement:GetChild(toAttr) == nil) then
						-- Some attributes (like visibility) are stored in the SFM GameModel/Camera/etc. elements. In Pragma these are
						-- components of an actor, and these attributes are stored in the actor, not the components, so we have to
						-- redirect the reference to the actor.
						local actor = toElement:FindParent(function(p) return p:GetType() == udm.ELEMENT_TYPE_PFM_ACTOR end) or nil
						if(actor ~= nil) then
							channel:SetToElement(actor)
							toElement = actor
						end
					end

					local isPosTransform = (toAttr == "position")
					local isRotTransform = (toAttr == "rotation")
					if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM and (isPosTransform or isRotTransform)) then
						local isBoneTransform = false
						local pfmModel
						local pfmBone
						if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM) then
							local parent = toElement:FindParentElement()
							if(parent ~= nil and parent:GetType() == udm.ELEMENT_TYPE_PFM_BONE) then
								pfmBone = parent
								pfmModel = parent:GetModelComponent()
								isBoneTransform = (pfmModel ~= nil)
							end
						end
						if(isBoneTransform) then
							local boneName = pfmBone:GetName()
							local mdlName = pfmModel:GetModelName()
							local mdl = pfmModel:GetModel()
							local boneId = mdl and mdl:LookupBone(boneName) or -1
							local isRootBone = (boneId ~= -1) and mdl:IsRootBone(boneId) or false
							if(mdl == nil and mdlMsgCache[mdlName] == nil) then
								mdlMsgCache[mdlName] = true
								pfm.log("Unable to load model '" .. mdlName .. "'! Bone transforms for this model will be incorrect!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
							end
							if(mdl ~= nil and boneId == -1) then
								pfm.log("Unknown bone '" .. boneName .. "' of model '" .. mdlName .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
							end

							local log = channel:GetLog()
							if(isPosTransform) then
								local value = sfm.convert_source_anim_set_position_to_pragma(log:GetDefaultValue())
								if(isRootBone) then
									convert_root_bone_pos(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
								end
								log:SetDefaultValue(value)
							else
								local value = sfm.convert_source_anim_set_rotation_to_pragma(log:GetDefaultValue())
								if(isRootBone) then
									convert_root_bone_rot(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
								end
								log:SetDefaultValue(value)
							end
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									local values = layer:GetValues()
									for i=1,#values do
										local value = values:Get(i)
										if(isPosTransform) then
											value = sfm.convert_source_anim_set_position_to_pragma(value)
											if(isRootBone) then
												convert_root_bone_pos(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
											end
											values:Set(i,value)
										else
											value = sfm.convert_source_anim_set_rotation_to_pragma(value)
											if(isRootBone) then
												convert_root_bone_rot(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
											end
											values:Set(i,value)
										end
									end
								end
							end
						else
							local actor = toElement and toElement:FindParent(function(p) return p:GetType() == udm.ELEMENT_TYPE_PFM_ACTOR end) or nil
							local isCamera = false
							if(actor ~= nil) then
								for _,component in ipairs(actor:GetComponents():GetTable()) do
									if(component:GetType() == udm.ELEMENT_TYPE_PFM_CAMERA) then
										isCamera = true
										break
									end
								end
							end

							local log = channel:GetLog()
							if(isCamera) then
								if(isPosTransform) then
									log:SetDefaultValue(sfm.convert_source_transform_position_to_pragma(log:GetDefaultValue()))
								else
									log:SetDefaultValue(sfm.convert_source_transform_rotation_to_pragma2(log:GetDefaultValue()))
								end
							else
								if(isPosTransform) then
									log:SetDefaultValue(sfm.convert_source_transform_position_to_pragma(log:GetDefaultValue()))
								else
									log:SetDefaultValue(sfm.convert_source_transform_rotation_to_pragma_special(actor,log:GetDefaultValue()))
								end
							end
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									local values = layer:GetValues()
									for i=1,#values do
										local value = values:Get(i)
										-- TODO: Note: These conversions have been confirmed to work with
										-- the skydome test session, but it's unclear if they work
										-- in all cases! Keep it under observation!
										if(isCamera) then
											if(isPosTransform) then
												values:Set(i,sfm.convert_source_transform_position_to_pragma(value))
											else
												values:Set(i,sfm.convert_source_transform_rotation_to_pragma2(value))
											end
										else
											if(isPosTransform) then
												values:Set(i,sfm.convert_source_transform_position_to_pragma(value))
											else
												values:Set(i,sfm.convert_source_transform_rotation_to_pragma_special(actor,value))
											end
										end
									end
								end
							end
						end
					end
				end
			end
			for _,childFilmClip in ipairs(track:GetFilmClips():GetTable()) do
				apply_post_processing(project,childFilmClip,processedObjects)
			end
		end
	end
end
function sfm.ProjectConverter:ApplyPostProcessing()
	pfm.log("Applying post-processing...",pfm.LOG_CATEGORY_PFM_CONVERTER)
	local function iterate_session(el,type,callback,iterated)
		iterated = iterated or {}
		for name,child in pairs(el:GetChildren()) do
			if(child:IsElement() and iterated[child] == nil) then
				iterated[child] = true
				iterate_session(child,type,callback,iterated)
			end
			if(child:GetType() == type) then callback(child) end
		end
	end

	local project = self:GetPFMProject()
	for _,session in ipairs(project:GetSessions()) do
		iterate_session(session,udm.ELEMENT_TYPE_TRANSFORM,function(elTransform)
			-- The "overrideParent" attribute of some transforms may be pointing to an actor component, but
			-- we want it to point to the actor instead.
			local overrideParent = elTransform:GetOverrideParent()
			if(overrideParent ~= nil) then
				if(sfm.is_udm_element_entity_component(overrideParent)) then
					local overrideParentActor = overrideParent:FindParentElement()
					elTransform:SetOverrideParent((overrideParentActor ~= nil) and udm.create_reference(overrideParentActor) or nil)
				end
			end
		end)

		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			apply_post_processing(project,filmClip)
		end
	end
	pfm.log("Generating particle system files for embedded particle systems...",pfm.LOG_CATEGORY_PFM_CONVERTER)
	self:GenerateEmbeddedParticleSystemFile()

	-- SFM uses scalar scaling factors, Pragma uses 3D vectors, so we'll have to do some conversions.
	pfm.log("Converting scalar scaling factors to vectors...",pfm.LOG_CATEGORY_PFM_CONVERTER)
	sfm.convert_scale_factors_to_vectors(project)

	pfm.log("Fixing element references...",pfm.LOG_CATEGORY_PFM_CONVERTER)
	sfm.fix_element_references(project)

	-- Build scene graph
	local groups = {}
	project:GetUDMRootNode():FindElementsByType(udm.ELEMENT_TYPE_PFM_GROUP,groups)
	for _,group in ipairs(groups) do
		local elParent = group:FindParentElement(function(el) return el:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP end)
		if(elParent ~= nil) then
			-- We'll assume the 'group' element is a scene
			for _,actor in ipairs(group:GetActors():GetTable()) do
				actor:BuildSceneParents(group)
			end
		end
	end
end

local g_sfmToPfmConversion = {}
sfm.register_element_type_conversion = function(sfmType,pfmType,conversionFunction)
	if(sfmType == nil) then
		error("Invalid SFM type specified for conversion to PFM type '" .. util.get_type_name(pfmType) .. "'!")
	end
	if(pfmType == nil) then
		error("Invalid PFM type specified for conversion of SFM type '" .. util.get_type_name(sfmType) .. "'!")
	end
	g_sfmToPfmConversion[util.get_type_name(sfmType)] = {conversionFunction,pfmType}
end

sfm.get_pfm_conversion_data = function(sfmType)
	return g_sfmToPfmConversion[(type(sfmType) == "string") and sfmType or util.get_type_name(sfmType)]
end

sfm.get_pfm_conversion_function = function(sfmType)
	local data = sfm.get_pfm_conversion_data(sfmType)
	return data and data[1] or nil
end

function sfm.ProjectConverter:ConvertElement(sfmElement,pfmElement,...)
	local data = sfm.get_pfm_conversion_data(util.get_type_name(sfmElement))
	if(data == nil) then
		pfm.error("No PFM conversion function exists for SFM element of type '" .. util.get_type_name(sfmElement) .. "'!")
	end
	-- DMX element may be invalid if it wasn't set in the DMX project file
	--[[if(sfmElement:GetDMXElement() == nil) then
		pfm.error("Attempted to convert SFM element '" .. sfmElement:GetName() .. "' of type '" .. util.get_type_name(sfmElement) .. "', but was not loaded from DMX element!")
	end]]
	pfmElement:ChangeName(sfmElement:GetName())
	self.m_sfmElementToPfmElement[sfmElement] = pfmElement -- Has to be cached before conversion function is called!
	data[1](self,sfmElement,pfmElement,...)
end

function sfm.ProjectConverter:ConvertNewElement(sfmElement,...)
	if(self.m_sfmElementToPfmElement[sfmElement] ~= nil) then
		return self.m_sfmElementToPfmElement[sfmElement],false -- Return cached element
	end
	local data = sfm.get_pfm_conversion_data(util.get_type_name(sfmElement))
	if(data == nil) then
		pfm.error("No PFM conversion function exists for SFM element of type '" .. util.get_type_name(sfmElement) .. "'!")
	end
	local pfmType = data[2]
	if(type(pfmType) == "function") then
		pfmType = pfmType(self,sfmElement)
	end
	local pfmElement = pfmType()
	pfmElement:ChangeName(sfmElement:GetName())
	self:ConvertElement(sfmElement,pfmElement,...)
	return pfmElement,true
end

----------------------

include("project_converter")

sfm.register_element_type_conversion(sfm.Session,udm.PFMSession,function(converter,sfmSession,pfmSession)
	local activeClip = sfmSession:GetActiveClip()
	pfmSession:SetActiveClip(converter:ConvertNewElement(activeClip))
	pfmSession:SetSettings(converter:ConvertNewElement(sfmSession:GetSettings()))

	pfmSession:GetClipsAttr():PushBack(pfmSession:GetActiveClip())
	--[[for _,clipSet in ipairs({sfmSession:GetClipBin(),sfmSession:GetMiscBin()}) do
		for _,clip in ipairs(clipSet) do
			if(clip:GetType() == "DmeFilmClip") then
				pfmSession:GetClipsAttr():PushBack(converter:ConvertNewElement(clip))
			else
				pfm.log("Unsupported session clip type '" .. clip:GetType() .. "'! Skipping...",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
			end
		end
	end]]
end)

sfm.register_element_type_conversion(sfm.Settings,udm.PFMSettings,function(converter,sfmSettings,pfmSettings)
	pfmSettings:SetRenderSettings(converter:ConvertNewElement(sfmSettings:GetRenderSettings()))
end)

sfm.register_element_type_conversion(sfm.RenderSettings,udm.PFMRenderSettings,function(converter,sfmRenderSettings,pfmRenderSettings)
	pfmRenderSettings:SetFrameRate(sfmRenderSettings:GetFrameRate())
end)

sfm.register_element_type_conversion(sfm.BookmarkSet,udm.PFMBookmarkSet,function(converter,sfmBookmarkSet,pfmBookmarkSet)
	for _,bookmark in ipairs(sfmBookmarkSet:GetBookmarks()) do
		pfmBookmarkSet:GetBookmarks():PushBack(converter:ConvertNewElement(bookmark))
	end
end)

sfm.register_element_type_conversion(sfm.Bookmark,udm.PFMBookmark,function(converter,sfmBookmark,pfmBookmark)
	pfmBookmark:GetTimeRange():SetTime(sfmBookmark:GetTime())
	pfmBookmark:GetTimeRange():SetDuration(sfmBookmark:GetDuration())
	pfmBookmark:SetNote(sfmBookmark:GetNote())
end)

sfm.register_element_type_conversion(sfm.Material,udm.PFMMaterial,function(converter,sfmMaterial,pfmMaterial)
	pfmMaterial:SetMaterialName(sfmMaterial:GetMtlName())
	local baseTexture = sfmMaterial["Get$basetexture"](sfmMaterial)
	if(baseTexture ~= nil and #baseTexture > 0) then
		pfmMaterial:GetOverrideValuesAttr():Insert("albedo_map",udm.String(baseTexture))
	end
end)

sfm.register_element_type_conversion(sfm.Color,udm.Color,function(converter,sfmColor,pfmColor)
	pfmColor:SetValue(sfmColor:GetColor())
end)

sfm.register_element_type_conversion(sfm.TimeFrame,udm.PFMTimeFrame,function(converter,sfmTimeFrame,pfmTimeFrame)
	pfmTimeFrame:SetStart(sfmTimeFrame:GetStart())
	pfmTimeFrame:SetDuration(sfmTimeFrame:GetDuration())
	pfmTimeFrame:SetOffset(sfmTimeFrame:GetOffset())
	pfmTimeFrame:SetScale(sfmTimeFrame:GetScale())
end)

sfm.register_element_type_conversion(sfm.AnimationSet,udm.PFMAnimationSet,function(converter,sfmAnimSet,pfmAnimSet)
	-- TODO: This is obsolete!
	-- Flex controls
	--[[for _,sfmControl in ipairs(sfmAnimSet:GetControls()) do
		local pfmControl = converter:ConvertNewElement(sfmControl)
		pfmAnimSet:AddFlexControl(pfmControl)
	end
	
	-- Transform controls
	for _,sfmControl in ipairs(sfmAnimSet:GetTransformControls()) do
		local pfmControl = converter:ConvertNewElement(sfmControl)
		pfmAnimSet:AddTransformControl(pfmControl)
	end]]
end)

sfm.register_element_type_conversion(sfm.Track,udm.PFMTrack,function(converter,sfmTrack,pfmTrack)
	pfmTrack:SetMuted(sfmTrack:IsMuted())
	pfmTrack:SetVolume(sfmTrack:GetVolume())

	for _,clip in ipairs(sfmTrack:GetFilmClips()) do
		local pfmClip = converter:ConvertNewElement(clip)
		pfmTrack:GetFilmClipsAttr():PushBack(pfmClip)
	end
	
	for _,clip in ipairs(sfmTrack:GetSoundClips()) do
		local pfmClip = converter:ConvertNewElement(clip)
		pfmTrack:GetAudioClipsAttr():PushBack(pfmClip)
	end

	for _,clip in ipairs(sfmTrack:GetOverlayClips()) do
		local pfmClip = converter:ConvertNewElement(clip)
		pfmTrack:GetOverlayClipsAttr():PushBack(pfmClip)
	end
	
	for _,clip in ipairs(sfmTrack:GetChannelClips()) do
		local pfmClip = converter:ConvertNewElement(clip)
		pfmTrack:GetChannelClipsAttr():PushBack(pfmClip)
	end
end)

sfm.register_element_type_conversion(sfm.TrackGroup,udm.PFMTrackGroup,function(converter,sfmTrackGroup,pfmTrackGroup)
	pfmTrackGroup:SetVisible(sfmTrackGroup:IsVisible())
	pfmTrackGroup:SetMuted(sfmTrackGroup:IsMuted())
	for _,track in ipairs(sfmTrackGroup:GetTracks()) do
		local pfmTrack = converter:ConvertNewElement(track)
		pfmTrackGroup:GetTracksAttr():PushBack(pfmTrack)
	end
end)

sfm.register_element_type_conversion(sfm.Camera,udm.PFMCamera,function(converter,sfmCamera,pfmCamera)
	pfmCamera:SetFov(sfm.convert_source_fov_to_pragma(sfmCamera:GetFieldOfView()))
	pfmCamera:SetZNear(sfm.source_units_to_pragma_units(sfmCamera:GetZNear()))
	pfmCamera:SetZFar(sfm.source_units_to_pragma_units(sfmCamera:GetZFar()))
	pfmCamera:SetAspectRatio(sfm.ASPECT_RATIO)
	local aperture = sfmCamera:GetAperture()
	if(aperture > 0.0) then
		pfmCamera:SetDepthOfFieldEnabled(true)
		pfmCamera:SetFStop(sfm.convert_source_aperture_to_fstop(aperture))
	end
	pfmCamera:SetFocalDistance(sfm.source_units_to_pragma_units(sfmCamera:GetFocalDistance()))
	pfmCamera:SetSensorSize(36.0)
	pfmCamera:SetApertureBladeCount(3)
end)

sfm.register_element_type_conversion(sfm.Control,udm.PFMFlexControl,function(converter,sfmControl,pfmControl)
	pfmControl:SetValue(sfmControl:GetValue())
	pfmControl:SetLeftValue(sfmControl:GetLeftValue())
	pfmControl:SetRightValue(sfmControl:GetRightValue())

	local sfmChannel = sfmControl:GetChannel()
	if(sfmChannel ~= nil) then
		local pfmChannel = converter:ConvertNewElement(sfmChannel)
		pfmControl:SetChannelAttr(pfmChannel)
	end
	
	sfmChannel = sfmControl:GetRightValueChannel()
	if(sfmChannel ~= nil) then
		local pfmChannel = converter:ConvertNewElement(sfmChannel)
		pfmControl:SetRightValueChannelAttr(pfmChannel)
	end
	
	sfmChannel = sfmControl:GetLeftValueChannel()
	if(sfmChannel ~= nil) then
		local pfmChannel = converter:ConvertNewElement(sfmChannel)
		pfmControl:SetLeftValueChannelAttr(pfmChannel)
	end
end)

sfm.register_element_type_conversion(sfm.TransformControl,udm.PFMTransformControl,function(converter,sfmControl,pfmControl)
	local pos = sfmControl:GetValuePosition()
	local rot = sfmControl:GetValueOrientation()
	-- TODO: The Source Engine uses different coordinate systems depending on what we're dealing with.
	-- We need to determine whether or not this is a bone transform, but there's really no good way to do it, so
	-- we'll just check if this is one of the typical known non-bone transforms.
	-- TODO: This will fail if the name has been changed. Find a better way to do this!
	local nonBoneTransforms = {
		["rootTransform"] = true
	}
	local isBoneTransform = not (nonBoneTransforms[pfmControl:GetName()] or false)
	pfmControl:SetValuePosition(isBoneTransform and sfm.convert_source_anim_set_position_to_pragma(pos) or sfm.convert_source_transform_position_to_pragma(pos))
	pfmControl:SetValueRotation(isBoneTransform and sfm.convert_source_anim_set_rotation_to_pragma(rot) or sfm.convert_source_transform_rotation_to_pragma(rot))

	local sfmChannel = sfmControl:GetPositionChannel()
	if(sfmChannel ~= nil) then
		local pfmChannel = converter:ConvertNewElement(sfmChannel)
		pfmControl:SetPositionChannelAttr(pfmChannel)
	end
	
	sfmChannel = sfmControl:GetOrientationChannel()
	if(sfmChannel ~= nil) then
		local pfmChannel = converter:ConvertNewElement(sfmChannel)
		pfmControl:SetRotationChannelAttr(pfmChannel)
	end
end)

sfm.register_element_type_conversion(sfm.GameModel,udm.PFMModel,function(converter,sfmGameModel,pfmGameModel)
	local mdlName = sfmGameModel:GetPragmaModelPath()
	pfmGameModel:SetModelName(mdlName)
	pfmGameModel:SetSkin(sfmGameModel:GetSkin())
	pfmGameModel:SetBodyGroup(sfmGameModel:GetBody())

	local transformToBone = {}
	local function add_child_bones(sfmElement,parent)
		local type = sfmElement:GetType()
		if(type ~= "DmeDag" and type ~= "DmeGameModel") then
			pfm.log("Expected bones of element '" .. pfmGameModel:GetName() .. "' to be of type 'DmeDag', but bone with type '" .. sfmElement:GetType() .. "' found! This is currently not supported!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
			return
		end
		for _,child in ipairs(sfmElement:GetChildren()) do
			local bone = converter:ConvertNewElement(child)

			local name = string.remove_whitespace(child:GetName()) -- Format: "name (boneName)"
			local boneNameStart = name:find("%(")
			local boneNameEnd = name:match('.*()' .. "%)") -- Reverse find
			if(boneNameStart ~= nil and boneNameEnd ~= nil) then
				local boneName = name:sub(boneNameStart +1,boneNameEnd -1)
				bone:ChangeName(boneName)
			else pfm.log("Invalid format for bone name '" .. name .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING) end

			if(parent:GetType() == udm.ELEMENT_TYPE_PFM_MODEL) then parent:GetRootBonesAttr():PushBack(bone)
			else parent:AddChild(bone) end

			transformToBone[child:GetTransform()] = bone
			transformToBone[child:GetName()] = bone
			add_child_bones(child,bone)
		end
	end
	add_child_bones(sfmGameModel,pfmGameModel)

	for _,node in ipairs(sfmGameModel:GetBones()) do
		local pfmBone = transformToBone[node]
		if(pfmBone == nil) then
			-- Transform in bone list doesn't match transform in child hierarchy.
			-- This can happen if a rig is involved.
			-- In this case we'll attempt to find it by name, although this
			-- isn't reliable as the name can be changed arbitrarily.
			pfmBone = transformToBone[node:GetName()]
		end
		if(pfmBone ~= nil) then
			pfmGameModel:GetBoneListAttr():PushBack(udm.create_reference(pfmBone))
			-- Note: The transform in the bone hierarchy is not necessarily the actual final transform for the bone,
			-- we'll use the one from the bone list instead.
			pfmBone:SetProperty("transform",converter:ConvertNewElement(node))
		else
			pfm.log("Found bone '" .. node:GetName() .. "' in list of bones for actor '" .. sfmGameModel:GetName() .. "', but bone not found in child hierarchy of that actor! Animation data for this bone will not be available!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
	end

	for _,weight in ipairs(sfmGameModel:GetFlexWeights()) do
		pfmGameModel:GetFlexWeightsAttr():PushBack(udm.Float(weight))
	end

	for _,node in ipairs(sfmGameModel:GetGlobalFlexControllers()) do
		pfmGameModel:GetGlobalFlexControllersAttr():PushBack(converter:ConvertNewElement(node))
	end

	for _,name in ipairs(sfmGameModel:GetFlexNames()) do
		pfmGameModel:GetFlexControllerNamesAttr():PushBack(udm.String(name))
	end

	for _,material in ipairs(sfmGameModel:GetMaterials()) do
		pfmGameModel:GetMaterialOverridesAttr():PushBack(converter:ConvertNewElement(material))
	end
end)

sfm.register_element_type_conversion(sfm.GlobalFlexControllerOperator,udm.PFMGlobalFlexControllerOperator,function(converter,sfmOp,pfmOp)
	pfmOp:SetFlexWeight(sfmOp:GetFlexWeight())
	pfmOp:SetGameModelAttr(udm.create_reference(converter:ConvertNewElement(sfmOp:GetGameModel())))
end)

sfm.register_element_type_conversion(sfm.Channel,udm.PFMChannel,function(converter,sfmChannel,pfmChannel)
	local log = sfmChannel:GetLog()
	local pfmLog = converter:ConvertNewElement(log)
	pfmChannel:SetLogAttr(pfmLog)

	local toAttr = sfmChannel:GetToAttribute()
	if(toAttr == "orientation") then toAttr = "rotation" end
	pfmChannel:SetToAttribute(toAttr)

	-- To
	local toElement = sfmChannel:GetToElement()
	if(toElement == nil) then
		-- pfm.log("Unsupported 'to'-element for channel '" .. sfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
	else
		local pfmElement = converter:ConvertNewElement(toElement)
		pfmChannel:SetToElementAttr(udm.create_reference(pfmElement))

		-- Translate attribute
		if(pfmElement ~= nil and toAttr ~= nil) then
			local attrTranslationTable = sfm_attr_to_pragma_table[pfmElement:GetType()]
			if(attrTranslationTable ~= nil) then
				local toAttrL = toAttr:lower()
				if(attrTranslationTable[toAttrL] ~= nil) then
					toAttr = attrTranslationTable[toAttrL]
					pfmChannel:SetToAttribute(toAttr)
				end
			end
		end

		if(pfmElement:GetChild(toAttr) == nil) then
			pfm.log("Invalid to-attribute '" .. toAttr .. "' of element '" .. pfmElement:GetName() .. "' used for channel '" .. pfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
	end

	-- From
	local fromAttr = sfmChannel:GetFromAttribute()
	if(fromAttr == "orientation") then fromAttr = "rotation"
	elseif(fromAttr == "valueOrientation") then fromAttr = "valueRotation" end
	pfmChannel:SetFromAttribute(fromAttr)

	local fromElement = sfmChannel:GetFromElement()
	if(fromElement == nil) then
		-- pfm.log("Unsupported 'from'-element for channel '" .. sfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
	else
		local pfmElement = converter:ConvertNewElement(fromElement)
		pfmChannel:SetFromElementAttr(udm.create_reference(pfmElement))

		-- Translate attribute
		if(pfmElement ~= nil and fromAttr ~= nil) then
			local attrTranslationTable = sfm_attr_to_pragma_table[pfmElement:GetType()]
			if(attrTranslationTable ~= nil) then
				local toAttrL = fromAttr:lower()
				if(attrTranslationTable[toAttrL] ~= nil) then
					fromAttr = attrTranslationTable[toAttrL]
					pfmChannel:SetFromAttribute(fromAttr)
				end
			end
		end

		if(pfmElement:GetChild(fromAttr) == nil) then
			pfm.log("Invalid from-attribute '" .. fromAttr .. "' of element '" .. pfmElement:GetName() .. "' used for channel '" .. pfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
	end

	--[[local graphCurve = sfmChannel:GetGraphCurve()
	if(graphCurve ~= nil) then
		pfmChannel:SetGraphCurveAttr(converter:ConvertNewElement(graphCurve))
	end]]
end)

sfm.register_element_type_conversion(sfm.ExpressionOperator,udm.PFMExpressionOperator,function(converter,sfmOperator,pfmOperator)
	local varNames = {}
	for name,attr in pairs(sfmOperator:GetDMXElement():GetAttributes()) do
		if(name ~= "name" and name ~= "spewresult" and name ~= "result" and name ~= "expr" and name ~= "value") then
			table.insert(varNames,name)
			sfm.assign_generic_attribute(name,attr,pfmOperator)
		end
	end
	pfmOperator:SetExpression(sfm.convert_math_expression_to_pragma(sfmOperator:GetExpr(),varNames))
	pfmOperator:SetResult(sfmOperator:GetResult())
	pfmOperator:SetValue(sfmOperator:GetValue())
end)

-- TODO: Graph editor element is obsolete; Remove it!
sfm.register_element_type_conversion(sfm.GraphEditorCurve,udm.PFMGraphCurve,function(converter,sfmGraphCurve,pfmGraphCurve)
	for _,t in ipairs(sfmGraphCurve:GetKeysTime_0()) do
		pfmGraphCurve:GetKeyTimesAttr():PushBack(udm.Float(t))
	end
	for _,v in ipairs(sfmGraphCurve:GetKeysValue_0()) do
		pfmGraphCurve:GetKeyValuesAttr():PushBack(udm.Float(v))
	end
end)

sfm.register_element_type_conversion(sfm.LogLayer,udm.PFMLogList,function(converter,sfmLogLayer,pfmLogLayer)
	for _,t in ipairs(sfmLogLayer:GetTimes()) do
		pfmLogLayer:GetTimesAttr():PushBack(t)
	end
	local type = sfmLogLayer:GetType()
	if(type == "DmeFloatLogLayer") then type = util.VAR_TYPE_FLOAT
	elseif(type == "DmeVector3LogLayer") then type = util.VAR_TYPE_VECTOR
	elseif(type == "DmeQuaternionLogLayer") then type = util.VAR_TYPE_QUATERNION
	elseif(type == "DmeIntLogLayer") then type = util.VAR_TYPE_INT32
	elseif(type == "DmeBoolLogLayer") then type = util.VAR_TYPE_BOOL
	else
		console.print_warning("Unsupported log layer type: ",type)
		return
	end

	pfmLogLayer:GetValuesAttr():SetValueType(type)
	for _,v in ipairs(sfmLogLayer:GetValues()) do
		pfmLogLayer:GetValuesAttr():PushBack(v)
	end
end)

sfm.register_element_type_conversion(sfm.Log,udm.PFMLog,function(converter,sfmLog,pfmLog)
	for _,logLayer in ipairs(sfmLog:GetLayers()) do
		local pfmLogLayer = converter:ConvertNewElement(logLayer)
		pfmLog:AddLayer(pfmLogLayer)
	end
	for _,t in ipairs(sfmLog:GetBookmarks()) do
		pfmLog:GetBookmarks():PushBack(udm.Float(t))
	end
	pfmLog:SetUseDefaultValue(sfmLog:GetUsedefaultvalue())

	local dmxLog = sfmLog:GetDMXElement()
	if(dmxLog ~= nil) then
		local defaultValue = dmxLog:GetAttr("defaultvalue")
		local type = defaultValue:GetType()
		if(type == dmx.Attribute.TYPE_INT) then pfmLog:SetDefaultValueAttr(udm.Int(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_FLOAT) then pfmLog:SetDefaultValueAttr(udm.Float(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_BOOL) then pfmLog:SetDefaultValueAttr(udm.Bool(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_STRING) then pfmLog:SetDefaultValueAttr(udm.String(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_COLOR) then pfmLog:SetDefaultValueAttr(udm.Color(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_VECTOR3) then pfmLog:SetDefaultValueAttr(udm.Vector3(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_VECTOR2) then pfmLog:SetDefaultValueAttr(udm.Vector2(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_VECTOR4) then pfmLog:SetDefaultValueAttr(udm.Vector4(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_ANGLE) then pfmLog:SetDefaultValueAttr(udm.Angle(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_QUATERNION) then pfmLog:SetDefaultValueAttr(udm.Quaternion(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_UINT8) then pfmLog:SetDefaultValueAttr(udm.UInt8(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_UINT64) then pfmLog:SetDefaultValueAttr(udm.UInt64(defaultValue:GetValue()))
		elseif(type == dmx.Attribute.TYPE_MATRIX) then pfmLog:SetDefaultValueAttr(udm.Matrix(defaultValue:GetValue()))
		else
			local msg = "Unsupported default value type '" .. dmx.type_to_string(type) .. "' for log '" .. pfmLog:GetName() .. "'!"
			pfm.log(msg,pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_ERROR)
			error(msg)
		end
	else
		pfm.log("Log " .. tostring(sfmLog:GetName()) .. " does not have valid DMX element associated! Default value will be incorrect.",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
	end
end)

local function is_sfm_bone(el)
	for _,parent in ipairs(el:GetParents()) do
		local type = parent:GetType()
		if(type == "DmeGameModel" or (type == "DmeDag" and is_sfm_bone(parent))) then
			return true -- Element is a child of a DmeGameModel, which means it must be a bone
		end
	end
	return false
end

local function apply_override_parent(converter,sfmEl,pfmEl)
	if(sfmEl.GetOverrideParent == nil) then return end
	local overrideParent = sfmEl:GetOverrideParent()
	if(overrideParent == nil) then return end
	local pos = sfmEl:GetOverridePos() or false
	local rot = sfmEl:GetOverrideRot() or false
	local transform = pfmEl:GetTransform()
	transform:SetOverridePos(pos)
	transform:SetOverrideRot(rot)
	local pfmOverrideParent,isNewElement = converter:ConvertNewElement(overrideParent)
	-- Override parent is probably a game model, we'll just turn it into a reference.
	-- We'll turn it into a reference to the actor in post-processing.
	pfmOverrideParent = udm.create_reference(pfmOverrideParent)
	transform:SetOverrideParentAttr(pfmOverrideParent)
end

sfm.register_element_type_conversion(sfm.Dag,function(converter,sfmDag)
	if(is_sfm_bone(sfmDag)) then return udm.PFMBone end
	return udm.PFMGroup
end,function(converter,sfmDag,pfmEl)
	if(pfmEl:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then
		local pfmDag = pfmEl
		-- TODO: Unsure about sfm.ProjectConverter.TRANSFORM_TYPE_ALT, but has been confirmed to work with groups that contain particle
		-- systems! (e.g. session mtt_soldier_pyro_explosion_pos.dmx)
		pfmDag:SetTransformAttr(converter:ConvertNewElement(sfmDag:GetTransform(),sfm.ProjectConverter.TRANSFORM_TYPE_ALT))
		pfmDag:SetVisible(sfmDag:IsVisible())
		apply_override_parent(converter,sfmDag,pfmDag)
		for _,child in ipairs(sfmDag:GetChildren()) do
			local type = child:GetType()

			if(type == "DmeGameModel" or type == "DmeCamera" or type == "DmeProjectedLight" or type == "DmeGameParticleSystem") then
				local actor = converter:CreateActor(child,pfmDag)
				pfmDag:AddChild(udm.create_reference(actor))

				apply_override_parent(converter,child,actor)
			else
				local pfmElement = converter:ConvertNewElement(child)
				pfmDag:AddChild(udm.create_reference(pfmElement))

				apply_override_parent(converter,child,pfmElement)
			end
		end
		return
	end
	pfmEl:SetTransformAttr(converter:ConvertNewElement(sfmDag:GetTransform(),sfm.ProjectConverter.TRANSFORM_TYPE_NONE))
	apply_override_parent(converter,sfmDag,pfmEl)
	for _,child in ipairs(sfmDag:GetChildren()) do
		if(child:GetType() == "DmeDag") then
			pfmEl:GetChildBones():PushBack(converter:ConvertNewElement(child))
		else
			-- Note: Meet-the-Heavy has a case where a 'PFMParticleSystem' element is in the list of bones. TODO: What does that mean exactly?
			-- See also add_child_bones in sfm.GameModel conversion
			pfm.log("Expected bones of element '" .. pfmEl:GetName() .. "' to be of type 'DmeDag', but bone with type '" .. child:GetType() .. "' found! This is currently not supported!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
	end
end)

sfm.register_element_type_conversion(sfm.MaterialOverlayFXClip,udm.PFMOverlayClip,function(converter,sfmMat,pfmMat)
	pfmMat:SetTimeFrameAttr(converter:ConvertNewElement(sfmMat:GetTimeFrame()))
	local matName = sfmMat:GetMaterial()
	if(#matName > 0) then matName = file.remove_file_extension(matName) .. ".wmi" end
	pfmMat:SetMaterial(matName)
	pfmMat:SetLeft(sfmMat:GetLeft())
	pfmMat:SetTop(sfmMat:GetTop())
	pfmMat:SetWidth(sfmMat:GetWidth())
	pfmMat:SetHeight(sfmMat:GetHeight())
	pfmMat:SetFullscreen(sfmMat:IsFullscreen())
end)

sfm.register_element_type_conversion(sfm.ProjectedLight,udm.PFMSpotLight,function(converter,sfmLight,pfmLight)
	pfmLight:SetColor(sfmLight:GetColor())
	pfmLight:SetIntensity(sfmLight:GetIntensity())
	pfmLight:SetIntensityType(ents.LightComponent.INTENSITY_TYPE_CANDELA)
	pfmLight:SetFalloffExponent(1.0)
	pfmLight:SetMaxDistance(sfmLight:GetMaxDistance())
	pfmLight:SetCastShadows(sfmLight:ShouldCastShadows())
	pfmLight:SetVolumetric(sfmLight:IsVolumetric())
	pfmLight:SetVolumetricIntensity(sfmLight:GetVolumetricIntensity() *0.05)

	local fov = math.max(sfmLight:GetHorizontalFOV(),sfmLight:GetVerticalFOV())
	pfmLight:SetOuterConeAngle(fov)
	pfmLight:SetInnerConeAngle(fov *0.7)
end)

sfm.register_element_type_conversion(sfm.GameParticleSystem,udm.PFMParticleSystem,function(converter,sfmParticle,pfmParticle)
	pfmParticle:SetTimeScale(sfmParticle:GetSimulationTimeScale())
	pfmParticle:SetSimulating(sfmParticle:IsSimulating())
	pfmParticle:SetEmitting(sfmParticle:IsEmitting())
	local ptSystemName = sfmParticle:GetParticleSystemType()
	pfmParticle:SetParticleSystemName(ptSystemName)
	if(#ptSystemName == 0) then
		local ptSystemDef = sfmParticle:GetParticleSystemDefinition()
		local dmxEl = ptSystemDef:GetDMXElement()
		if(dmxEl ~= nil) then
			converter:AddParticleSystemDefinitionForConversion(pfmParticle,ptSystemDef)
		end
	end
	-- pfmParticle:SetDefinition(converter:ConvertNewElement())
	for _,cp in ipairs(sfmParticle:GetControlPoints()) do
		local pfmCp = converter:ConvertNewElement(cp)
		pfmParticle:GetControlPointsAttr():PushBack(pfmCp)
	end
end)

sfm.register_element_type_conversion(sfm.ParticleSystemDefinition,udm.PFMParticleSystemDefinition,function(converter,sfmParticleDef,pfmParticleDef)
	pfmParticleDef:SetMaxParticles(sfmParticleDef:GetMaxParticles())
	pfmParticleDef:SetMaterial(sfmParticleDef:GetMaterial())
	pfmParticleDef:SetRadius(sfmParticleDef:GetRadius())
	pfmParticleDef:SetLifetime(sfmParticleDef:GetLifetime())
	pfmParticleDef:SetColor(sfmParticleDef:GetColor())
	pfmParticleDef:SetSortParticles(sfmParticleDef:ShouldSortParticles())

	for _,renderer in ipairs(sfmParticleDef:GetRenderers()) do
		local pfmRenderer = converter:ConvertNewElement(renderer)
		pfmParticleDef:GetRenderersAttr():PushBack(pfmRenderer)
	end

	for _,operator in ipairs(sfmParticleDef:GetOperators()) do
		local pfmOperator = converter:ConvertNewElement(operator)
		pfmParticleDef:GetOperatorsAttr():PushBack(pfmOperator)
	end

	for _,initializer in ipairs(sfmParticleDef:GetInitializers()) do
		local pfmInitializer = converter:ConvertNewElement(initializer)
		pfmParticleDef:GetInitializersAttr():PushBack(pfmInitializer)
	end
end)

sfm.register_element_type_conversion(sfm.ParticleSystemOperator,udm.PFMParticleSystemOperator,function(converter,sfmParticleOp,pfmParticleOp)
	pfmParticleOp:SetOperatorName(sfmParticleOp:GetFunctionName())

	for name,attr in pairs(sfmParticleOp:GetDMXElement():GetAttributes()) do
		sfm.assign_generic_attribute(name,attr,pfmParticleOp)
	end
end)

sfm.register_element_type_conversion(sfm.ChannelClip,udm.PFMChannelClip,function(converter,sfmChannelClip,pfmChannelClip)
	pfmChannelClip:SetTimeFrameAttr(converter:ConvertNewElement(sfmChannelClip:GetTimeFrame()))
	for _,channel in ipairs(sfmChannelClip:GetChannels()) do
		pfmChannelClip:GetChannelsAttr():PushBack(converter:ConvertNewElement(channel))
	end
end)

sfm.register_element_type_conversion(sfm.SoundClip,udm.PFMAudioClip,function(converter,sfmSoundClip,pfmSoundClip)
	pfmSoundClip:SetSoundAttr(converter:ConvertNewElement(sfmSoundClip:GetSound()))
	pfmSoundClip:SetTimeFrameAttr(converter:ConvertNewElement(sfmSoundClip:GetTimeFrame()))
end)

sfm.register_element_type_conversion(sfm.Sound,udm.PFMSound,function(converter,sfmSound,pfmSound)
	pfmSound:SetSoundName(sfmSound:GetSoundName())
	pfmSound:SetVolume(sfmSound:GetVolume())
	pfmSound:SetPitch(sfmSound:GetPitch() /100.0)
	pfmSound:SetOrigin(sfm.convert_source_position_to_pragma(sfmSound:GetOrigin()))
	pfmSound:SetDirection(sfm.convert_source_normal_to_pragma(sfmSound:GetDirection()))
end)

sfm.ProjectConverter.TRANSFORM_TYPE_NONE = -1
sfm.ProjectConverter.TRANSFORM_TYPE_GENERIC = 0
sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL = 1
sfm.ProjectConverter.TRANSFORM_TYPE_BONE = 2
sfm.ProjectConverter.TRANSFORM_TYPE_ALT = 3
sfm.register_element_type_conversion(sfm.Transform,udm.Transform,function(converter,sfmTransform,pfmTransform,type)
	pfmTransform:ChangeName(sfmTransform:GetName())
	type = type or sfm.ProjectConverter.TRANSFORM_TYPE_GENERIC
	if(type == sfm.ProjectConverter.TRANSFORM_TYPE_GENERIC) then
		pfmTransform:SetPosition(sfm.convert_source_position_to_pragma(sfmTransform:GetPosition()))
		pfmTransform:SetRotation(sfm.convert_source_rotation_to_pragma(sfmTransform:GetOrientation()))
	elseif(type == sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL) then
		pfmTransform:SetPosition(sfm.convert_source_position_to_pragma(sfmTransform:GetPosition()))
		pfmTransform:SetRotation(sfm.convert_source_global_rotation_to_pragma(sfmTransform:GetOrientation()))
	elseif(type == sfm.ProjectConverter.TRANSFORM_TYPE_BONE) then
		pfmTransform:SetPosition(sfm.convert_source_anim_set_position_to_pragma(sfmTransform:GetPosition()))
		pfmTransform:SetRotation(sfm.convert_source_anim_set_rotation_to_pragma(sfmTransform:GetOrientation()))
	elseif(type == sfm.ProjectConverter.TRANSFORM_TYPE_ALT) then
		pfmTransform:SetPosition(sfm.convert_source_transform_position_to_pragma(sfmTransform:GetPosition()))
		pfmTransform:SetRotation(sfm.convert_source_transform_rotation_to_pragma2(sfmTransform:GetOrientation()))
	else
		pfmTransform:SetPosition(sfmTransform:GetPosition())
		pfmTransform:SetRotation(sfmTransform:GetOrientation())
	end

	local scale = sfmTransform:GetScale()
	pfmTransform:SetScale(Vector(scale,scale,scale))
end)

sfm.register_element_type_conversion(sfm.RigPointConstraintOperator,udm.PFMRigPointConstraintOperator,function(converter,sfmOp,pfmOp)
	pfmOp:SetSlaveAttr(converter:ConvertNewElement(sfmOp:GetSlave()))
	for _,target in ipairs(sfmOp:GetTargets()) do
		pfmOp:GetTargetsAttr():PushBack(converter:ConvertNewElement(target))
	end
end)

sfm.register_element_type_conversion(sfm.RigOrientConstraintOperator,udm.PFMRigRotationConstraintOperator,function(converter,sfmOp,pfmOp)
	pfmOp:SetSlaveAttr(converter:ConvertNewElement(sfmOp:GetSlave()))
	for _,target in ipairs(sfmOp:GetTargets()) do
		pfmOp:GetTargetsAttr():PushBack(converter:ConvertNewElement(target))
	end
end)

sfm.register_element_type_conversion(sfm.RigParentConstraintOperator,udm.PFMRigParentConstraintOperator,function(converter,sfmOp,pfmOp)
	pfmOp:SetSlaveAttr(converter:ConvertNewElement(sfmOp:GetSlave()))
	for _,target in ipairs(sfmOp:GetTargets()) do
		pfmOp:GetTargetsAttr():PushBack(converter:ConvertNewElement(target))
	end
end)

sfm.register_element_type_conversion(sfm.ConstraintTarget,udm.PFMConstraintTarget,function(converter,sfmTarget,pfmTarget)
	pfmTarget:SetTargetAttr(converter:ConvertNewElement(sfmTarget:GetTarget()))
	pfmTarget:SetTargetWeight(sfmTarget:GetTargetWeight())
	pfmTarget:SetOffset(sfm.convert_source_constraint_target_offset_to_pragma(sfmTarget:GetVecOffset()))
	pfmTarget:SetRotationOffset(sfm.convert_source_constraint_target_rotation_offset_to_pragma(sfmTarget:GetOOffset()))
end)

sfm.register_element_type_conversion(sfm.ConstraintSlave,udm.PFMConstraintSlave,function(converter,sfmSlave,pfmSlave)
	pfmSlave:SetTargetAttr(converter:ConvertNewElement(sfmSlave:GetTarget()))
	-- TODO: Transform coordinate system
	pfmSlave:SetPosition(sfm.convert_source_anim_set_position_to_pragma(sfmSlave:GetPosition()))
	pfmSlave:SetRotation(sfm.convert_source_anim_set_rotation_to_pragma(sfmSlave:GetOrientation()))
end)

sfm.register_element_type_conversion(sfm.RigHandle,udm.PFMRigHandle,function(converter,sfmHandle,pfmHandle)
	pfmHandle:SetTransformAttr(converter:ConvertNewElement(sfmHandle:GetTransform()))
end)
