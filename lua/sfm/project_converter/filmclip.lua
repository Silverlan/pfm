
local function iterate_film_clip_children(converter,pfmFilmClip,node,parentName)
	local numTypes = 0
	if(node:GetType() == "DmeProjectedLight" or node:GetType() == "DmeGameModel" or node:GetType() == "DmeCamera") then
		local pfmActor = converter:CreateActor(node)
		pfmFilmClip:GetActorsAttr():PushBack(pfmActor)
		numTypes = numTypes +1
	elseif(node:GetType() == "DmeDag") then
		local children = node:GetChildren()
		local actorName = node:GetName()

		-- Get the parent transform which will be applied to the children
		for _,child in ipairs(node:GetChildren()) do
			iterate_film_clip_children(converter,pfmFilmClip,child,actorName)
		end
	else
		pfm.log("Unsupported film clip child type '" .. node:GetType() .. "' of parent '" .. node:GetName() .. "'! Child will be ignored!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
	end
	if(numTypes > 1) then
		pfm.log("Expected node '" .. node:GetName() .. "' to have a maximum of 1 type, but has " .. numTypes .. "! This is not supported!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_ERROR)
		return
	end
end

sfm.register_element_type_conversion(sfm.FilmClip,udm.PFMFilmClip,function(converter,sfmFilmClip,pfmFilmClip)
	pfmFilmClip:SetTimeFrameAttr(converter:ConvertNewElement(sfmFilmClip:GetTimeFrame()))
	pfmFilmClip:SetSceneAttr(converter:ConvertNewElement(sfmFilmClip:GetScene()))
	pfmFilmClip:SetMaterialOverlay(converter:ConvertNewElement(sfmFilmClip:GetMaterialOverlay()))
	pfmFilmClip:SetFadeIn(sfmFilmClip:GetFadeIn())
	pfmFilmClip:SetFadeOut(sfmFilmClip:GetFadeOut())

	-- Note: In PFM game models and cameras are actors and animation sets are actor components.
	-- In SFM that relationship is the other way around, so we have to iterate through the list of
	-- animation sets to get the association.
	local actorNameToAnimSet = {}
	local animSetNameToAnimSet = {}
	-- TODO: Obsolete
	--[[for _,animSet in ipairs(sfmFilmClip:GetAnimationSets()) do
		local gameModel = animSet:GetGameModel()
		local camera = animSet:GetCamera()
		local actorName
		if(gameModel ~= nil) then
			actorName = gameModel:GetName()
		elseif(camera ~= nil) then
			actorName = camera:GetName()
		else
			pfm.log("Animation set '" .. animSet:GetName() .. "' has no camera or game model associated! Animation set will not be used.",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		end

		if(actorName ~= nil) then
			actorNameToAnimSet[actorName] = animSet
			animSetNameToAnimSet[animSet:GetName()] = animSet
		end
	end]]

	local scene = sfmFilmClip:GetScene()
	local t = converter:ConvertNewElement(scene:GetTransform(),sfm.ProjectConverter.TRANSFORM_TYPE_GLOBAL)

	-- Note: All objects in a scene are located under FilmTrack->scene->children. The structure for the children is a bit peculiar:
	-- Some child-nodes can be group nodes. There doesn't seem to be a 'proper' way to determine whether or not a node is a group node
	-- so it's assumed that group nodes always contain one or more DmeDag elements and everything else is a concrete type node (e.g. camera, gameModel).
	iterate_film_clip_children(converter,pfmFilmClip,scene)

	-- We'll add the animation sets (FilmTrack->animationSets) to the actors (i.e. game models) as components.
	-- Some game models may not have an animation set associated with them.
	local animSetToActor = {}
	for _,actor in ipairs(pfmFilmClip:GetActors():GetTable()) do
		local actorName = actor:GetName()
		local animSet = actorNameToAnimSet[actorName]
		if(animSet ~= nil) then -- Check if there is an animation set for this actor
			local pfmAnimSet = converter:ConvertNewElement(animSet)
			pfmAnimSet:SetName(actorName .. "_animset")
			actor:AddComponent(pfmAnimSet)
			animSetToActor[animSet] = actor
		end
	end

	local cam = sfmFilmClip:GetCamera()
	local camName = cam:GetName()
	if(#camName > 0) then -- TODO: Can a camera be valid if it has no name? If so, how do we check if a camera is actually valid?
		-- Note: For some reason in some cases the camera may not be in the list of the scene children for the film clip, but the camera is still usable.
		-- In this case we'll just add the camera manually here.
		-- pfm.log("Camera '" .. camName .. "' of clip '" .. pfmFilmClip:GetName() .. "' not found in list of actors! Adding manually...",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)

		local actor,isNewActor = converter:CreateActor(cam)
		pfmFilmClip:SetProperty("camera",udm.create_reference(actor))
		if(isNewActor == true) then -- This is a new actor we didn't know about yet
			pfmFilmClip:GetActorsAttr():PushBack(actor)
		end
	end

	local trackGroups = {}
	for _,trackGroup in ipairs(sfmFilmClip:GetTrackGroups()) do
		table.insert(trackGroups,trackGroup)
	end
	local subClipTrackGroup = sfmFilmClip:GetSubClipTrackGroup()
	if(subClipTrackGroup ~= nil) then
		table.insert(trackGroups,subClipTrackGroup)
	end

	-- Note: The channel clips within the tracks refer to animation sets through their name, but
	-- animation sets in PFM cannot be referenced directly. For this reason we'll change the reference
	-- of the channel clips from the animation set to the actors that the animation set belongs to.
	for _,trackGroup in ipairs(trackGroups) do
		for _,track in ipairs(trackGroup:GetTracks()) do
			for _,channelClip in ipairs(track:GetChannelClips()) do
				local animSetName = channelClip:GetName()
				local animSet = animSetNameToAnimSet[animSetName]
				if(animSet ~= nil) then
					local actor = animSetToActor[animSet]
					if(actor ~= nil) then
						pfm.log("Renaming channel clip '" .. channelClip:GetName() .. "' of track '" .. track:GetName() .. "' of track group '" .. trackGroup:GetName() .. "' to name of associated actor '" .. actor:GetName() .. "'!",pfm.LOG_CATEGORY_SFM)
						channelClip:SetName(actor:GetName())
					else
						pfm.log("Animation set '" .. animSetName .. "' of channel clip '" .. channelClip:GetName() .. "' of track '" .. track:GetName() .. "' of track group '" .. trackGroup:GetName() .. "' has no associated actor! This clip will not be used!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
					end
				else
					pfm.log("Channel clip '" .. channelClip:GetName() .. "' of track '" .. track:GetName() .. "' of track group '" .. trackGroup:GetName() .. "' does not reference known animation set! The actor associated with this clip may not be animated properly!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
				end
			end
		end
	end

	for _,trackGroup in ipairs(trackGroups) do
		local pfmTrackGroup = converter:ConvertNewElement(trackGroup)
		pfmFilmClip:GetTrackGroupsAttr():PushBack(pfmTrackGroup)
	end
end)
