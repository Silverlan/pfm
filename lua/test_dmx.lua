local r = engine.load_library("pr_dmx")
if(r ~= true) then
	print("WARNING: An error occured trying to load the 'pr_dmx' module: ",r)
	return
end

local f = file.open("scenes/test_tex.dmx",bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
if(f == nil) then return end
local dmxData,msg = dmx.load(f)
f:Close()

if(dmxData == false) then
	print("An error has occured: ",msg)
	return
end

local rootAttr = dmxData:GetRootAttribute()

local session = rootAttr:Get("session")
local clip = session:GetAttrV("activeClip")
local mapName = clip:GetAttrV("mapname")

local subClipTrackGroup = clip:GetAttrV("subClipTrackGroup")
local tracks = subClipTrackGroup:GetAttrV("tracks")
for _,track in ipairs(tracks) do
	local elTrack = track:GetValue()
	for _,child in ipairs(elTrack:GetAttrV("children")) do
		local elChild = child:GetValue()
		local camera = elChild:GetAttrV("camera")
		local scene = elChild:GetAttrV("scene")
		local animSets = elChild:GetAttrV("animationSets")
		for _,animSet in ipairs(animSets) do
			local elAnimSet = animSet:GetValue()
			local gameModel = elAnimSet:GetAttrV("gameModel")
			local modelName = gameModel:GetAttrV("modelName")
			print(modelName)
		end
	end
end
--[[local animSets = clip:GetAttrV("animationSets")
print(#animSets)
for _,animSet in ipairs(animSets) do
	print(animSet:GetName())
end

tracks
Film -> children[1] (Shot1)]]

--print(rootAttr:Get("session"):GetAttrV("settings"):GetAttrV("renderSettings"):GetAttrV("frameRate"))

--[[
local fDbg = file.open("scenes/scene_log.txt",bit.bor(file.OPEN_MODE_WRITE))
fDbg:WriteString(tostring(dmxData))
fDbg:Close()]]


--local rootElements = dmxData:GetRootElements()

--dmxData:Get("session"):Get("settings"):Get("movieSettings"):Get("videoTarget")
--local session = rootElements

-- lua_exec_cl test_dmx.lua
