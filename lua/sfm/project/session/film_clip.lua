--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("film_clip")
include("time_frame.lua")

util.register_class("sfm.FilmClip",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.FilmClip,"mapname","")
sfm.BaseElement.RegisterArray(sfm.FilmClip,"trackGroups",sfm.TrackGroup)
sfm.BaseElement.RegisterArray(sfm.FilmClip,"animationSets",sfm.AnimationSet)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"subClipTrackGroup",sfm.TrackGroup)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"camera",sfm.Camera)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"timeFrame",sfm.TimeFrame)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"scene",sfm.Scene)

function sfm.FilmClip:__init()
  sfm.BaseElement.__init(self,sfm.FilmClip)
end

function sfm.FilmClip:GetType() return "DmeFilmClip" end

local function iterate_film_clip_children(pfmFilmClip,node,parentName,parentTransform)
  local numTypes = 0
  if(node:GetType() == "DmeProjectedLight") then
    local lightName = node:GetName() -- The actor for a light node is always the node itself, so we can just use its own name
    local pfmActor = udm.PFMActor(lightName)
    local light = udm.PFMSpotLight(lightName .. "_spotlight")
    node:ToPFMLight(light)
    node:GetTransform():ToPFMTransformGlobal(pfmActor:GetTransform()) -- Transform is moved from light to actor
    pfmActor:GetTransform():ApplyTransformGlobal(parentTransform)
    pfmActor:AddComponent(light)
    pfmFilmClip:GetActorsAttr():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeGameModel") then
    local actorName = node:GetName()
    local pfmActor = udm.PFMActor(actorName)
    local model = udm.PFMModel(actorName .. "_model")
    node:ToPFMModel(model)
    node:GetTransform():ToPFMTransformGlobal(pfmActor:GetTransform()) -- Transform is moved from model to actor
    pfmActor:GetTransform():ApplyTransformGlobal(parentTransform)
    pfmActor:AddComponent(model)
    pfmFilmClip:GetActorsAttr():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeCamera") then
    local cameraName = node:GetName() -- Camera name is name of its own node
    local pfmActor = udm.PFMActor(cameraName)
    local camera = udm.PFMCamera(cameraName .. "_camera")
    node:ToPFMCamera(camera)
    node:GetTransform():ToPFMTransformGlobal(pfmActor:GetTransform()) -- Transform is moved from camera to actor
    pfmActor:GetTransform():ApplyTransformGlobal(parentTransform)
    pfmActor:AddComponent(camera)
    pfmFilmClip:GetActorsAttr():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeDag") then
    local children = node:GetChildren()
    local actorName = node:GetName()

    -- Get the parent transform which will be applied to the children
    local transform = phys.Transform()
    if(util.get_type_name(node) == "GenericDmeChild") then
      local t = udm.Transform()
      node:GetTransform():ToPFMTransformGlobal(t)
      transform = t:GetPose()
    end
    if(parentTransform ~= nil) then transform = parentTransform *transform end

    for _,child in ipairs(node:GetChildren()) do
      iterate_film_clip_children(pfmFilmClip,child,actorName,transform)
    end
  else
    pfm.log("Unsupported film clip child type '" .. node:GetType() .. "' of parent '" .. node:GetName() .. "'! Child will be ignored!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
  end
  if(numTypes > 1) then
    pfm.log("Expected node '" .. node:GetName() .. "' to have a maximum of 1 type, but has " .. numTypes .. "! This is not supported!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_ERROR)
    return
  end
end

function sfm.FilmClip:ToPFMFilmClip(pfmFilmClip)
  self:GetTimeFrame():ToPFMTimeFrame(pfmFilmClip:GetTimeFrame())

  -- Note: In PFM game models and cameras are actors and animation sets are actor components.
  -- In SFM that relationship is the other way around, so we have to iterate through the list of
  -- animation sets to get the association.
  local actorNameToAnimSet = {}
  local animSetNameToAnimSet = {}
  for _,animSet in ipairs(self:GetAnimationSets()) do
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
  end

  local scene = self:GetScene()
  local t = udm.Transform()
  scene:GetTransform():ToPFMTransformGlobal(t)

  -- Note: All objects in a scene are located under FilmTrack->scene->children. The structure for the children is a bit peculiar:
  -- Some child-nodes can be group nodes. There doesn't seem to be a 'proper' way to determine whether or not a node is a group node
  -- so it's assumed that group nodes always contain one or more DmeDag elements and everything else is a concrete type node (e.g. camera, gameModel).
  local scenePose = t:GetPose()
  iterate_film_clip_children(pfmFilmClip,scene,nil,scenePose)

  -- We'll add the animation sets (FilmTrack->animationSets) to the actors (i.e. game models) as components.
  -- Some game models may not have an animation set associated with them.
  local animSetToActor = {}
  for _,actor in ipairs(pfmFilmClip:GetActors()) do
    local actorName = actor:GetName()
    local animSet = actorNameToAnimSet[actorName]
    if(animSet ~= nil) then -- Check if there is an animation set for this actor
      local pfmAnimSet = udm.PFMAnimationSet(actorName .. "_animset")
      animSet:ToPFMAnimationSet(pfmAnimSet)
      actor:AddComponent(pfmAnimSet)
      animSetToActor[animSet] = actor
    end
  end

  local camName = self:GetCamera():GetName()
  if(#camName > 0) then
    -- Find the camera actor for this film clip
    local foundCamera = false
    for _,actor in ipairs(pfmFilmClip:GetActors()) do
      local actorName = actor:GetName()
      for _,component in ipairs(actor:GetComponents()) do
        if(component:GetValue():GetType() == udm.ELEMENT_TYPE_PFM_CAMERA and actorName == camName) then
          pfmFilmClip:SetProperty("camera",actor)
          foundCamera = true
          break
        end
      end
      if(foundCamera == true) then break end
    end
    if(foundCamera == false) then
      -- Note: For some reason in some cases the camera may not be in the list of the scene children for the film clip, but the camera is still usable.
      -- In this case we'll just add the camera manually here.
      pfm.log("Camera '" .. camName .. "' of clip '" .. pfmFilmClip:GetName() .. "' not found in list of actors! Adding manually...",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
      local actor = udm.create_element(udm.ELEMENT_TYPE_PFM_ACTOR)
      actor:SetName(camName)
      self:GetCamera():GetTransform():ToPFMTransformAlt(actor:GetTransform()) -- Transform is moved from camera to actor
      actor:GetTransform():ApplyTransformGlobal(scenePose)
      
      local cam = udm.create_element(udm.ELEMENT_TYPE_PFM_CAMERA)
      cam:SetName(camName)
      actor:GetComponentsAttr():PushBack(udm.create_attribute(udm.ATTRIBUTE_TYPE_ANY,cam))
      pfmFilmClip:GetActorsAttr():PushBack(actor)

      pfmFilmClip:SetProperty("camera",actor)
    end
  end

  local trackGroups = self:GetTrackGroups()
  local subClipTrackGroup = self:GetSubClipTrackGroup()
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
    local pfmTrackGroup = udm.PFMTrackGroup(trackGroup:GetName())
    trackGroup:ToPFMTrackGroup(pfmTrackGroup)
    pfmFilmClip:GetTrackGroupsAttr():PushBack(pfmTrackGroup)
  end
end
