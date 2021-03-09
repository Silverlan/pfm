--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:Initialize()
	self.m_rotAxis = vector.create_from_string(self:GetKeyValue("rotation_axis") or "0 1 0")
	self.m_rotRate = tonumber(self:GetKeyValue("rotation_rate") or "180")
	self.m_controlPoint = tonumber(self:GetKeyValue("control_point_id") or "0")
	self.m_localSpace = toboolean(self:GetKeyValue("use_local_space") or "0")
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:Simulate(pt,dt,strength)
	local rot = self.m_rotRate *dt
	local rotAxis = self.m_rotAxis:Copy()
	if(self.m_localSpace) then
		local pose = GetControlPointTransformAtTime(self,self.m_controlPoint,pt:GetTimeAlive())
		rotAxis:Rotate(pose:GetRotation())
	end

	local vecCPos = GetControlPointTransformAtTime(self,self.m_controlPoint,pt:GetTimeAlive())
	vecCPos = vecCPos:GetOrigin()

	local pos = pt:GetPosition() -vecCPos
	local prevPos = pt:GetPreviousPosition() -vecCPos

	local mat = MatrixBuildRotationAboutAxis(rotAxis,rot)
	--pos = mat *pos
	--prevPos = mat *prevPos
	--local ang = Quaternion(rotAxis,math.rad(rot))--EulerAngles(0,1,0):ToQuaternion()
	--if(pt:GetIndex() == 1) then print(self.m_rotAxis) end
	local ang = Quaternion(Vector(0,1,0),math.rad(rot))
	pos:Rotate(ang)
	prevPos:Rotate(ang)


	pos = Vector(pos.x,pos.y,pos.z)
	prevPos = Vector(prevPos.x,prevPos.y,prevPos.z)

	pos = pos +vecCPos
	pos = pos -pt:GetPosition()
	pos = pos *strength
	-- if(pt:GetIndex() == 1) then print(pos) end
	pt:SetPosition(pt:GetPosition() +pos)

	prevPos = prevPos +vecCPos
	prevPos = prevPos -pt:GetPreviousPosition()
	prevPos = prevPos *strength
	pt:SetPreviousPosition(pt:GetPreviousPosition() +prevPos)
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_movement_rotate_particle_around_axis",ents.ParticleSystemComponent.OperatorMovementRotateParticleAroundAxis)
