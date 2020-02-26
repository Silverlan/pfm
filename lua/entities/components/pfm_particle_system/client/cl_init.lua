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
end
function ents.PFMParticleSystem:OnTick(dt)
	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	ptC:Simulate(dt)
end
function ents.PFMParticleSystem:OnOffsetChanged(offset)
	local dt = offset -self.m_lastSimulationOffset
	self.m_lastSimulationOffset = offset

	local ptC = self:GetEntity():GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	-- ptC:Simulate(1 /60.0)--dt)
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
	return Vector(-v.x,v.z,-v.y)
end
function ents.PFMParticleSystem:InitializeParticleSystem()
	local particleData = self.m_particleData
	local def = particleData:GetDefinition()
	local numParticles = def:GetMaxParticles()
	if(numParticles == 0) then return end

	local ent = self:GetEntity()
	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	-- TODO: File extension should be removed during SFM -> Pragma conversion!
	local material = file.remove_file_extension(def:GetMaterial())
	local radius = def:GetRadius()
	ent:SetKeyValue("maxparticles",tostring(numParticles))
	ent:SetKeyValue("material",material)
	ent:SetKeyValue("radius",tostring(radius))
	ent:SetKeyValue("lifetime",tostring(def:GetLifetime()))
	ent:SetKeyValue("color",tostring(def:GetColor()))
	ent:SetKeyValue("sort_particles",tostring(def:ShouldSortParticles()))
	ent:SetKeyValue("emission_rate","100") -- -- TODO: Emitter tostring(1))--tostring(numParticles))
	ent:SetKeyValue("loop","1")
	ent:SetKeyValue("auto_simulate","0")
	print("MATERIAL: ",material)
	--particleData:DebugPrint()
	--ent:SetKeyValue("transform_with_emitter","1")

	for _,rendererData in ipairs(def:GetRenderers():GetTable()) do
		local name = rendererData:GetName()
		if(string.compare(name,"render_animated_sprites",false)) then
			ptC:AddRenderer("sprite",{})
		else
			pfm.log("Unsupported particle system renderer '" .. name .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
		end
	end
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
				velocity_min = tostring(speedInLocalCoordinateSystemMin /4.0),
				velocity_max = tostring(speedInLocalCoordinateSystemMax /4.0)
			})
		elseif(string.compare(name,"radius random",false)) then
			ptC:AddInitializer("radius_random",{
				radius_min = tostring(initializerData:GetProperty("radius_min"):GetValue()),
				radius_max = tostring(initializerData:GetProperty("radius_max"):GetValue())
			})
		else
			pfm.log("Unsupported particle system renderer '" .. name .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
		end
	end
	local cp = particleData:GetControlPoints():Get(1)
	if(cp ~= nil) then
		table.insert(self.m_listeners,cp:GetPositionAttr():AddChangeListener(function(newPos)
			self:GetEntity():SetPos(newPos)
		end))
	end
	ptC:Start()
end
function ents.PFMParticleSystem:Setup(actorData,particleData)
	self.m_particleData = particleData
end
ents.COMPONENT_PFM_PARTICLE_SYSTEM = ents.register_component("pfm_particle_system",ents.PFMParticleSystem)
