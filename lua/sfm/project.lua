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
	self.m_dmxData = dmxData
	self.m_dmxToElement = {}
	self.m_elementToDMX = {}
	self.m_cachedElements = {}

	self.m_sessions = {}
	local elSession = dmxData:GetRootAttribute():GetValue()
	if(elSession ~= nil) then
		-- The 'clipBin' and 'miscBin' containers should only contain elements of type 'DmeFilmClip'
		-- but in some cases they can also contain sessions, which in turn contain clip elements.
		-- I don't know why that is, but it messes with out importer, so we'll move them up to the main 'clipBin'/'miscBin' containers.
		-- TODO: This might be obsolete
		local attrClipBin = elSession:GetAttribute("clipBin")
		local attrMiscBin = elSession:GetAttribute("miscBin")
		local bins = {}
		if(attrClipBin ~= nil) then table.insert(bins,attrClipBin) end
		if(attrMiscBin ~= nil) then table.insert(bins,attrMiscBin) end
		for _,bin in ipairs(bins) do
			for _,attr in ipairs(bin:GetValue()) do
				local val = attr:GetValue()
				if(val:GetType() == "DmElement") then
					local attrChildClipBin = val:GetAttribute("clipBin")
					if(attrChildClipBin ~= nil) then
						for _,elChild in ipairs(attrChildClipBin:GetValue()) do
							bin:AddArrayValue(elChild)
						end
					end

					local attrChildMiscBin = val:GetAttribute("miscBin")
					if(attrChildMiscBin ~= nil) then
						for _,elChild in ipairs(attrChildMiscBin:GetValue()) do
							attrMiscBin:AddArrayValue(elChild)
						end
					end
					bin:RemoveArrayValue(attr)
				end
			end
		end

		table.insert(self.m_sessions,self:CreatePropertyFromDMXElement(elSession,sfm.Session))
	end

	-- TODO: Obsolete! Now done in project converter!
	-- For some reason root bones requires a different transformation than other bones,
	-- so we'll have to apply that in post-processing here.
	--[[for _,session in ipairs(self:GetSessions()) do
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
										-- local isRootTransform = (boneName == "rootTransform")
										local isRootBone = (rootBones[boneId] ~= nil)
										if(isRootBone) then
											transformControl:SetValuePosition(sfm.convert_source_root_bone_position_to_pragma(transformControl:GetValuePosition()))
											transformControl:SetValueOrientation(sfm.convert_source_root_bone_rotation_to_pragma(transformControl:GetValueOrientation()))

											local posChannel = transformControl:GetPositionChannel()
											local log = posChannel:GetLog()
											for _,layer in ipairs(log:GetLayers()) do
												if(layer:GetType() == "DmeVector3LogLayer") then
													for _,v in ipairs(layer:GetValues()) do
														v:Set(sfm.convert_source_root_bone_position_to_pragma(v))
													end
												end
											end

											local rotChannel = transformControl:GetOrientationChannel()
											log = rotChannel:GetLog()
											for _,layer in ipairs(log:GetLayers()) do
												if(layer:GetType() == "DmeQuaternionLogLayer") then
													for _,v in ipairs(layer:GetValues()) do
														v:Set(sfm.convert_source_root_bone_rotation_to_pragma(v))
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
	end]]
end

function sfm.Project:CreatePropertyFromDMXElement(dmxEl,class,parent)
	local cachedElement = self:GetCachedElement(dmxEl)
	if(cachedElement ~= nil) then
		if(parent ~= nil) then cachedElement:AddParent(parent) end
		return cachedElement
	end
	local o = self:CreateElement(class,parent)
	self:CacheElement(dmxEl,o) -- Needs to be cached before loading to prevent possible infinite recursion
	if(type(o) == "userdata") then o:Load(dmxEl) end
	return o
end

function sfm.Project:GetCachedElement(dmxEl,name)
	local cacheId = dmxEl:GetGUID()
	if(self.m_cachedElements[cacheId] ~= nil) then
		if(name ~= nil) then return self.m_cachedElements[cacheId] and self.m_cachedElements[cacheId][name] or nil end
		return self.m_cachedElements[cacheId]
	end
end

function sfm.Project:CacheElement(dmxEl,el,name)
	local cacheId = dmxEl:GetGUID()
	if(name == nil) then self.m_cachedElements[cacheId] = el
	else
		self.m_cachedElements[cacheId] = self.m_cachedElements[cacheId] or {}
		self.m_cachedElements[cacheId][name] = el
	end
end

function sfm.Project:MapDMXElement(dmxElement,element)
	self.m_dmxToElement[dmxElement] = element
	self.m_elementToDMX[element] = dmxElement
end

function sfm.Project:GetElementFromDMXElement(dmxElement)
	return self.m_dmxToElement[dmxElement]
end

function sfm.Project:GetDMXElement(element)
	return self.m_elementToDMX[element]
end

function sfm.Project:GetSessions() return self.m_sessions end

function sfm.Project:CreateElement(elType,parent,...)
	if(elType == nil) then
		error("Attempted to create element of unknown type: Type is nil!")
	end
	local class = (type(elType) == "string") and sfm.get_type_data(elType) or elType
	local el = class(self,...)
	if(parent ~= nil) then el:AddParent(parent) end
	return el
end
