--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.PragmaRenderJob")
function pfm.PragmaRenderJob:__init(renderSettings)
	self.m_progress = 0.0
	self.m_renderSettings = renderSettings
end
function pfm.PragmaRenderJob:Clear()
	util.remove(self.m_cbPreRenderScenes)
	util.remove(self.m_cbPostRenderScenes)
	if(util.is_valid(self.m_scene)) then self.m_scene:GetEntity():Remove() end
	if(util.is_valid(self.m_renderer)) then self.m_renderer:GetEntity():Remove() end
end
function pfm.PragmaRenderJob:RenderScene(immediate)
	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfo.scene = self.m_scene
	drawSceneInfo.renderFlags = bit.bor(bit.band(drawSceneInfo.renderFlags,bit.bnot(game.RENDER_FLAG_BIT_VIEW)),game.RENDER_FLAG_HDR_BIT) -- Don't render view models
	drawSceneInfo.commandBuffer = self.m_drawCommandBuffer
	if(immediate) then
		game.render_scenes({drawSceneInfo})
		self:FinalizeRender()
	else
		game.queue_scene_for_rendering(drawSceneInfo)
		self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes",function(drawSceneInfo)
			self:RenderScene(true)
		end)

		self.m_cbPostRenderScenes = game.add_callback("PostRenderScenes",function(drawSceneInfo)
			self:FinalizeRender()
		end)
	end
end
function pfm.PragmaRenderJob:FinalizeRender()
	self.m_drawCommandBuffer:Flush()
	local imgTest = self.m_renderer:GetHDRPresentationTexture():GetImage()

	self.m_imageBuffer = imgTest:ToImageBuffer(false,false,util.ImageBuffer.FORMAT_RGBA32,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
	local res = unirender.apply_color_transform(self.m_imageBuffer,nil,nil,self.m_renderSettings:GetColorTransform(),self.m_renderSettings:GetColorTransformLook())
	self.m_progress = 1.0

	self:Clear()
end
function pfm.PragmaRenderJob:Start()
	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT

	-- Create temporary scene
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local scene = ents.create_scene(sceneCreateInfo,gameScene)
	scene:SetActiveCamera(gameScene:GetActiveCamera())
	self.m_scene = scene

	-- Create temporary renderer
	local entRenderer = ents.create("rasterization_renderer")
	local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
	local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
	rasterizer:SetSSAOEnabled(true)
	renderer:InitializeRenderTarget(gameScene,self.m_renderSettings:GetWidth(),self.m_renderSettings:GetHeight())
	scene:SetRenderer(renderer)
	self.m_renderer = renderer

	-- Create temporary command buffer
	local drawCmd = prosper.create_primary_command_buffer()
	self.m_drawCommandBuffer = drawCmd
	self:RenderScene(true)
end
function pfm.PragmaRenderJob:IsComplete() return self:GetProgress() == 1.0 end
function pfm.PragmaRenderJob:GetProgress() return self.m_progress end
function pfm.PragmaRenderJob:IsSuccessful() return self:GetProgress() == 1.0 end
function pfm.PragmaRenderJob:GetResultCode() return -1 end
function pfm.PragmaRenderJob:GetImage() return self.m_imageBuffer end
function pfm.PragmaRenderJob:Cancel() self:Clear() end
