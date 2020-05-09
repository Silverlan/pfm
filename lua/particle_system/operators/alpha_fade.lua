--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorAlphaFade",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorAlphaFade:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorAlphaFade:Initialize()
	self.m_startAlpha = tonumber(self:GetKeyValue("start_alpha") or "1")
	self.m_endAlpha = tonumber(self:GetKeyValue("end_alpha") or "0")
	self.m_startFadeInTime = tonumber(self:GetKeyValue("start_fade_in_time") or "0")
	self.m_endFadeInTime = tonumber(self:GetKeyValue("end_fade_in_time") or "0.5")
	self.m_startFadeOutTime = tonumber(self:GetKeyValue("start_fade_out_time") or "0.5")
	self.m_endFadeOutTime = tonumber(self:GetKeyValue("end_fade_out_time") or "1")

	-- Cache off and validate values
	if(self.m_endFadeInTime < self.m_startFadeInTime) then
		self.m_endFadeInTime = self.m_startFadeInTime
	end
	if(self.m_endFadeOutTime < self.m_startFadeOutTime) then
		self.m_endFadeOutTime = self.m_startFadeOutTime
	end
	
	if(self.m_startFadeOutTime < self.m_startFadeInTime) then
		local tmp = self.m_startFadeInTime
		self.m_startFadeInTime = self.m_startFadeOutTime
		self.m_startFadeOutTime = tmp
	end

	if(self.m_endFadeOutTime < self.m_endFadeInTime) then
		local tmp = self.m_endFadeInTime
		self.m_endFadeInTime = self.m_endFadeOutTime
		self.m_endFadeOutTime = tmp
	end
end
function ents.ParticleSystemComponent.OperatorAlphaFade:Simulate(pt,dt)
	-- TODO
	--[[CM128AttributeIterator pCreationTime( PARTICLE_ATTRIBUTE_CREATION_TIME, pParticles );
	CM128AttributeIterator pLifeDuration( PARTICLE_ATTRIBUTE_LIFE_DURATION, pParticles );
	CM128InitialAttributeIterator pInitialAlpha( PARTICLE_ATTRIBUTE_ALPHA, pParticles );
	CM128AttributeWriteIterator pAlpha( PARTICLE_ATTRIBUTE_ALPHA, pParticles );

	fltx4 fl4StartFadeInTime = ReplicateX4( m_flStartFadeInTime );
	fltx4 fl4StartFadeOutTime = ReplicateX4( m_flStartFadeOutTime );
	fltx4 fl4EndFadeInTime = ReplicateX4( m_flEndFadeInTime );
	fltx4 fl4EndFadeOutTime = ReplicateX4( m_flEndFadeOutTime );
	fltx4 fl4EndAlpha = ReplicateX4( m_flEndAlpha );
	fltx4 fl4StartAlpha = ReplicateX4( m_flStartAlpha );

	fltx4 fl4CurTime = pParticles->m_fl4CurTime;
	int nLimit = pParticles->m_nPaddedActiveParticles << 2;
	
	fltx4 fl4FadeInDuration = ReplicateX4( m_flEndFadeInTime - m_flStartFadeInTime );
	fltx4 fl4OOFadeInDuration = ReciprocalEstSIMD( fl4FadeInDuration );

	fltx4 fl4FadeOutDuration = ReplicateX4( m_flEndFadeOutTime - m_flStartFadeOutTime );
	fltx4 fl4OOFadeOutDuration = ReciprocalEstSIMD( fl4FadeOutDuration );

	for ( int i = 0; i < nLimit; i+= 4 )
	{
		fltx4 fl4Age = SubSIMD( fl4CurTime, *pCreationTime );
		fltx4 fl4ParticleLifeTime = *pLifeDuration;
		fltx4 fl4KillMask = CmpGeSIMD( fl4Age, *pLifeDuration );	// takes care of lifeduration = 0 div 0
		fl4Age = MulSIMD( fl4Age, ReciprocalEstSIMD( fl4ParticleLifeTime ) );	// age 0..1
		fltx4 fl4FadingInMask = AndNotSIMD( fl4KillMask, 
											AndSIMD(
												CmpLeSIMD( fl4StartFadeInTime, fl4Age ), CmpGtSIMD(fl4EndFadeInTime, fl4Age ) ) );
		fltx4 fl4FadingOutMask = AndNotSIMD( fl4KillMask,
										  AndSIMD( 
											  CmpLeSIMD( fl4StartFadeOutTime, fl4Age ), CmpGtSIMD(fl4EndFadeOutTime, fl4Age ) ) );
		if ( IsAnyNegative( fl4FadingInMask ) )
		{
			fltx4 fl4Goal = MulSIMD( *pInitialAlpha, fl4StartAlpha );
			fltx4 fl4NewAlpha = SimpleSplineRemapValWithDeltasClamped( fl4Age, fl4StartFadeInTime, fl4FadeInDuration, fl4OOFadeInDuration,
																	   fl4Goal, SubSIMD( *pInitialAlpha, fl4Goal ) );

			*pAlpha = MaskedAssign( fl4FadingInMask, fl4NewAlpha, *pAlpha );
		}
		if ( IsAnyNegative( fl4FadingOutMask ) )
		{
			fltx4 fl4Goal = MulSIMD( *pInitialAlpha, fl4EndAlpha );
			fltx4 fl4NewAlpha = SimpleSplineRemapValWithDeltasClamped( fl4Age, fl4StartFadeOutTime, fl4FadeOutDuration, fl4OOFadeOutDuration,
																	   *pInitialAlpha, SubSIMD( fl4Goal, *pInitialAlpha ) );
			*pAlpha = MaskedAssign( fl4FadingOutMask, fl4NewAlpha, *pAlpha );
		}
		if ( IsAnyNegative( fl4KillMask ) )
		{
			int nMask = TestSignSIMD( fl4KillMask );
			if ( nMask & 1 )
				pParticles->KillParticle( i );
			if ( nMask & 2 )
				pParticles->KillParticle( i + 1 );
			if ( nMask & 4 )
				pParticles->KillParticle( i + 2 );
			if ( nMask & 8 )
				pParticles->KillParticle( i + 3 );
		}
		++pCreationTime;
		++pLifeDuration;
		++pInitialAlpha;
		++pAlpha;
	}]]
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("alpha fade and decay",ents.ParticleSystemComponent.OperatorAlphaFade)
