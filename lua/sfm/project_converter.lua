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
		print("SESSION: ",util.get_type_name(session))
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
	for name,node in pairs(project:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
			iterate_film_clip(node)
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
	for _,clipSet in ipairs({sfmSession:GetClipBin(),sfmSession:GetMiscBin()}) do
		for _,clip in ipairs(clipSet) do
			if(clip:GetType() == "DmeFilmClip") then
				self.m_pfmProject:AddFilmClip(self:ConvertNewElement(clip))
			else
				pfm.log("Unsupported clip type '" .. clip:GetType() .. "'! Skipping...",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
			end
		end
	end
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
	if(actor ~= nil) then return actor end
	actor = udm.create_element(udm.ELEMENT_TYPE_PFM_ACTOR)
	actor:SetName(pfmComponent:GetName()) -- TODO: Remove suffix (e.g. _model)

	local transformType = sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL
	if(sfmComponent:GetType() == "DmeCamera") then transformType = sfm.ProjectConverter.TRANSFORM_TYPE_ALT end

	actor:SetTransformAttr(self:ConvertNewElement(sfmComponent:GetTransform(),transformType))
	print("CREATING ACTOR WITH ROTATION ",actor:GetName(),actor:GetTransform():GetRotation())
	actor:AddComponent(pfmComponent)
	self:CachePFMActor(pfmComponent,actor)
	return actor
end
function sfm.ProjectConverter:GetPFMElement(element)
	return self.m_sfmElementToPfmElement[element]
end
local function convert_root_bone_pos(pos)
	pos:Set(pos.x,-pos.y,-pos.z)
end
local rot180Pitch = EulerAngles(180,0,0):ToQuaternion()
local function convert_root_bone_rot(rot)
	local newRot = rot180Pitch *rot
	rot:Set(newRot.w,newRot.x,newRot.y,newRot.z)
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
					for boneId,t in ipairs(component:GetBones():GetTable()) do
						-- TODO: I'm not sure if the index actually corresponds to the bone id, keep this under observation
						local isRootBone = (mdl ~= nil) and mdl:IsRootBone(boneId -1) or false

						local pos = t:GetPosition():Copy()
						local rot = t:GetRotation():Copy()
						pos = sfm.convert_source_anim_set_position_to_pragma(pos)
						rot = sfm.convert_source_anim_set_rotation_to_pragma(rot)
						if(isRootBone) then
							convert_root_bone_pos(pos)
							convert_root_bone_rot(rot)
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
					local isPosTransform = (toAttr == "position")
					local isRotTransform = (toAttr == "rotation")
					if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM and (isPosTransform or isRotTransform)) then
						-- Bone transforms require a special conversion, so we need to determine whether this log layer refers to a bone.
						-- We do so by going backwards through the hierarchy and checking if the layer is part of the bones array of a model.
						local boneArray = toElement and (toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM) and toElement:FindParent(function(p) return p:GetType() == udm.ELEMENT_TYPE_ARRAY and p:GetName() == "bones" end) or nil
						local pfmModel = boneArray and boneArray:FindParent(function(p) return p:GetType() == udm.ELEMENT_TYPE_PFM_MODEL end) or nil
						local isBoneTransform = (pfmModel ~= nil)

						if(isBoneTransform) then
							local boneName = toElement:GetName()
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
												convert_root_bone_pos(value)
											end
										else
											value:Set(sfm.convert_source_anim_set_rotation_to_pragma(value))
											if(isRootBone) then
												convert_root_bone_rot(value)
											end
										end
									end
								end
							end
						else
							local log = channel:GetLog()
							for _,layer in ipairs(log:GetLayers():GetTable()) do
								if(processedObjects[layer] == nil) then
									processedObjects[layer] = true
									for _,value in ipairs(layer:GetValues():GetTable()) do
										if(isPosTransform) then
											value:Set(sfm.convert_source_transform_position_to_pragma(value))
										else
											value:Set(sfm.convert_source_transform_rotation_to_pragma(value))
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
	local project = self:GetPFMProject()
	for name,node in pairs(project:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
			apply_post_processing(project,node)
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
	pfmElement:SetName(sfmElement:GetName())
	self.m_sfmElementToPfmElement[sfmElement] = pfmElement -- Has to be cached before conversion function is called!
	data[1](self,sfmElement,pfmElement,...)
end

function sfm.ProjectConverter:ConvertNewElement(sfmElement,...)
	if(self.m_sfmElementToPfmElement[sfmElement] ~= nil) then
		return self.m_sfmElementToPfmElement[sfmElement] -- Return cached element
	end
	local data = sfm.get_pfm_conversion_data(util.get_type_name(sfmElement))
	if(data == nil) then
		pfm.error("No PFM conversion function exists for SFM element of type '" .. util.get_type_name(sfmElement) .. "'!")
	end
	local pfmElement = data[2]()
	pfmElement:SetName(sfmElement:GetName())
	self:ConvertElement(sfmElement,pfmElement,...)
	return pfmElement
end

----------------------

include("project_converter")

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

	for _,node in ipairs(sfmGameModel:GetBones()) do
		local name = string.remove_whitespace(node:GetName()) -- Format: "name (boneName)"
		local boneNameStart = name:find("%(")
		local boneNameEnd = name:match('.*()' .. "%)") -- Reverse find
		if(boneNameStart ~= nil and boneNameEnd ~= nil) then
			local boneName = name:sub(boneNameStart +1,boneNameEnd -1)
			local t = converter:ConvertNewElement(node,sfm.ProjectConverter.TRANSFORM_TYPE_NONE)
			t:SetName(boneName)

			pfmGameModel:GetBonesAttr():PushBack(t)
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
end)

sfm.register_element_type_conversion(sfm.GlobalFlexControllerOperator,udm.PFMGlobalFlexControllerOperator,function(converter,sfmOp,pfmOp)
	pfmOp:SetFlexWeight(sfmOp:GetFlexWeight())
	pfmOp:SetGameModelAttr(converter:ConvertNewElement(sfmOp:GetGameModel()))
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
		pfmChannel:SetToElementAttr(pfmElement)
		if(pfmElement:GetChild(toAttr) == nil) then
			pfm.log("Invalid to-attribute '" .. toAttr .. "' of element '" .. pfmElement:GetName() .. "' used for channel '" .. pfmChannel:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
		end
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
end)

sfm.register_element_type_conversion(sfm.Dag,udm.PFMGroup,function(converter,sfmDag,pfmDag)
	pfmDag:SetTransformAttr(converter:ConvertNewElement(sfmDag:GetTransform(),sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL))
	for _,child in ipairs(sfmDag:GetChildren()) do
		local type = child:GetType()
		if(type == "DmeGameModel" or type == "DmeCamera" or type == "DmeProjectedLight") then
			local actor = converter:CreateActor(child)
			pfmDag:AddChild(actor)
		else
			local pfmElement = converter:ConvertNewElement(child)
			pfmDag:AddChild(pfmElement)
		end
	end
end)

sfm.register_element_type_conversion(sfm.MaterialOverlayFXClip,udm.PFMMaterialOverlayFXClip,function(converter,sfmMat,pfmMat)
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
	-- TODO
	pfmLight:SetColor(Color.Red)--sfmLight:GetColor())
	pfmLight:SetIntensity(2000.0)--sfmLight:GetIntensity())
	pfmLight:SetIntensityType(ents.LightComponent.INTENSITY_TYPE_CANDELA)
	pfmLight:SetFalloffExponent(1.0)
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
	pfmTransform:SetName(sfmTransform:GetName())
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
		pfmTransform:SetRotation(sfm.convert_source_transform_rotation_to_pragma(sfmTransform:GetOrientation()))
	else
		pfmTransform:SetPosition(sfmTransform:GetPosition())
		pfmTransform:SetRotation(sfmTransform:GetOrientation())
	end
end)
