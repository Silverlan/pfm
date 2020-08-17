--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMParticleSystem",BaseEntityComponent)

function ents.PFMParticleSystem:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	self:AddEntityComponent(ents.COMPONENT_LOGIC)
	self:AddEntityComponent("pfm_actor")

	self:BindEvent(ents.PFMActorComponent.EVENT_ON_OFFSET_CHANGED,"OnOffsetChanged")
	self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")

	self.m_listeners = {}
	self.m_lastSimulationOffset = 0.0
	self.m_queuedSimOffset = 0
	self.m_ptSimTime = 0
end
function ents.PFMParticleSystem:OnTick(dt)
	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	--ptC:Simulate(1 /24.0)--dt)
	self:ApplySimulationState()
	if(self.m_queuedSimOffset == 0) then return end

	-- Particles are simulated at 60 ticks per second
	local ptSimRate = 1 /60.0
	local dtAcc = 0.0
	while(self.m_queuedSimOffset > ptSimRate) do
		-- print(self:GetEntity())
		self.m_queuedSimOffset = self.m_queuedSimOffset -ptSimRate

	--local cp0 = self:GetEntity():GetPose() *ptC:GetControlPointPose(0)
	--local cp0Prev = self:GetEntity():GetPose() *ptC:GetPrevControlPointPose(0)
	--debug.draw_line(cp0Prev:GetOrigin(),cp0:GetOrigin(),Color.Red,12)
	--debug.draw_line(cp0:GetOrigin(),cp0:GetOrigin() +Vector(0,100,0),Color.Lime,12)
	--debug.draw_line(cp0Prev:GetOrigin(),cp0Prev:GetOrigin() +Vector(0,100,0),Color.Aqua,12)

		ptC:Simulate(ptSimRate)

		dtAcc = dtAcc +ptSimRate
	end
end
function ents.PFMParticleSystem:OnOffsetChanged(offset)
	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC:IsActive() == false) then return end
	if(self:IsSimulating() == false and (ptC == nil or ptC:IsDying() == false)) then return end
	local dt = offset -self.m_lastSimulationOffset
	self.m_lastSimulationOffset = offset

	if(ptC == nil) then return end
	self.m_queuedSimOffset = self.m_queuedSimOffset +(1 /tool.get_filmmaker():GetFrameRate()) -- TODO: Use dt
	self.m_ptSimTime = self.m_ptSimTime +(1 /tool.get_filmmaker():GetFrameRate())
end
function ents.PFMParticleSystem:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end
function ents.PFMParticleSystem:GetParticleData() return self.m_particleData end
function ents.PFMParticleSystem:OnEntitySpawn()
	self:InitializeParticleSystem()
end
local function convert_vector(v)
	return Vector(v.z,v.y,v.x)
end
function ents.PFMParticleSystem:InitializeParticleSystem()
	local particleData = self.m_particleData
	local def = particleData:GetDefinition()
	local numParticles = def:GetMaxParticles()
	local ptSystemName = particleData:GetParticleSystemName()
	if(ptSystemName == nil) then _ptTest = particleData end
	if(numParticles == 0 and #ptSystemName == 0) then return end

	local ent = self:GetEntity()
	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	-- TODO: File extension should be removed during SFM -> Pragma conversion!
	local material = file.remove_file_extension(def:GetMaterial())
	local radius = def:GetRadius()
	if(#ptSystemName > 0) then
		local ptSystemFileName = "blood_impact" -- TODO: Determine particle system file
		-- TODO: These don't belong here; just for testing purposes
		game.precache_particle_system(ptSystemFileName,true)
		game.precache_particle_system("blood_trail",true)
		game.precache_particle_system("rockettrail",true)
		game.precache_particle_system("flamethrower",true)
		game.precache_particle_system("explosion",true)
		game.precache_particle_system("explosion2",true)
		game.precache_particle_system("stickybomb",true)
		game.precache_particle_system("muzzle_flash",true)
		game.precache_particle_system("bullet_tracers",true)
		game.precache_particle_system("nailtrails",true)
		game.precache_particle_system("sessions/" .. tool.get_filmmaker():GetProject():GetName() .. "_instanced",true)
		ent:SetKeyValue("particle_file",ptSystemFileName)
		ent:SetKeyValue("particle",ptSystemName)
	else
		ent:SetKeyValue("maxparticles",tostring(numParticles))
		ent:SetKeyValue("material",material)
		ent:SetKeyValue("radius",tostring(radius))
		ent:SetKeyValue("lifetime",tostring(def:GetLifetime()))
		ent:SetKeyValue("color",tostring(def:GetColor()))
		ent:SetKeyValue("sort_particles",tostring(def:ShouldSortParticles()))
		ent:SetKeyValue("emission_rate","100") -- -- TODO: Emitter tostring(1))--tostring(numParticles))
		ent:SetKeyValue("loop","1")
	end
	ent:SetKeyValue("auto_simulate","0")
	--ent:SetKeyValue("transform_with_emitter","1")
	--ent:SetKeyValue("transform_with_emitter","1")

	if(#ptSystemName == 0) then
		for _,rendererData in ipairs(def:GetRenderers():GetTable()) do
			local name = rendererData:GetName()
			-- TODO: This doesn't belong here
			if(string.compare(name,"render_animated_sprites",false)) then
				ptC:AddRenderer("sprite",{})
			else
				pfm.log("Unsupported particle system renderer '" .. name .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
			end
		end
		-- TODO: These are just for testing purposes
		ptC:AddInitializer("random_initial_frame",{
			
		})
		ptC:AddOperator("flamethrower",{})
		ptC:AddOperator("animation",{

		})
		for _,operatorData in ipairs(def:GetOperators():GetTable()) do
			local name = operatorData:GetName()
			if(string.compare(name,"radius scale",false)) then
				local radiusStartScale = operatorData:GetProperty("radius_start_scale")
				local radiusEndScale = operatorData:GetProperty("radius_end_scale")
				local startTime = operatorData:GetProperty("start_time")
				local endTime = operatorData:GetProperty("end_time")

				ptC:AddOperator("radius_fade",{
					radius_start = tostring(radius *radiusStartScale:GetValue()),
					radius_end = tostring(radius *radiusEndScale:GetValue()),
					fade_start = tostring(startTime:GetValue()),
					fade_end = tostring(endTime:GetValue())
				})
			elseif(string.compare(name,"color fade",false)) then
				local colorFade = operatorData:GetProperty("color_fade")
				local startTime = operatorData:GetProperty("fade_start_time")
				local endTime = operatorData:GetProperty("fade_end_time")

				ptC:AddOperator("color_fade",{
					color_fade = tostring(colorFade:GetValue()),
					fade_start = tostring(startTime:GetValue()),
					fade_end = tostring(endTime:GetValue())
				})
			elseif(string.compare(name,"movement basic",false) or string.compare(name,"basic_movement",false)) then
				ptC:AddOperator("movement_basic",{

				})
			elseif(string.compare(name,"alpha fade and decay",false)) then
				local startFadeIn = operatorData:GetProperty("start_fade_in_time")
				local endFadeIn = operatorData:GetProperty("end_fade_in_time")
				local startFadeOut = operatorData:GetProperty("start_fade_out_time")
				local endFadeOut = operatorData:GetProperty("end_fade_out_time")
				local startAlpha = operatorData:GetProperty("start_alpha")
				local endAlpha = operatorData:GetProperty("end_alpha")

				--[[ptC:AddOperator("color_fade",{
					alpha_start = "0.0",
					alpha_end = tostring(startAlpha:GetValue()),
					fade_start = tostring(startFadeIn:GetValue()),
					fade_end = tostring(endFadeIn:GetValue())
				})
				ptC:AddOperator("color_fade",{
					alpha_start = tostring(startAlpha:GetValue()),
					alpha_end = tostring(endAlpha:GetValue()),
					fade_start = tostring(startFadeOut:GetValue()),
					fade_end = tostring(endFadeOut:GetValue())
				})]]
			else
				pfm.log("Unsupported particle system renderer '" .. name .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
			end
		end
		for _,initializerData in ipairs(def:GetInitializers():GetTable()) do
			local name = initializerData:GetName()
			if(string.compare(name,"position within sphere random",false)) then
				local speedInLocalCoordinateSystemMin = convert_vector(initializerData:GetProperty("speed_in_local_coordinate_system_min"):GetValue())
				local speedInLocalCoordinateSystemMax = convert_vector(initializerData:GetProperty("speed_in_local_coordinate_system_max"):GetValue())

				ptC:AddInitializer("initial_velocity",{
					velocity_min = tostring(speedInLocalCoordinateSystemMin),
					velocity_max = tostring(speedInLocalCoordinateSystemMax)
				})
			elseif(string.compare(name,"radius random",false)) then
				ptC:AddInitializer("radius_random",{
					radius_min = tostring(initializerData:GetProperty("radius_min"):GetValue()),
					radius_max = tostring(initializerData:GetProperty("radius_max"):GetValue())
				})
			elseif(string.compare(name,"color random",false)) then
				local color1 = initializerData:GetProperty("color1"):GetValue()
				local color2 = initializerData:GetProperty("color2"):GetValue()
				ptC:AddInitializer("color_random",{
					color1 = tostring(color1),
					color2 = tostring(color2)
				})
			else
				pfm.log("Unsupported particle system renderer '" .. name .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
			end
		end
	end
	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	for i,cp in ipairs(particleData:GetControlPoints():GetTable()) do
		table.insert(self.m_listeners,cp:GetPositionAttr():AddChangeListener(function(newPos)
			if(ptC == nil) then return end
			local pose = ptC:GetControlPointPose(i -1)
			pose:SetOrigin(newPos)
			ptC:SetControlPointPose(i -1,pose,self.m_ptSimTime -0.02) -- TODO: FIXME: How to we properly synchronize the film clip time with the particle simulation time?
		end))
		table.insert(self.m_listeners,cp:GetRotationAttr():AddChangeListener(function(newRot)
			local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
			if(ptC == nil) then return end
			local pose = ptC:GetControlPointPose(i -1)
			pose:SetRotation(newRot)
			ptC:SetControlPointPose(i -1,pose,self.m_ptSimTime -0.02) -- TODO: FIXME: How to we properly synchronize the film clip time with the particle simulation time?
		end))
		if(ptC ~= nil) then
			ptC:SetControlPointPosition(i -1,cp:GetPosition())
			ptC:SetControlPointRotation(i -1,cp:GetRotation())
		end
	end
	table.insert(self.m_listeners,particleData:GetSimulatingAttr():AddChangeListener(function(simulating)
		self:UpdateSimulationState()
	end))
	table.insert(self.m_listeners,particleData:GetEmittingAttr():AddChangeListener(function(emitting)
		self:UpdateSimulationState()
	end))
	self:UpdateSimulationState()
end
function ents.PFMParticleSystem:UpdateSimulationState()
	self.m_simulating = (self.m_particleData:IsSimulating() and self.m_particleData:IsEmitting())
end
function ents.PFMParticleSystem:ApplySimulationState()
	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC ~= nil) then
		if(self:IsSimulating() == false) then
			if(ptC:IsActive() and ptC:IsDying() == false) then ptC:Die() end
		elseif(ptC:IsActive() == false) then
			ptC:Start()
			self.m_ptSimTime = 0.0
		end
	end
end
function ents.PFMParticleSystem:IsSimulating() return self.m_simulating end
function ents.PFMParticleSystem:Setup(actorData,particleData)
	self.m_particleData = particleData
end
ents.COMPONENT_PFM_PARTICLE_SYSTEM = ents.register_component("pfm_particle_system",ents.PFMParticleSystem)
