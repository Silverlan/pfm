util.register_class("ents.PFMScene",BaseEntityComponent)

function ents.PFMScene:__init()
	BaseEntityComponent.__init(self)
end

function ents.PFMScene:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_tracks = {}
	self.m_start = 0.0
	self.m_duration = 0.0
	self.m_bCameraEnabled = true
end

function ents.PFMScene:Start()
	for _,track in ipairs(self.m_tracks) do
		if(self.m_offsetTransform ~= nil) then
			track:SetOffsetTransform(self.m_offsetTransform[1],self.m_offsetTransform[2])
		end
		track:SetCameraEnabled(self.m_bCameraEnabled)
	end
	local tStart
	self.m_cbThink = game.add_callback("Think",function()
		tStart = tStart or time.cur_time()
		local t = time.cur_time()
		local tDelta = t -tStart
		if(tDelta < self.m_start) then return end
		if((tDelta -self.m_start) >= self.m_duration) then
			self:Stop()
			return
		end
		for _,track in ipairs(self.m_tracks) do
			track:Run(tDelta)
		end
	end)
end

function ents.PFMScene:Stop()
	if(util.is_valid(self.m_cbThink)) then
		self.m_cbThink:Remove()
		self.m_cbThink = nil
	end
	for _,track in ipairs(self.m_tracks) do track:Stop() end
end

function ents.PFMScene:SetOffsetTransform(pos,rot)
	self.m_offsetTransform = {pos,rot}
end

function ents.PFMScene:SetCameraEnabled(b) self.m_bCameraEnabled = b end

function ents.PFMScene:SetTimeSpan(start,duration)
	self.m_start = start
	self.m_duration = duration
end
function ents.PFMScene:GetTimeSpan() return self.m_start,self.m_duration end

function ents.PFMScene:AddTrack(name,start,dur,offset)
	for _,track in ipairs(self.m_tracks) do
		if(track:GetName() == name) then return track end
	end
	table.insert(self.m_tracks,ents.PFMScene.Track(name,start,dur,offset))
	return self.m_tracks[#self.m_tracks]
end

ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene",ents.PFMScene)
