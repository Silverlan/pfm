--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMPlayer",BaseEntityComponent)

ents.PFMPlayer.TAUNT_SOUNDS = {"scout_cheers03"}
function ents.PFMPlayer:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_LOGIC)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)

	-- TODO: This is here because something seems to be off with the player render bounds. Remove this line once that's fixed
	renderC:SetExemptFromOcclusionCulling(true)

	self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
	self.m_precached = false
	self.m_taunting = false
end

function ents.PFMPlayer:PrecacheSounds()
	if(self.m_precached) then return end
	self.m_precached = true
	for _,snd in ipairs(ents.PFMPlayer.TAUNT_SOUNDS) do
		sound.precache(snd,sound.FCREATE_MONO)
	end
end

function ents.PFMPlayer:OnTick()
	local ent = self:GetEntity()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return end
	local vel = ent:GetVelocity()
	local speed = vel:Length()
	vel:Rotate(ent:GetRotation():GetInverse())

	vel.y = 0.0 -- We only care about the velocity on the xz plane
	vel:Normalize() -- Probably not necessary
	local v = math.atan2(vel.x,vel.z) /math.pi
	animC:SetBlendController("move_y",v)

	local maxSpeed = 326.0 -- TODO: We should use the max speed as defined for the player, but due to a bug the actual max speed is lower. FIXME
	local f = 1.0 -speed /maxSpeed
	animC:SetBlendController("move_x",f)
end

function ents.PFMPlayer:OnRemove()
	self:ClearTaunt()
end

function ents.PFMPlayer:IsTaunting() return self.m_taunting end

function ents.PFMPlayer:ClearTaunt()
	self.m_taunting = false
	if(util.is_valid(self.m_cbHandleActionInput)) then self.m_cbHandleActionInput:Remove() end
	if(util.is_valid(self.m_cbOnAnimationComplete)) then self.m_cbOnAnimationComplete:Remove() end
end

function ents.PFMPlayer:Taunt()
	if(self:IsTaunting()) then return end
	self.m_taunting = true
	self:PrecacheSounds()

	local ent = self:GetEntity()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	local mdl = ent:GetModel()
	if(animC == nil or mdl == nil) then return end
	local animId = mdl:LookupAnimation("taunt01")
	animC:PlayAnimation(animId)

	local charC = ent:GetComponent(ents.COMPONENT_CHARACTER)
	if(charC ~= nil) then
		local sndE = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
		if(sndE ~= nil) then
			local snd = table.random(ents.PFMPlayer.TAUNT_SOUNDS)
			snd = sndE:EmitSound("vo/" .. snd .. ".mp3",sound.TYPE_VOICE)
		end
	end
	local pl = ent:GetComponent(ents.COMPONENT_PLAYER)
	if(pl ~= nil) then
		self.m_cbHandleActionInput = pl:AddEventCallback(ents.PlayerComponent.EVENT_HANDLE_ACTION_INPUT,function(action,pressed,magnitude)
			return util.EVENT_REPLY_HANDLED
		end)
	end
	self.m_cbOnAnimationComplete = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATION_COMPLETE,function(animation,activity)
		if(animation == animId) then
			self:ClearTaunt()
		end
	end)
end
ents.COMPONENT_PFM_PLAYER = ents.register_component("pfm_player",ents.PFMPlayer)
