local r = engine.load_library("pr_dmx")
if(r ~= true) then
	print("WARNING: An error occured trying to load the 'pr_dmx' module: ",r)
	return
end

util.register_class("dmx.Scene")

sfm = sfm or {}
util.register_class("sfm.Scene")

include("dmx_session.lua")

function dmx.Scene:__init()
end

function dmx.Scene:Import(fpath)
	local f = file.open(fpath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	local elements = dmx.load(f)
	f:Close()
	
	local dmxData
	dmxData:Get("session")[1]:Get("settings")
	
	for _,el in ipairs(elements) do
		if(el:GetName() == "session") then
			local session = sfm.Scene.Session(el)
			local settings = session:GetSettings()
			local movieSettings = settings:GetMovieSettings()
			local videoTarget = movieSettings:GetVideoTarget()
			print("Video Target: ",videoTarget)
			break
		end
	end
	
	return false
	--[[local str = ""
	for _,el in ipairs(elements) do
		str = str .. tostring(el) .. "\n"
	end
	
	
	for _,el in ipairs(elements) do
		if(el:GetName() == "session") then
			self:LoadSession(el)
			break
		end
	end]]
	
	--[[local fOut = file.open("dmxtest.txt",bit.bor(file.OPEN_MODE_WRITE))
	fOut:WriteString(str)
	fOut:Close()]]
	
	--[[if(true) then
		return false
	end
	
	self.m_scene = ents.create("pfm_scene")
	for _,el in ipairs(elements) do
		if(el:GetName() == "session") then
			self:InitializeSession(el)
			break
		end
	end
	return true]]
end

function dmx.Scene:GetPFMScene() return self.m_scene end

function dmx.Scene:GetChannelValues(channel)
	local log = channel:GetAttributeValue("log")
	local layers = log:GetAttributeValue("layers")
	local outValues = {}
	for _,attrLayer in ipairs(layers) do
		local layer = attrLayer:GetValue()
		local times = layer:GetAttributeValue("times")
		local values = layer:GetAttributeValue("values")
		for i=1,#times do
			local t = times[i]:GetValue()
			local v = values[i]:GetValue()
			table.insert(outValues,{t,v})
		end
	end
	return outValues
end

function dmx.Scene:GetTransform(el)
	local transform = el:GetAttributeValue("transform")
	local pos = transform:GetAttributeValue("position")
	local rot = transform:GetAttributeValue("orientation")
	
	-- Transform coordinate system from source to pragma
	local y = pos.y
	pos.y = pos.z
	pos.z = -y
	
	--[[local y = rot.y
	rot.x = -rot.x
	rot.y = rot.z
	rot.z = y
	rot = EulerAngles(0,180,0):ToQuaternion() *rot]]
	local x = rot.x
	local y = rot.y
	local z = rot.z
	rot.x = y
	rot.y = z
	rot.z = x
	rot = EulerAngles(0,-90,0):ToQuaternion() *rot
	return pos,rot
end

function dmx.Scene:GetTimeFrame(el)
	local ts = el:GetAttributeValue("timeFrame")
	local start = ts:GetAttributeValue("start")
	local duration = ts:GetAttributeValue("duration")
	local offset = ts:GetAttributeValue("offset")
	return start,duration,offset
end

function dmx.Scene:LoadCameraData(dmeCam,cam)
	--[[for _,attrChannel in ipairs(dmeCam:GetAttributeValue("channels")) do
		local channel = attrChannel:GetValue()
		local name = channel:GetName()
		if(name == "transform_pos") then
			local log = channel:GetAttributeValue("log")
			local layers = log:GetAttributeValue("layers")
			local outValues = {}
			for _,attrLayer in ipairs(layers) do
				local layer = attrLayer:GetValue()
				local times = layer:GetAttributeValue("times")
				local values = layer:GetAttributeValue("values")
				for i=1,#times do
					local t = times[i]:GetValue()
					local v = values[i]:GetValue()
					table.insert(outValues,{t,v})
				end
			end
			return outValues
		elseif(name == "transform_rot") then
			
		end
	end]]
end

--local bSpawned = false
function dmx.Scene:InitializeAnimationSet(track,animSet)
	local gameModel = animSet:GetAttributeValue("gameModel")
	if(gameModel == nil) then return end -- ??
	local modelName = gameModel:GetAttributeValue("modelName")
	modelName = file.remove_file_extension(modelName:sub(8)) .. ".wmd"
	if(modelName ~= "player\\hwm\\engineer.wmd" and modelName ~= "props_facemovie\\guitar\\guitar.wmd"--[[ and modelName ~= "props_facemovie\\beer_bottle.wmd"]]) then return end -- TODO
	--console.print_messageln(modelName)
	--if(modelName ~= "player/hwm/heavy.wmd") then return end -- TODO
	--if(bSpawned == true) then return end
	--bSpawned = true
	
	local pos,rot = self:GetTransform(gameModel)
	local actor = track:GetComponent(ents.COMPONENT_PFM_TRACK):AddActor(animSet:GetName(),modelName,pos,rot)
	local actorComponent = actor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	
	local controls = animSet:GetAttributeValue("controls")
	--console.print_table(controls)
	for _,attrCtrl in ipairs(controls) do
		local ctrl = attrCtrl:GetValue()
		local name = ctrl:GetName()
		
		local channel = ctrl:GetAttributeValue("channel")
		local rvChannel = ctrl:GetAttributeValue("rightvaluechannel")
		local lvChannel = ctrl:GetAttributeValue("leftvaluechannel")
		if(channel ~= nil or rvChannel ~= nil or lvChannel ~= nil) then
			-- Probably a flex controller?
			
			if(channel ~= nil) then
				local values = self:GetChannelValues(channel)
				for _,v in ipairs(values) do
					actorComponent:AddFlexTransform(name,v[1],v[2])
				end
			end
			if(rvChannel ~= nil) then
				local values = self:GetChannelValues(rvChannel)
				for _,v in ipairs(values) do
					actorComponent:AddFlexTransform("right_" .. name,v[1],v[2])
				end
			end
			if(lvChannel ~= nil) then
				local values = self:GetChannelValues(lvChannel)
				for _,v in ipairs(values) do
					actorComponent:AddFlexTransform("left_" .. name,v[1],v[2])
				end
			end
		else
			-- Probably a bone transform?
			local bRoot = name == "rootTransform"
			-- Position
			local posChannel = ctrl:GetAttributeValue("positionChannel")
			if(posChannel ~= nil) then
				local values = self:GetChannelValues(posChannel)
				for _,v in ipairs(values) do
					if(bRoot == false) then-- and name ~= "bip_pelvis") then
						local y = v[2].y
						v[2].y = -v[2].z
						v[2].z = y
					else
						local y = v[2].y
						v[2].y = v[2].z
						v[2].z = -y
					end
					--if(name == "bip_pelvis") then print("XXXX: ",v[2]) v[2] = Vector() end
					actorComponent:AddBoneTransform(name,v[1],v[2],nil)
				end
			end
			
			-- Rotation
			local rotChannel = ctrl:GetAttributeValue("orientationChannel")
			if(rotChannel ~= nil) then
				local values = self:GetChannelValues(rotChannel)
				for _,v in ipairs(values) do
					if(bRoot == false) then-- and name ~= "bip_pelvis") then
						local y = v[2].y
						v[2].y = -v[2].z
						v[2].z = y
					else
						local y = v[2].y
						v[2].x = -v[2].x
						v[2].y = v[2].z
						v[2].z = y
						v[2] = EulerAngles(0,180,0):ToQuaternion() *v[2]
					end
					actorComponent:AddBoneTransform(name,v[1],nil,v[2])
				end
			end
		end
	end
	
	--[[local boneTransforms = actor:GetBoneTransforms()
	local actorTransforms = {}
	for name,transforms in pairs(boneTransforms) do
		local boneId = ent:LookupBone(name)
		--if(name == "bip_collar_R") then print(boneId) end
		if(boneId ~= -1 and boneId ~= 0) then -- Bone 0 = root bone?
			actorTransforms[boneId] = {
				transformId = 1,
				transforms = transforms
			}
		end
	end
	
	local mdl = ent:GetModel()
	local flexTransforms = actor:GetFlexTransforms()
	local actorFlexTransforms = {}
	for name,transforms in pairs(flexTransforms) do
		local flexId = mdl:GetFlexControllerId(name)
		if(flexId ~= -1) then
			local fc = mdl:GetFlexController(flexId)
			local translatedTransforms = {}
			for _,t in ipairs(transforms) do
				table.insert(translatedTransforms,{
					time = t.time,
					value = t.value *(fc.max -fc.min) +fc.min
				})
			end
			actorFlexTransforms[flexId] = {
				transformId = 1,
				transforms = translatedTransforms,
				name = name
			}
		end
	end]]
	
	--[[actorFlexTransforms = {
		[mdl:GetFlexControllerId("JawV")] = {
			transformId = 1,
			transforms = {
				{
					time = 0.1,
					value = 0.57624965906143
				}
			}
		},
		[mdl:GetFlexControllerId("right_LipUpV")] = {
			transformId = 1,
			transforms = {
				{
					time = 0.1,
					value = 0.63530892133713
				}
			}
		},
		[mdl:GetFlexControllerId("left_LipUpV")] = {
			transformId = 1,
			transforms = {
				{
					time = 0.1,
					value = 0.66997975111008
				}
			}
		},
	}]]
	--local soundEvents = self.m_scene:GetSoundEvents()
	--local lastSoundEvent = 0
	--local t = time.cur_time()
	--[[ent:AddCallback("UpdateSkeleton",function()
		local tCur = time.cur_time()
		local tDelta = tCur -t
		
		-- Update sounds
		local numEvents = #soundEvents
		if(lastSoundEvent < numEvents) then
			for i=lastSoundEvent +1,numEvents do
				local ev = soundEvents[i]
				if(tDelta >= ev:GetStartTime()) then
					lastSoundEvent = i
					
					local snd = sound.create(ev:GetSoundName(),sound.TYPE_EFFECT)
					if(snd ~= nil) then
						--print("Playing sound: ",ev:GetSoundName(),tDelta,ev:GetStartTime())
						snd:SetGain(ev:GetVolume())
						snd:SetPitch(ev:GetPitch())
						snd:SetPos(ev:GetOrigin())
						snd:SetDirection(ev:GetDirection())
						snd:Play()
					end
				end
			end
		end
		
		if(tDelta >= start) then
			tDelta = tDelta -start
			
			-- Update bones
			for boneId,data in pairs(actorTransforms) do
				local t = data.transforms[data.transformId]
				--if(boneId == 14) then print(tDelta,data.transforms[data.transformId +1].time) end
				while(data.transforms[data.transformId +1] ~= nil and tDelta >= data.transforms[data.transformId +1].time) do
					data.transformId = data.transformId +1
					t = data.transforms[data.transformId]
				end
				local pos,rot = ent:GetBoneTransform(boneId)
				local time = t.time
				--print(pos,",",rot)
				--print(t.pos,",",t.rot)
				--print(pos,",",t.pos)
				pos = t.pos or pos
				--pos = ent:WorldToLocal(pos)
				rot = t.rot or rot
				local tNext = data.transforms[data.transformId +1]
				if(tNext ~= nil) then
					local tDiff = tNext.time -time
					local interp = (tDiff > 0.0) and ((tDelta -time) /tDiff) or 0.0
					if(tNext.pos ~= nil) then pos = pos:Lerp(tNext.pos,interp) end
					if(tNext.rot ~= nil) then rot = rot:Slerp(tNext.rot,interp) end
				end
				ent:SetBoneTransform(boneId,pos,rot)
			end
				
			-- Update flexes
			for flexControllerId,data in pairs(actorFlexTransforms) do
				local t = data.transforms[data.transformId]
				while(data.transforms[data.transformId +1] ~= nil and tDelta >= data.transforms[data.transformId +1].time) do
					data.transformId = data.transformId +1
					t = data.transforms[data.transformId]
				end
				local time = t.time
				local v = t.value
				local tNext = data.transforms[data.transformId +1]
				if(tNext ~= nil) then
					local tDiff = tNext.time -time
					local interp = (tDiff > 0.0) and ((tDelta -time) /tDiff) or 0.0
					v = math.lerp(v,tNext.value,interp)
				end
				--print(mdl:GetFlexControllerName(flexControllerId),v)
				--if(flexControllerId == mdl:GetFlexControllerId("LipLoV")) then
				if(flexControllerId == 18 or flexControllerId == 21 or flexControllerId == 22) then
					--print(data.name,v)
					ent:SetFlexController(flexControllerId,v)
				end
				--end
			end
		end
	end)]]
end

--[[function dmx.Scene:InitializeCamera(cam)
	
end]]

function dmx.Scene:InitializeSession(el)
	local clip = el:GetAttributeValue("activeClip")
	
	local sceneComponent = self.m_scene:GetComponent(ents.COMPONENT_PFM_SCENE)
	-- Retrieve time span
	sceneComponent:SetTimeSpan(self:GetTimeFrame(clip))
	--
	
	local subClipTrackGroup = clip:GetAttributeValue("subClipTrackGroup")
	for _,attrTrack in pairs(subClipTrackGroup:GetAttributeValue("tracks")) do
		local track = attrTrack:GetValue()
		for _,attrChild in ipairs(track:GetAttributeValue("children")) do
			local child = attrChild:GetValue()
			
			local sceneTrack = sceneComponent:AddTrack(child:GetName(),self:GetTimeFrame(child))
			local trackComponent = sceneTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
			for _,attrAnimSet in ipairs(child:GetAttributeValue("animationSets")) do
				local animSet = attrAnimSet:GetValue()
				self:InitializeAnimationSet(sceneTrack,animSet)
			end
			
			local cam = child:GetAttributeValue("camera")
			if(cam ~= nil) then
				local pos,rot = self:GetTransform(cam)
				trackComponent:AddCamera(cam:GetName(),pos,rot)
			end
			
			local cam = child:GetAttributeValue("camera")
			if(cam ~= nil and cam:GetType() == "DmeCamera") then
				local pos,rot = self:GetTransform(cam)
				trackComponent:SetCamPos(pos)
				trackComponent:SetCamRot(rot)
			end
			for _,attrTrackGroup in ipairs(child:GetAttributeValue("trackGroups")) do
				local trackGroup = attrTrackGroup:GetValue()
				for _,attrTrack in ipairs(trackGroup:GetAttributeValue("tracks")) do
					local track = attrTrack:GetValue()
					for _,attrChild in ipairs(track:GetAttributeValue("children")) do
						local child = attrChild:GetValue()
						local name = child:GetName()
						local actor = trackComponent:GetActor(name)
						if(actor ~= nil) then
							actor:GetComponent(ents.COMPONENT_PFM_ACTOR):SetTimeSpan(self:GetTimeFrame(child))
						end
						
						--[[local cam = sceneTrack:GetCamera(name)
						if(cam ~= nil) then
							self:LoadCameraData(child,cam)
						end]]
					end
				end
			end
		end
	end
	
	for _,attrTrackGroup in ipairs(clip:GetAttributeValue("trackGroups")) do
		local trackGroup = attrTrackGroup:GetValue()
		if(trackGroup:GetAttributeValue("mute") == false) then
			for _,attrAudio in ipairs(trackGroup:GetAttributeValue("tracks")) do
				local audio = attrAudio:GetValue()
				for _,attrChild in ipairs(audio:GetAttributeValue("children")) do
					local child = attrChild:GetValue()
					if(child:GetAttributeValue("mute") == false) then
						local start,duration = self:GetTimeFrame(child)
						local track = sceneComponent:AddTrack(child:GetName(),start,duration)
						local trackComponent = track:GetComponent(ents.COMPONENT_PFM_TRACK)
						
						local sound = child:GetAttributeValue("sound")
						local soundName = sound:GetAttributeValue("soundname")
						if(#soundName > 0) then
							local prefix = soundName:sub(1,1)
							while(prefix == "#" or prefix == ")") do
								soundName = soundName:sub(2)
								prefix = soundName:sub(1,1)
							end
						end
						local gameSoundName = sound:GetAttributeValue("gameSoundName")
						local volume = sound:GetAttributeValue("volume")
						local pitch = sound:GetAttributeValue("pitch")
						local origin = sound:GetAttributeValue("origin")
						local y = origin.y
						origin.y = origin.z
						origin.z = -y
						local direction = sound:GetAttributeValue("direction")
						local y = direction.y
						direction.y = direction.z
						direction.z = -y
						local channel = sound:GetAttributeValue("channel")
						local level = sound:GetAttributeValue("level")
						trackComponent:AddSoundEvent(soundName,start,duration,volume,pitch /100.0,origin,direction)
					end
				end
			end
		end
	end
end

import.import_dmx_scene = function(sceneFile,origin)
	local scene = dmx.Scene()
	if(scene:Import(sceneFile) == false) then return end
	--scene.m_scene:SetCameraEnabled(false)
	--scene.m_scene:SetOffsetTransform(origin,EulerAngles(180,180,0):ToQuaternion())
	return scene:GetPFMScene()
end
