--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")
include("/gui/pfm/controls_menu.lua")
include("/gui/cubemap_view.lua")

pfm = pfm or {}
pfm.util = pfm.util or {}

pfm.util.open_reflection_probe_view_window = function(ent,onInit)
	pfm.util.open_simple_window("Reflection Probe View",function(windowHandle,contents,controls)
		if(ent:IsValid() == false) then return end
		local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		if(reflC == nil) then return end
		local matPath = util.Path.CreateFilePath(reflC:GetIBLMaterialFilePath())
		matPath:PopFront()

		local el = gui.create("WICubemapView",contents)
		local mat = game.load_material(matPath:GetString())
		if(util.is_valid(mat)) then
			local texIn = mat:GetTextureInfo("prefilter"):GetTexture():GetVkTexture()
			local elCubemap
			local wrapper
			elCubemap,wrapper = controls:AddDropDownMenu("Texture","show_external_assets",{
				{"0","Prefilter"},
				{"1","Irradiance"}
			},"0",function()
				local val = toint(elCubemap:GetOptionValue(elCubemap:GetSelectedOption()))
				if(val == 0) then
					local prefilter = mat:GetTextureInfo("prefilter")
					prefilter = (prefilter ~= nil) and prefilter:GetTexture()
					prefilter = (prefilter ~= nil) and prefilter:GetVkTexture()
					if(prefilter ~= nil) then el:SetInputTexture(prefilter) end
				elseif(val == 1) then
					local irradiance = mat:GetTextureInfo("irradiance")
					irradiance = (irradiance ~= nil) and irradiance:GetTexture()
					irradiance = (irradiance ~= nil) and irradiance:GetVkTexture()
					if(irradiance ~= nil) then el:SetInputTexture(irradiance) end
				end
			end)
			elCubemap:SelectOption(0)
		end

		local w = contents:GetWidth()
		local h = contents:GetHeight()
		el:SetViewResolution(w,h)
		el:SetSize(w,h)
		el:InitializeViewTexture()

		if(onInit ~= nil) then onInit(windowHandle,contents,controls) end
	end)
end

util.register_class("WIReflectionProbeBaker",WIBaseBaker)
function WIReflectionProbeBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:SetActor(actorData,entActor)
	WIBaseBaker.SetActor(self,actorData,entActor)
	self.m_baker = pfm.bake.ReflectionProbeBaker(actorData,entActor)
end
function WIBaseBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:StartBaker() self.m_baker:Start() end
function WIReflectionProbeBaker:CancelBaker() self.m_baker:Clear() end
function WIReflectionProbeBaker:PollBaker() self.m_baker:Poll() end
function WIReflectionProbeBaker:IsBakerComplete() return self.m_baker:IsComplete() end
function WIReflectionProbeBaker:IsBakerSuccessful() return self.m_baker:IsSuccessful() end
function WIReflectionProbeBaker:GetBakerProgress() return self.m_baker:GetProgress() end
function WIReflectionProbeBaker:FinalizeBaker()
	local ent = self:GetActorEntity()
	local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
	return reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult())
end
function WIReflectionProbeBaker:OpenWindow(title)
	WIBaseBaker.OpenWindow(self,title)
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	pfm.util.open_reflection_probe_view_window(ent,function(windowHandle,contents,controls)
		if(self:IsValid() == false) then return end
		self.m_viewWindow = windowHandle
	end)
end
function WIReflectionProbeBaker:OnComplete()
	if(self.m_baker:IsSuccessful()) then
		local ent = self.m_baker:GetActorEntity()
		local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local res = reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult())
		if(res == false) then
			self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
		else
			self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))

			self:OpenWindow("Reflection Probe View")
		end
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
gui.register("WIReflectionProbeBaker",WIReflectionProbeBaker)
