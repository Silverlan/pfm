include("sfm.lua")
include("/pfm/pfm.lua")
--[[
include("demo/scenes/sfm/dmx_scene_loader.lua")

local dmxTestScene = import.import_dmx("lua/mtt_engineer.dmx",Vector())



if(true) then return end]]

-- Input SFM scene
print("Loading SFM scene...")
local sfmScene = sfm.import_scene("lua/mtt_engineer.dmx")
if(sfmScene == nil) then return end

local function initialize_track(pfmScene,sfmTrack)
	local track = pfmScene:AddTrack(sfmTrack:GetName())
	track:SetMuted(sfmTrack:IsMuted())
	track:SetVolume(sfmTrack:GetVolume())
	--[[for _,soundClip in ipairs(sfmTrack:GetSoundClips()) do
		print("Adding clip " .. soundClip:GetName() .. " to track " .. track:GetName())
		local audioClip = track:AddAudioClip(soundClip:GetName())
		soundClip:ToPFMAudioClip(audioClip)
	end]]
	for _,sfmFilmClip in ipairs(sfmTrack:GetFilmClips()) do
		local filmClip = track:AddFilmClip(sfmFilmClip:GetName())
		sfmFilmClip:ToPFMFilmClip(filmClip)
	end
end

local function initialize_clips(pfmScene,clips)
  for _,clip in ipairs(clips) do
    local trackGroups = clip:GetTrackGroups()
    if(trackGroups ~= nil) then
      for _,trackGroup in ipairs(trackGroups) do
        for _,track in ipairs(trackGroup:GetTracks()) do
					initialize_track(pfmScene,track)
        end
      end
    end
    local subClipTrackGroup = clip:GetSubClipTrackGroup()
    if(subClipTrackGroup ~= nil) then
      for _,track in ipairs(subClipTrackGroup:GetTracks()) do
        initialize_track(pfmScene,track)
      end
    end
    
    --print("Clip Name: ",clip:GetType())
    --[[local cam = clip:GetCamera()
    if(cam ~= nil) then
      local t = cam:GetTransform()
      print(t:GetPosition())
    end]]
  end
end

local function create_pfm_scene_from_sfm_scene(sfmScene)
	local scene = pfm.create_scene()
	
	
	for _,session in ipairs(sfmScene:GetSessions()) do
		initialize_clips(scene,session:GetClips())
	end
	return scene
end

--profilerStart()
print("Converting to PFM scene...")
local scene = create_pfm_scene_from_sfm_scene(sfmScene)
--profilerStop()
--profilerReport("profiler.log")

print("Initializing scene entity...")
if(util.is_valid(ents.find_by_class("pfm_scene")[1])) then ents.find_by_class("pfm_scene")[1]:Remove() end
local entScene = ents.create("pfm_scene")
entScene:GetComponent(ents.COMPONENT_PFM_SCENE):SetScene(scene)
entScene:Spawn()

--[[for name,node in pairs(scene:GetUDMRootNode():GetChildren()) do
	if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
		print("Track: ",node:GetName())
		for name,clip in pairs(node:GetAudioClips():GetValue()) do
			print("\tAudio Clip: ",clip:GetName())
		end
	end
end]]

for name,node in pairs(scene:GetUDMRootNode():GetChildren()) do
	if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
		if(node:GetMuted() == false and node:GetName() == "Film") then
			print("Non Muted node found: ",node:GetName())
			entScene:GetComponent(ents.COMPONENT_PFM_SCENE):StartPlayback(node)
			break
		end
	end
end

	--[[local f = file.open("lua/mtt_engineer.dmx",bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return end
	local dmxData = dmx.load(f)
	f:Close()
local str = tostring(dmxData)
f = file.open("mtt_engineer.txt",file.OPEN_MODE_WRITE)
f:WriteString(str)
f:Close()]]

--[[print(sfmScene)
for _,session in ipairs(sfmScene:GetSessions()) do
  local settings = session:GetSettings()
  local movieSettings = settings:GetMovieSettings()
  local videoTarget = movieSettings:GetVideoTarget()
  print("Video Target: ",videoTarget)
end]]

-- lua_exec_cl test_import_sfm.lua
