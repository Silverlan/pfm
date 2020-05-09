--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerPositionWithinSphere",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerPositionWithinSphere:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerPositionWithinSphere:Initialize()
	self.m_distanceMin = tonumber(self:GetKeyValue("distance_min") or "0")
	self.m_distanceMax = tonumber(self:GetKeyValue("distance_max") or "0")
	self.m_distanceBias = vector.create_from_string(self:GetKeyValue("distance_bias") or "1 1 1")
	self.m_distanceBiasAbsoluteValue = vector.create_from_string(self:GetKeyValue("distance_bias_absolute_value") or "0 0 0")
	self.m_biasInLocalSystem = toboolean(self:GetKeyValue("bias in local system") or "0")
	self.m_controlPointNumber = tonumber(self:GetKeyValue("control_point_number") or "0")
	self.m_speedMin = tonumber(self:GetKeyValue("speed_min") or "0")
	self.m_speedMax = tonumber(self:GetKeyValue("speed_max") or "0")
	self.m_speedRandomExponent = tonumber(self:GetKeyValue("speed_random_exponent") or "1")
	self.m_speedInLocalCoordinateSystemMin = vector.create_from_string(self:GetKeyValue("speed_in_local_coordinate_system_min") or "0 0 0")
	self.m_speedInLocalCoordinateSystemMax = vector.create_from_string(self:GetKeyValue("speed_in_local_coordinate_system_max") or "0 0 0")
	self.m_createInModel = tonumber(self:GetKeyValue("create in model") or "0")
	self.m_randomlyDistributeToHighestSuppliedControlPoint = toboolean(self:GetKeyValue("randomly distribute to highest supplied Control Point") or "0")
	self.m_randomlyDistributionGrowthTime = tonumber(self:GetKeyValue("randomly distribution growth time") or "0")

	self.m_hasDistanceBias = (self.m_distanceBias.x ~= 1.0 and self.m_distanceBias.y ~= 1.0 and self.m_distanceBias.z ~= 1.0)
	self.m_hasDistanceBiasAbs = (self.m_distanceBiasAbsoluteValue.x ~= 0.0 and self.m_distanceBiasAbsoluteValue.y ~= 0.0 and self.m_distanceBiasAbsoluteValue.z ~= 0.0)
end
function ents.ParticleSystemComponent.InitializerPositionWithinSphere:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerPositionWithinSphere:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerPositionWithinSphere:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local randPos = Vector()
	local randDir = Vector()
	for nTryCtr=0,9 do
		local nCurrentControlPoint = m_nControlPointNumber;
		local len
		randPos,len = RandomVectorInUnitSphere()
		-- Absolute value and biasing for creating hemispheres and ovoids.
		if(self.m_hasDistanceBiasAbs) then
			if(self.m_distanceBiasAbsoluteValue.x ~= 0.0) then
				randPos.x = math.abs(randPos.x)
			end
			if(self.m_distanceBiasAbsoluteValue.y ~= 0.0) then
				randPos.y = math.abs(randPos.y)
			end
			if(self.m_distanceBiasAbsoluteValue.z ~= 0.0) then
				randPos.z = math.abs(randPos.z)
			end
		end
		randPos = randPos *self.m_distanceBias
		randPos:Normalize()
			
		randDir = randPos
		randPos = randPos *math.lerp(self.m_distanceMin,self.m_distanceMax,len)
			
		if(self.m_hasDistanceBias == false or self.m_biasInLocalSystem == false) then
			local vecControlPoint = GetControlPointAtTime( self,nCurrentControlPoint, pt:GetTimeCreated() )
			randPos = randPos +vecControlPoint
		else
			local t = GetControlPointTransformAtTime(self, nCurrentControlPoint, pt:GetTimeCreated() )
			local vecTransformLocal = Vector()
			randPos = t *randPos
		end
			
		-- now, force to be in model if we can
		if (
			( self.m_createInModel == 0 ) or 
			(g_pParticleSystemMgr:Query():MovePointInsideControllingObject( 
				pParticles, pParticles.m_ControlPoints[nCurrentControlPoint].m_pObject, randPos ) ) ) then
			break
		end
	end
	pt:SetPosition(randPos)

	local pOffset = Vector()
	if(self.m_speedMax > 0.0) then
		local randSpeed = self.m_speedMin +(math.randomf(0.0,self.m_speedMax -self.m_speedMin) ^self.m_speedRandomExponent)
		pOffset = pOffset -randSpeed *randDir
	end
	pOffset =
		pOffset -
		math.randomf(self.m_speedInLocalCoordinateSystemMin.x,self.m_speedInLocalCoordinateSystemMax.x)*
		GetControlPointPose(self,nCurrentControlPoint):GetRotation():GetForward()
	pOffset =
		pOffset -
		math.randomf(self.m_speedInLocalCoordinateSystemMin.y,self.m_speedInLocalCoordinateSystemMax.y)*
		GetControlPointPose(self,nCurrentControlPoint):GetRotation():GetRight()
	pOffset =
		pOffset -
		math.randomf(self.m_speedInLocalCoordinateSystemMin.z,self.m_speedInLocalCoordinateSystemMax.z)*
		GetControlPointPose(self,nCurrentControlPoint):GetRotation():GetUp()

	local prevDt = 0.04166666790843 -- TODO
	pOffset = pOffset *prevDt
	randPos = randPos +pOffset
	SetPrevPos(pt:GetIndex(),randPos)
			--[[poffset *= pParticles->m_flPreviousDt;
			randpos += poffset;
			pxyz[0] = randpos.x;
			pxyz[4] = randpos.y;
			pxyz[8] = randpos.z;]]

	--pt:SetVelocity(pt:GetVelocity() +pOffset)

	--[[pOffset = pOffset *pParticles->m_flPreviousDt;
	randPos = randPos +pOffset;
	pxyz[0] = randPos.x;
	pxyz[4] = randPos.y;
	pxyz[8] = randPos.z;]]
end
function ents.ParticleSystemComponent.InitializerPositionWithinSphere:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("position_within_sphere",ents.ParticleSystemComponent.InitializerPositionWithinSphere)
