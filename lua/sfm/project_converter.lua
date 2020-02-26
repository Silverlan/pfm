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
		numActors = numActors +#filmClip:GetActors()
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

local function is_udm_element_entity_component(el)
	local type = el:GetType()
	-- We only have to check the component types that have a corresponding type in SFM
	return (type == udm.ELEMENT_TYPE_PFM_MODEL or type == udm.ELEMENT_TYPE_PFM_CAMERA or type == udm.ELEMENT_TYPE_PFM_SPOT_LIGHT or type == udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM)
end

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmProject = sfm.import_scene(projectFilePath)
	if(sfmProject == nil) then return false end
	log_sfm_project_debug_info(sfmProject)

	local converter = sfm.ProjectConverter(sfmProject)
	local pfmProject = converter:GetPFMProject()
	log_pfm_project_debug_info(pfmProject)
	return pfmProject
end
function sfm.ProjectConverter:__init(sfmProject)
	self.m_sfmProject = sfmProject -- Input project
	self.m_pfmProject = pfm.create_project() -- Output project
	self.m_sfmElementToPfmElement = {} -- Cache of converted elements
	self.m_sfmObjectToPfmActor = {}

	for _,session in ipairs(sfmProject:GetSessions()) do
		self:ConvertSession(session)
	end
	self:ApplyPostProcessing()
	pfm.log("Conversion of SFM project to PFM project has been completed!",pfm.LOG_CATEGORY_PFM_CONVERTER)
end
function sfm.ProjectConverter:GetSFMProject() return self.m_sfmProject end
function sfm.ProjectConverter:GetPFMProject() return self.m_pfmProject end
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
function sfm.ProjectConverter:CreateActor(sfmComponent)
	local pfmComponent = self:ConvertNewElement(sfmComponent)
	local actor = self:GetPFMActor(pfmComponent) -- Check if this component has already been associated with an actor
	if(actor ~= nil) then return actor,false end
	actor = udm.create_element(udm.ELEMENT_TYPE_PFM_ACTOR)
	actor:ChangeName(pfmComponent:GetName()) -- TODO: Remove suffix (e.g. _model)
	actor:SetVisible(sfmComponent:IsVisible())

	local transformType = sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL
	if(sfmComponent:GetType() == "DmeCamera") then transformType = sfm.ProjectConverter.TRANSFORM_TYPE_ALT end

	actor:SetTransformAttr(self:ConvertNewElement(sfmComponent:GetTransform(),transformType))
	actor:AddComponent(pfmComponent)
	self:CachePFMActor(pfmComponent,actor)
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
	for _,actor in ipairs(filmClip:GetActors():GetTable()) do
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
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			for _,channelClip in ipairs(track:GetChannelClips():GetTable()) do
				for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
					local toElement = channel:GetToElement()
					local toAttr = channel:GetToAttribute()

					if(toElement ~= nil and is_udm_element_entity_component(toElement)) then
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
							local mdl = game.load_model(mdlName)
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
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									for _,value in ipairs(layer:GetValues():GetTable()) do
										if(isPosTransform) then
											value:Set(sfm.convert_source_anim_set_position_to_pragma(value))
											if(isRootBone) then
												convert_root_bone_pos(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
											end
										else
											value:Set(sfm.convert_source_anim_set_rotation_to_pragma(value))
											if(isRootBone) then
												convert_root_bone_rot(value,mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE))
											end
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
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									for _,value in ipairs(layer:GetValues():GetTable()) do
										-- TODO: Note: These conversions have been confirmed to work with
										-- the skydome test session, but it's unclear if they work
										-- in all cases! Keep it under observation!
										if(isCamera) then
											if(isPosTransform) then
												value:Set(sfm.convert_source_transform_position_to_pragma(value))
											else
												value:Set(sfm.convert_source_transform_rotation_to_pragma2(value))
											end
										else
											if(isPosTransform) then
												value:Set(sfm.convert_source_transform_position_to_pragma(value))
											else
												value:Set(sfm.convert_source_transform_rotation_to_pragma_special(actor,value))
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
				if(is_udm_element_entity_component(overrideParent)) then
					local overrideParentActor = overrideParent:FindParentElement()
					elTransform:SetOverrideParent((overrideParentActor ~= nil) and udm.create_reference(overrideParentActor) or nil)
				end
			end
		end)

		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			apply_post_processing(project,filmClip)
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

	for _,clipSet in ipairs({sfmSession:GetClipBin(),sfmSession:GetMiscBin()}) do
		for _,clip in ipairs(clipSet) do
			if(clip:GetType() == "DmeFilmClip") then
				pfmSession:GetClipsAttr():PushBack(converter:ConvertNewElement(clip))
			else
				pfm.log("Unsupported session clip type '" .. clip:GetType() .. "'! Skipping...",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
			end
		end
	end
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
	pfmCamera:SetFov(sfmCamera:GetFieldOfView())
	pfmCamera:SetZNear(sfm.source_units_to_pragma_units(sfmCamera:GetZNear()))
	pfmCamera:SetZFar(sfm.source_units_to_pragma_units(sfmCamera:GetZFar()))
	pfmCamera:SetAspectRatio(16.0 /9.0)
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
	-- TODO: Obsolete? We don't need animation set information anymore
	local pos = sfmControl:GetValuePosition()
	local rot = sfmControl:GetValueOrientation()
	local isBoneTransform = true -- TODO
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
			add_child_bones(child,bone)
		end
	end
	add_child_bones(sfmGameModel,pfmGameModel)

	for _,node in ipairs(sfmGameModel:GetBones()) do
		local pfmBone = transformToBone[node]
		pfmGameModel:GetBoneListAttr():PushBack(udm.create_reference(pfmBone))
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

	local toElement = sfmChannel:GetToElement()
	if(toElement == nil) then
		-- pfm.log("Unsupported 'to'-element for channel '" .. sfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
	else
		local pfmElement = converter:ConvertNewElement(toElement)
		pfmChannel:SetToElementAttr(udm.create_reference(pfmElement))
		if(pfmElement:GetChild(toAttr) == nil) then
			pfm.log("Invalid to-attribute '" .. toAttr .. "' of element '" .. pfmElement:GetName() .. "' used for channel '" .. pfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
	end

	--[[local graphCurve = sfmChannel:GetGraphCurve()
	if(graphCurve ~= nil) then
		pfmChannel:SetGraphCurveAttr(converter:ConvertNewElement(graphCurve))
	end]]
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
		pfmDag:SetTransformAttr(converter:ConvertNewElement(sfmDag:GetTransform(),sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL))
		pfmDag:SetVisible(sfmDag:IsVisible())
		apply_override_parent(converter,sfmDag,pfmDag)
		for _,child in ipairs(sfmDag:GetChildren()) do
			local type = child:GetType()

			if(type == "DmeGameModel" or type == "DmeCamera" or type == "DmeProjectedLight" or type == "DmeGameParticleSystem") then
				local actor = converter:CreateActor(child)
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
end)

sfm.register_element_type_conversion(sfm.GameParticleSystem,udm.PFMParticleSystem,function(converter,sfmParticle,pfmParticle)
	pfmParticle:SetTimeScale(sfmParticle:GetSimulationTimeScale())
	pfmParticle:SetDefinition(converter:ConvertNewElement(sfmParticle:GetParticleSystemDefinition()))
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
		local type = attr:GetType()
		local v = attr:GetValue()
		if(type == dmx.Attribute.TYPE_INT) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
		elseif(type == dmx.Attribute.TYPE_FLOAT) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_FLOAT,v))
		elseif(type == dmx.Attribute.TYPE_BOOL) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_BOOL,v))
		elseif(type == dmx.Attribute.TYPE_STRING) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_STRING,v))
		elseif(type == dmx.Attribute.TYPE_COLOR) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_COLOR,v))
		elseif(type == dmx.Attribute.TYPE_VECTOR3) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_VECTOR3,v))
		elseif(type == dmx.Attribute.TYPE_ANGLE) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_ANGLE,v))
		elseif(type == dmx.Attribute.TYPE_QUATERNION) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_QUATERNION,v))
		elseif(type == dmx.Attribute.TYPE_UINT64) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
		elseif(type == dmx.Attribute.TYPE_UINT8) then pfmParticleOp:SetProperty(name,udm.create_attribute(udm.ATTRIBUTE_TYPE_INT,v))
		else
			pfm.log("Unsupported particle attribute type '" .. dmx.type_to_string(type) .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
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
