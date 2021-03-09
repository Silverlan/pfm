--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_tonemapping.lua")
include("controls_menu.lua")

util.register_class("gui.PFMPostProcessing",gui.Base)

function gui.PFMPostProcessing:__init()
	gui.Base.__init(self)
end
function gui.PFMPostProcessing:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128,hViewport +hBottom)

	local p = gui.create("WIPFMControlsMenu",self)
	self.m_settingsBox = p

	-- Tonemapping
	--[[self:InitializeToneMapControls(p)

	-- DOF
	self:InitializeDOFControls(p)]]
end
function gui.PFMPostProcessing:OnRemove()
end
function gui.PFMPostProcessing:UpdateLuminance()
	local luminance = rt:GetLuminance()
	local Lmax = luminance:GetMaxLuminance()
	local Lav = luminance:GetAvgLuminance()
	local Llav = luminance:GetAvgLuminance()
	local Lmin = luminance:GetMinLuminance()
	local k = (math.log(Lmax) -math.log(Llav)) /(math.log(Lmax) -math.log(Lmin))
	local m = 0.3 +0.7 *math.pow(k,1.4)

	self.m_ctrlCompressionCurveParam:SetDefault(m)
	self.m_ctrlCompressionCurveParam:SetValue(m)
end
function gui.PFMPostProcessing:InitializeDOFControls(p)
	local fApplyDOFSettings = function() self:ApplyDOFSettings() end
	self.m_ctrlDofEnabled = self:AddToggleControl("pfm_dof_enabled",nil,false,fApplyDOFSettings)
	self.m_ctrlDofShowFocus = self:AddToggleControl("pfm_dof_debug_show_focus",nil,false,fApplyDOFSettings)
	self.m_ctrlDofShowDepth = self:AddToggleControl("pfm_dof_debug_show_depth",nil,false,fApplyDOFSettings)
	self.m_ctrlDofEnableVignette = self:AddToggleControl("pfm_dof_enable_vignette",nil,false,fApplyDOFSettings)
	self.m_ctrlDofUsePentagonBokehShape = self:AddToggleControl("pfm_dof_use_pentagon_bokeh_shape",nil,false,fApplyDOFSettings)

	self.m_ctrlParticleIntensity = self:AddSliderControl("pfm_pp_particle_intensity",nil,1,0,10,function()
		local intensity = self.m_ctrlParticleIntensity:GetValue()
		self.m_rt:SetParticleSystemColorFactor(Vector4(intensity,intensity,intensity,1.0))
	end)
	self.m_ctrlDofRings = self:AddSliderControl("pfm_dof_rings",nil,3,0,10,fApplyDOFSettings,1,true)
	self.m_ctrlDofRingSamples = self:AddSliderControl("pfm_dof_ring_samples",nil,3,0,10,fApplyDOFSettings,1,true)
	self.m_ctrlCoC = self:AddSliderControl("pfm_dof_coc",nil,0.03,0,0.1,fApplyDOFSettings)
	self.m_ctrlMaxBlur = self:AddSliderControl("pfm_dof_max_blur",nil,1.0,0,10,fApplyDOFSettings)
	self.m_ctrlDither = self:AddSliderControl("pfm_dof_dither_amount",nil,0.0001,0,0.01,fApplyDOFSettings,0.0001)
	self.m_ctrlVignIn = self:AddSliderControl("pfm_dof_vignette_inner_border",nil,0.0,0,5,fApplyDOFSettings)
	self.m_ctrlVignOut = self:AddSliderControl("pfm_dof_vignette_outer_border",nil,1.3,0,5,fApplyDOFSettings)
	self.m_ctrlPentagonShapeFeather = self:AddSliderControl("pfm_dof_pentagon_shape_feather",nil,0.4,0,2,fApplyDOFSettings)
end
function gui.PFMPostProcessing:ApplyDOFSettings()
	self.m_rt:SetDOFEnabled(self.m_ctrlDofEnabled:IsChecked())

	local dofSettings = self.m_rt:GetDOFSettings()
	local flags = dofSettings:GetFlags()
	flags = math.set_flag(flags,shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_FOCUS,self.m_ctrlDofShowFocus:IsChecked())
	flags = math.set_flag(flags,shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_DEPTH,self.m_ctrlDofShowDepth:IsChecked())
	flags = math.set_flag(flags,shader.PFMDepthOfField.DOFSettings.FLAG_BIT_ENABLE_VIGNETTE,self.m_ctrlDofEnableVignette:IsChecked())
	flags = math.set_flag(flags,shader.PFMDepthOfField.DOFSettings.FLAG_BIT_PENTAGON_BOKEH_SHAPE,self.m_ctrlDofUsePentagonBokehShape:IsChecked())
	dofSettings:SetFlags(flags)

	dofSettings:SetRingCount(self.m_ctrlDofRings:GetValue())
	dofSettings:SetRingSamples(self.m_ctrlDofRingSamples:GetValue())
	dofSettings:SetCircleOfConfusionSize(self.m_ctrlCoC:GetValue())
	dofSettings:SetMaxBlur(self.m_ctrlMaxBlur:GetValue())
	dofSettings:SetDitherAmount(self.m_ctrlDither:GetValue())
	dofSettings:SetVignettingInnerBorder(self.m_ctrlVignIn:GetValue())
	dofSettings:SetVignettingOuterBorder(self.m_ctrlVignOut:GetValue())
	dofSettings:SetPentagonShapeFeather(self.m_ctrlPentagonShapeFeather:GetValue())
end
function gui.PFMPostProcessing:UpdateDepthOfField()
	self.m_rt:UpdateGameSceneTextures()

	-- TODO: Handle this properly
	local gameScene = self.m_rt:GetGameScene()
	local cam = gameScene:GetActiveCamera():GetEntity():GetComponent(ents.COMPONENT_PFM_CAMERA)
	if(cam == nil) then return end
	local camData = cam:GetCameraData()
	local dofSettings = self.m_rt:GetDOFSettings()
	-- TODO: Add callbacks for these!
	--self.m_rt:SetDOFEnabled(camData:IsDepthOfFieldEnabled())
	self.m_rt:SetDOFEnabled(self.m_ctrlDofEnabled:IsChecked())
	self.m_rt:InitializeDepthTexture(gameScene:GetWidth(),gameScene:GetHeight(),camData:GetZNear(),camData:GetZFar())
	dofSettings:SetFocalDistance(camData:GetFocalDistance())
	dofSettings:SetFStop(camData:GetFStop())
	dofSettings:SetRingCount(camData:GetApertureBladeCount()) -- TODO: I'm not sure if these are equivalent
end
gui.register("WIPFMPostProcessing",gui.PFMPostProcessing)
