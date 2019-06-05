util.register_class("ents.PFMSound",BaseEntityComponent)

function ents.PFMSound:__init()
	BaseEntityComponent.__init(self)
end

function ents.PFMSound:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_SOUND)
	
	self.m_soundName = soundName
	self.m_volume = volume
	self.m_pitch = pitch
	self.m_origin = origin
	self.m_direction = direction
end

function ents.PFMSound:OnStart()
	if(self:GetSoundName() ~= "mixes\\meet_the_engineer\\mtt_engineer_m17_44khz.wav") then return end -- Dirty hack for Meet the Engineer, fix this once cinematic scenes are implemented properly
	local snd = sound.create(self:GetSoundName(),sound.TYPE_EFFECT)
	if(snd ~= nil) then
		snd:SetGain(self:GetVolume())
		snd:SetPitch(self:GetPitch())
		snd:SetPos(self:GetOrigin())
		snd:SetDirection(self:GetDirection())
		snd:Play()
		self.m_sound = snd
	end
end
function ents.PFMSound:OnStop()
	if(self.m_sound ~= nil) then
		self.m_sound:Stop()
		self.m_sound = nil
	end
end

ents.COMPONENT_PFM_SOUND = ents.register_component("pfm_sound",ents.PFMSound)
