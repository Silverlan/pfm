--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function calc_rotation_matrix_around_axis(axis,ang)
	ang = math.rad(ang)
	local sin = math.sin(ang)
	local cos = math.cos(ang)
	local xSq = axis.x *axis.x
	local ySq = axis.y *axis.y
	local zSq = axis.z *axis.z
	local m = math.Mat3x4()

	-- Column 0:
	m:Set(0,0,xSq +(1 -xSq) *cos)
	m:Set(1,0,axis.x *axis.y *(1 -cos) +axis.z *sin)
	m:Set(2,0,axis.z *axis.x *(1 -cos) -axis.y *sin)

	-- Column 1:
	m:Set(0,1,axis.x *axis.y *(1 -cos) -axis.z *sin)
	m:Set(1,1,ySq +(1 -ySq) *cos)
	m:Set(2,1,axis.y *axis.z *(1 -cos) +axis.x *sin)

	-- Column 2:
	m:Set(0,2,axis.z *axis.x *(1 -cos) +axis.y *sin)
	m:Set(1,2,axis.y *axis.z *(1 -cos) -axis.x *sin)
	m:Set(2,2,zSq +(1 -zSq) *cos)

	-- Column 3:
	m:Set(0,3,0)
	m:Set(1,3,0)
	m:Set(2,3,0)
	return m
end

local function rotate_vector(v,m)
	return Vector(
		v:DotProduct(Vector(m:Get(0,0),m:Get(0,1),m:Get(0,2))),
		v:DotProduct(Vector(m:Get(1,0),m:Get(1,1),m:Get(1,2))),
		v:DotProduct(Vector(m:Get(2,0),m:Get(2,1),m:Get(2,2)))
	)
end

util.register_class("shader.PFMParticleRenderAnimatedSprites",shader.BaseParticle2D)

shader.PFMParticleRenderAnimatedSprites.FragmentShader = "particles/fs_particle"
shader.PFMParticleRenderAnimatedSprites.VertexShader = "pfm/particles/vs_particle_animated_sprites"
function shader.PFMParticleRenderAnimatedSprites:__init()
	shader.BaseParticle2D.__init(self)

	self.m_dsPushConstants = util.DataStream(shader.BaseParticle2D.PUSH_CONSTANTS_SIZE +util.SIZEOF_FLOAT)
end
function shader.PFMParticleRenderAnimatedSprites:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseParticle2D.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachPushConstantRange(shader.BaseParticle2D.PUSH_CONSTANTS_USER_DATA_OFFSET,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))
end
function shader.PFMParticleRenderAnimatedSprites:CalcVertexPosition(ptc,ptIdx,localVertIdx,posCam,camUp,camRight)
	-- Note: This has to match the calculations performed in the vertex shader
	local pt = ptc:GetParticle(ptIdx)
	local ptWorldPos = pt:GetPosition()
	-- bool useCamBias = (u_instance.cameraBias != 0.0);
	-- TODO
	--[[if(useCamBias)
	{
		vec3 vEyeDir = normalize(u_renderSettings.posCam -vecWorldPos);
		vEyeDir *= camBias;
		vecWorldPos += vEyeDir;
	}]]

	local rot = pt:GetRotation()
	local yaw = pt:GetRotationYaw()
	local radius = pt:GetRadius()
	local viewToPos = ptWorldPos -posCam
	local l = viewToPos:Length()
	if(l < radius /2.0) then return posCam:Copy() end -- TODO: How to handle this?

	camRight = -camRight
	local camForward = camUp:Cross(camRight)
	camForward:Normalize()
	if(yaw ~= 0.0) then
		local matRot = calc_rotation_matrix_around_axis(camUp,yaw)
		camRight = rotate_vector(camRight,matRot)
	end

	camRight = camRight *radius
	camUp = camUp *radius

	local ca = math.cos(-rot)
	local sa = math.sin(-rot)

	if(localVertIdx == 0) then
		local x = ca -sa
		local y = -ca -sa
		local vecCorner = ptWorldPos +x *camRight
		vecCorner = vecCorner +y *camUp
		return vecCorner
	elseif(localVertIdx == 1) then
		local x = ca +sa
		local y = ca -sa
		local vecCorner = ptWorldPos +x *camRight
		vecCorner = vecCorner +y *camUp
		return vecCorner
	elseif(localVertIdx == 2) then
		local x = -ca +sa
		local y = ca +sa
		local vecCorner = ptWorldPos +x *camRight
		vecCorner = vecCorner +y *camUp
		return vecCorner
	end
	local x = -ca -sa
	local y = -ca +sa
	local vecCorner = ptWorldPos +x *camRight
	vecCorner = vecCorner +y *camUp
	return vecCorner
end
function shader.PFMParticleRenderAnimatedSprites:Draw(drawCmd,ps,renderer,bloom,camBias)
	if(self:RecordBeginDraw(drawCmd,ps) == false) then return end
	local dsLightSources = renderer:GetLightSourceDescriptorSet()
	local dsShadows = renderer:GetPSSMTextureDescriptorSet()
	self:RecordBindLights(dsShadows,dsLightSources)
	self:RecordBindRenderSettings(game.get_render_settings_descriptor_set())
	self:RecordBindSceneCamera(renderer,ps:GetRenderMode() == ents.RenderComponent.RENDERMODE_VIEW)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteFloat(camBias)
	self:RecordPushConstants(self.m_dsPushConstants,shader.BaseParticle2D.PUSH_CONSTANTS_USER_DATA_OFFSET)

	self:RecordDraw(renderer,ps,bloom)
	self:RecordEndDraw()
end
shader.register("pfm_particle_animated_sprites",shader.PFMParticleRenderAnimatedSprites)
