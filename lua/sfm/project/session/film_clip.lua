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
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"subClipTrackGroup",sfm.SubClipTrackGroup)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"camera",sfm.Camera)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"timeFrame",sfm.TimeFrame)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"scene",sfm.Scene)

function sfm.FilmClip:__init()
  sfm.BaseElement.__init(self,sfm.FilmClip)
end

function sfm.FilmClip:GetType() return "DmeFilmClip" end

local function iterate_film_clip_children(pfmFilmClip,node,actorName)
  local numTypes = 0
  if(node:GetType() == "DmeProjectedLight") then
    local lightName = node:GetName() -- The actor for a light node is always the node itself, so we can just use its own name
    local pfmActor = udm.PFMActor(lightName)
    local light = udm.PFMSpotLight(lightName .. "_spotlight")
    node:ToPFMLight(light)
    pfmActor:AddComponent(light)
    pfmFilmClip:GetActors():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeGameModel") then
    local pfmActor = udm.PFMActor(actorName)
    local model = udm.PFMModel(actorName .. "_model")
    node:ToPFMModel(model)
    pfmActor:AddComponent(model)
    pfmFilmClip:GetActors():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeCamera") then
    local cameraName = node:GetName() -- Camera name is name of its own node
    local pfmActor = udm.PFMActor(cameraName)
    local camera = udm.PFMCamera(cameraName .. "_camera")
    node:ToPFMCamera(camera)
    pfmActor:AddComponent(camera)
    pfmFilmClip:GetActors():PushBack(pfmActor)
    numTypes = numTypes +1
  elseif(node:GetType() == "DmeDag") then
    local children = node:GetChildren()
    local actorName = node:GetName()
    for _,child in ipairs(node:GetChildren()) do
      iterate_film_clip_children(pfmFilmClip,child,actorName)
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

  local nameToAnimSet = {}
  for _,animSet in ipairs(self:GetAnimationSets()) do
    nameToAnimSet[animSet:GetName()] = animSet
  end

  -- Note: All objects in a scene are located under FilmTrack->scene->children. The structure for the children is a bit peculiar:
  -- Some child-nodes can be group nodes. There doesn't seem to be a 'proper' way to determine whether or not a node is a group node
  -- so it's assumed that group nodes always contain one or more DmeDag elements and everything else is a concrete type node (e.g. camera, gameModel).

  local scene = self:GetScene()
  iterate_film_clip_children(pfmFilmClip,scene)

  -- Some of the game model objects may have an animation set associated with them located in FilmTrack->animationSets, but that is optional.
  for _,actor in ipairs(pfmFilmClip:GetActors():GetValue()) do
    local actorName = actor:GetName()
    for _,component in ipairs(actor:GetComponents():GetValue()) do
      if(nameToAnimSet[actorName] ~= nil) then
        local animSet = udm.PFMAnimationSet(actorName .. "_animset")
        nameToAnimSet[actorName]:ToPFMAnimationSet(animSet)
        actor:AddComponent(animSet)
      end
      break
    end
  end

  local camName = self:GetCamera():GetName()
  -- Find the camera actor for this film clip
  local foundCamera = false
  for _,actor in ipairs(pfmFilmClip:GetActors():GetValue()) do
    local actorName = actor:GetName()
    for _,component in ipairs(actor:GetComponents():GetValue()) do
      if(component:GetValue():GetType() == udm.ELEMENT_TYPE_PFM_CAMERA and actorName == camName) then
        pfmFilmClip:SetProperty("camera",actor)
        foundCamera = true
        break
      end
    end
    if(foundCamera == true) then break end
  end
  if(foundCamera == false) then
    pfm.log("Camera '" .. camName .. "' of clip '" .. pfmFilmClip:GetName() .. "' not found in list of actors! Camera will be unavailable!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
  end
end
