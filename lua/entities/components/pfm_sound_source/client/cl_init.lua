util.register_class("ents.PFMSoundSource",BaseEntityComponent)
function ents.PFMSoundSource:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_SOUND)
end

function ents.PFMSoundSource:OnRemove()
	if(util.is_valid(self.m_cbOnOffsetChanged)) then self.m_cbOnOffsetChanged:Remove() end
	if(self.m_sound ~= nil) then self.m_sound:Stop() end
end

function ents.PFMSoundSource:Setup(clipC,sndInfo)
	self.m_clipComponent = clipC
	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,function(offset)
		self:OnOffsetChanged(offset)
		return util.EVENT_REPLY_UNHANDLED
	end)
	
	self:GetEntity():SetKeyValue("spawnflags","16") -- Play on spawn
	local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if(sndC ~= nil) then
		sndC:SetSoundSource(sndInfo:GetSoundName())
		sndC:SetRelativeToListener(true)
		sndC:SetPitch(sndInfo:GetPitch())
		sndC:SetGain(sndInfo:GetVolume())
	end
end

function ents.PFMSoundSource:OnEntitySpawn()
	local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if(sndC ~= nil) then
		sndC:PlaySound()
		print("Playing sound...")
	end
end

function ents.PFMSoundSource:OnOffsetChanged(offset)
	local soundC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if(soundC == nil) then return end
	local snd = soundC:GetSound()
	if(snd == nil) then return end
	print("CHANGING SOUND OFFSET!!!")
	-- snd:SetOffset() -- TODO: In Range [0,1]
end
ents.COMPONENT_PFM_SOUND_SOURCE = ents.register_component("pfm_sound_source",ents.PFMSoundSource)
