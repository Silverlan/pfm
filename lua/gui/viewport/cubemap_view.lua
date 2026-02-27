-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/util/cubemap_view.lua")
include("/gui/pfm/util/cursor_tracker.lua")

util.register_class("gui.CubemapView",gui.Base)
function gui.CubemapView:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512,512)
	local el = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_elTex = el

	self.m_rotation = Quaternion()

	self:SetViewResolution(512,512)
	self:SetMouseInputEnabled(true)
	self:RequestFocus()

	self:UpdateProjectionMatrix()
	self:UpdateViewMatrix()

	self.m_cbPreGuiDraw = game.add_callback("PreGUIDraw",function()
		if(self.m_viewUpdateRequired == nil) then return end
		self.m_viewUpdateRequired = nil
		local drawCmd = game.get_draw_command_buffer()
		self:UpdateView(drawCmd)
	end)
end
function gui.CubemapView:OnRemove()
	util.remove(self.m_cbPreGuiDraw)
end
function gui.CubemapView:OnThink()
	if(self.m_cursorTracker == nil) then return end
	local dt = self.m_cursorTracker:Update()
	if(dt.x == 0 and dt.y == 0) then return end
	local ang = self.m_rotation:ToEulerAngles()
	ang.y = ang.y -dt.x
	ang.p = ang.p -dt.y
	ang.p = math.clamp(ang.p,-89.99,89.99)
	self.m_rotation = ang:ToQuaternion()
	self:UpdateViewMatrix()
end
function gui.CubemapView:UpdateProjectionMatrix()
	local fov = 90.0
	local aspectRatio = 1.0
	local zNear = 1.0
	local zFar = 10000
	local p = matrix.create_perspective_matrix(fov,aspectRatio,zNear,zFar)
	self.m_projectionMatrix = p
end
function gui.CubemapView:UpdateViewMatrix()
	local origin = Vector()
	local dir = self.m_rotation:GetForward()
	local up = self.m_rotation:GetUp()
	local v = matrix.create_look_at_matrix(origin +dir,origin,up)
	self.m_viewMatrix = v

	self.m_viewUpdateRequired = true
end
function gui.CubemapView:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			self.m_cursorTracker = gui.CursorTracker()
			self:EnableThinking()
		elseif(state == input.STATE_RELEASE) then
			self.m_cursorTracker = nil
			self:DisableThinking()
		end
		return util.EVENT_REPLY_HANDLED
	end
end
function gui.CubemapView:SetViewResolution(width,height)
	self.m_viewWidth = width
	self.m_viewHeight = height
end
function gui.CubemapView:SetInputTexture(texIn)
	texIn = shader.cubemap_to_equirectangular_texture(texIn)
	if(texIn == nil) then return end

	local sh = shader.get("cubemap_view")

	local ds = sh:CreateDescriptorSet(shader.CubemapView.DESCRIPTOR_SET_TEXTURE)
	ds:SetBindingTexture(shader.CubemapView.TEXTURE_BINDING_TEXTURE,texIn)
	ds:Update()

	self.m_ds = ds
	self.m_inputTex = texIn

	self.m_viewUpdateRequired = true
end
function gui.CubemapView:InitializeViewTexture()
	local sh = shader.get("cubemap_view")

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = self.m_viewWidth
	imgCreateInfo.height = self.m_viewHeight
	imgCreateInfo.format = prosper.FORMAT_R8G8B8A8_UNORM
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL

	local img = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE

	local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	local rt = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{tex},shader.Graphics.get_render_pass())
	self.m_renderTarget = rt

	self.m_elTex:SetTexture(rt:GetTexture())
end
function gui.CubemapView:UpdateView(drawCmd)
	if(self.m_renderTarget == nil or self.m_ds == nil) then return end
	local cam = game.get_render_scene_camera()
	local vp = self.m_viewMatrix

	-- Strip translation
	vp:Set(3,0,0)
	vp:Set(3,1,0)
	vp:Set(3,2,0)
	vp = self.m_projectionMatrix *vp
	vp:Inverse()

	local rpInfo = prosper.RenderPassInfo(self.m_renderTarget)
	if(drawCmd:RecordBeginRenderPass(rpInfo)) then
		local shader = shader.get("cubemap_view")
		drawCmd:RecordImageBarrier(self.m_renderTarget:GetTexture():GetImage(),prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
		shader:GetWrapper():Record(drawCmd,self.m_ds,vp,prosper.util.get_square_vertex_uv_buffer(),prosper.util.get_square_vertex_count(),2.0,1,1,Color.Red)
		drawCmd:RecordImageBarrier(self.m_renderTarget:GetTexture():GetImage(),prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)

		drawCmd:RecordEndRenderPass()
	end
end
gui.register("cubemap_view",gui.CubemapView)
