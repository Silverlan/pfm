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
function shader.PFMParticleSpriteTrail:Draw(drawCmd,ps,renderer,bloom,minLength,maxLength,lengthFadeInTime,animRate)
	if(self:RecordBeginDraw(drawCmd,ps) == false) then return end
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

	self:RecordDraw(renderer,ps,bloom)
	self:RecordEndDraw()
end
shader.register("pfm_particle_sprite_trail",shader.PFMParticleSpriteTrail)
