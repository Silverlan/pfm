--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMParticleSpriteTrail",shader.BaseParticle2D)

shader.PFMParticleSpriteTrail.FragmentShader = "particles/fs_particle"
shader.PFMParticleSpriteTrail.VertexShader = "pfm/particles/vs_particle_sprite_trail"
function shader.PFMParticleSpriteTrail:__init()
	shader.BaseParticle2D.__init(self)

	self.m_dsPushConstants = util.DataStream(shader.BaseParticle2D.PUSH_CONSTANTS_SIZE +util.SIZEOF_FLOAT *4)
end
function shader.PFMParticleSpriteTrail:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseParticle2D.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachPushConstantRange(shader.BaseParticle2D.PUSH_CONSTANTS_USER_DATA_OFFSET,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))
end
function shader.PFMParticleSpriteTrail:CalcVertexPosition(ptc,ptIdx,localVertIdx,posCam,camUp,camRight)
	-- Note: This has to match the calculations performed in the vertex shader
	local renderer = ptc:GetRenderers()[1]
	if(renderer == nil) then return posCam:Copy() end
	local pt = ptc:GetParticle(ptIdx)
	local ptWorldPos = pt:GetPosition()
	local ptPrevWorldPos = pt:GetPreviousPosition()
	local dtPosWs = ptPrevWorldPos -ptWorldPos
	local l = dtPosWs:Length()
	dtPosWs:Normalize()

	local dt = 1.0 /(1.0 /100.0) -- 100 is arbitrary, try using actual delta time!
	local age = pt:GetTimeAlive()
	local lengthFadeInTime = renderer:GetLengthFadeInTime()
	local lengthScale = (age >= lengthFadeInTime) and 1.0 or (age /lengthFadeInTime)
	local ptLen = pt:GetLength()
	l = lengthScale *l *ptLen -- *dt
	l = math.log(l +2) *12;
	if(l <= 0.0) then return posCam:Copy() end
	l = math.clamp(l,renderer:GetMinLength(),renderer:GetMaxLength())

	local rad = math.min(pt:GetRadius(),l)
	dtPosWs = dtPosWs *l

	local dirToBeam = ptWorldPos -posCam
	local tangentY = dirToBeam:Cross(dtPosWs)
	tangentY:Normalize()

	if(localVertIdx == 0) then return ptWorldPos -tangentY *rad *0.5 end
	if(localVertIdx == 1) then return ptWorldPos +tangentY *rad *0.5 end
	if(localVertIdx == 2) then return (ptWorldPos +tangentY *rad *0.5) +dtPosWs end
	return (ptWorldPos -tangentY *rad *0.5) +dtPosWs
end
function shader.PFMParticleSpriteTrail:Draw(drawCmd,ps,renderer,renderFlags,minLength,maxLength,lengthFadeInTime,animRate)
	if(self:RecordBeginDraw(drawCmd,ps,renderFlags) == false) then return end
	local dsLightSources = renderer:GetLightSourceDescriptorSet()
	local dsShadows = renderer:GetPSSMTextureDescriptorSet()
	self:RecordBindLights(dsShadows,dsLightSources)
	self:RecordBindRenderSettings(game.get_render_settings_descriptor_set())
	self:RecordBindSceneCamera(renderer,ps:GetRenderMode() == ents.RenderComponent.RENDERMODE_VIEW)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteFloat(minLength)
	self.m_dsPushConstants:WriteFloat(maxLength)
	self.m_dsPushConstants:WriteFloat(lengthFadeInTime)
	self.m_dsPushConstants:WriteFloat(animRate)
	self:RecordPushConstants(self.m_dsPushConstants,shader.BaseParticle2D.PUSH_CONSTANTS_USER_DATA_OFFSET)

	self:RecordDraw(renderer,ps,renderFlags)
	self:RecordEndDraw()
end
shader.register("pfm_particle_sprite_trail",shader.PFMParticleSpriteTrail)
