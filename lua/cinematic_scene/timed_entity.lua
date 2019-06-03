util.register_class("CinematicScene.TimedEntity")
function CinematicScene.TimedEntity:__init(start,dur,offset)
	self.m_start = start
	self.m_duration = dur
	self.m_offset = offset or 0.0
	self:Stop()
end
function CinematicScene.TimedEntity:SetTimeSpan(start,duration,offset)
	self.m_start = start
	self.m_duration = duration
	self.m_offset = offset or self.m_offset
end
function CinematicScene.TimedEntity:GetStartTime() return self.m_start end
function CinematicScene.TimedEntity:GetDuration() return self.m_duration end
function CinematicScene.TimedEntity:GetOffset() return self.m_offset end
function CinematicScene.TimedEntity:GetTimeSpan() return self.m_start,self.m_duration end
function CinematicScene.TimedEntity:OnStart(t) end
function CinematicScene.TimedEntity:OnStop(t) end
function CinematicScene.TimedEntity:OnRun(t) end
function CinematicScene.TimedEntity:Start(t)
	if(self.m_bRunning == true) then return end
	self.m_bRunning = true
	self.m_lastSoundEvent = 0
	self:OnStart(t)
end
function CinematicScene.TimedEntity:Stop(t)
	if(self.m_bRunning == false) then return end
	self.m_bRunning = false
	self.m_lastSoundEvent = nil
	self:OnStop(t)
end
function CinematicScene.TimedEntity:Run(t)
	if(t < self.m_start) then return end
	if(t >= self.m_start +self.m_duration) then
		self:Stop(t)
		return
	end
	if(self.m_bRunning == false) then self:Start(t) end
	self:OnRun(t)
end
