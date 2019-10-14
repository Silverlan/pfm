--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Project")
include("base_element.lua")
include("project")

function sfm.Project:__init(dmxData)
	local elements = dmxData:GetElements()
	self.m_sessions = {}
	for _,el in ipairs(elements) do
		if(el:GetName() == "session") then
			table.insert(self.m_sessions,sfm.Session(el))
		end
	end

	-- For some reason the root bone of animation sets requires a different transformation than other bones,
	-- so we'll have to apply that in post-processing here.
	for _,session in ipairs(self:GetSessions()) do
		for _,clipSet in ipairs({session:GetClipBin(),session:GetMiscBin()}) do
			for _,clip in ipairs(clipSet) do
				local subClipTrackGroup = clip:GetSubClipTrackGroup()
				for _,track in ipairs(subClipTrackGroup:GetTracks()) do
					for _,filmClip in ipairs(track:GetFilmClips()) do
						for _,animSet in ipairs(filmClip:GetAnimationSets()) do
							local gameModel = animSet:GetGameModel()
							if(gameModel ~= nil) then
								local mdlName = gameModel:GetPragmaModelPath()
								local mdl = game.load_model(mdlName)
								if(mdl == nil) then
									console.print_warning("Model '" .. mdlName .. "' could not be loaded! This may result with incorrect translation values for this object!")
								else
									local rootBones = mdl:GetSkeleton():GetRootBones()
									for _,transformControl in ipairs(animSet:GetTransformControls()) do
										local boneName = transformControl:GetName()
										local boneId = mdl:LookupBone(boneName)
										if(boneName == "rootTransform" or rootBones[boneId] ~= nil) then
											local posChannel = transformControl:GetPositionChannel()
											local log = posChannel:GetLog()
											for _,layer in ipairs(log:GetLayers()) do
												if(layer:GetType() == "DmeVector3LogLayer") then
													for _,v in ipairs(layer:GetValues()) do
														v:Set(Vector(v.x,-v.y,-v.z))
													end
												end
											end

											local rotChannel = transformControl:GetOrientationChannel()
											log = rotChannel:GetLog()
											for _,layer in ipairs(log:GetLayers()) do
												if(layer:GetType() == "DmeQuaternionLogLayer") then
													for _,v in ipairs(layer:GetValues()) do
														local newRot = EulerAngles(180,0,0):ToQuaternion() *v
														v:Set(newRot.w,newRot.x,newRot.y,newRot.z)
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function sfm.Project:GetSessions() return self.m_sessions end
