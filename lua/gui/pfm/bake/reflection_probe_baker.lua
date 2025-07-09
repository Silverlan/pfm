-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("base_baker.lua")
include("/gui/pfm/controls_menu/controls_menu.lua")
include("/gui/cubemap_view.lua")

pfm = pfm or {}
pfm.util = pfm.util or {}

pfm.util.open_reflection_probe_view_window = function(ent, onInit)
	pfm.util.open_simple_window(locale.get_text("pfm_reflection_probe_view"), function(windowHandle, contents, controls)
		if ent:IsValid() == false then
			return
		end
		local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		if reflC == nil then
			return
		end
		local matPath = util.Path.CreateFilePath(reflC:GetIBLMaterialFilePath())
		matPath:PopFront()

		local el = gui.create("WICubemapView", contents)
		local mat = game.load_material(matPath:GetString())
		if util.is_valid(mat) then
			local elCubemap
			local wrapper
			elCubemap, wrapper = controls:AddDropDownMenu(
				locale.get_text("texture"),
				"view_reflection_probe",
				{
					{ "0", locale.get_text("pfm_reflection_probe_view_prefilter") },
					{ "1", locale.get_text("pfm_reflection_probe_view_irradiance") },
				},
				"0",
				function()
					local val = toint(elCubemap:GetOptionValue(elCubemap:GetSelectedOption()))
					if val == 0 then
						local prefilter = mat:GetTextureInfo("prefilter")
						prefilter = (prefilter ~= nil) and prefilter:GetTexture()
						prefilter = (prefilter ~= nil) and prefilter:GetVkTexture()
						if prefilter ~= nil then
							el:SetInputTexture(prefilter)
						end
					elseif val == 1 then
						local irradiance = mat:GetTextureInfo("irradiance")
						irradiance = (irradiance ~= nil) and irradiance:GetTexture()
						irradiance = (irradiance ~= nil) and irradiance:GetVkTexture()
						if irradiance ~= nil then
							el:SetInputTexture(irradiance)
						end
					end
				end
			)
			elCubemap:SelectOption(0)
		end

		local w = contents:GetWidth()
		local h = contents:GetHeight()
		el:SetViewResolution(w, h)
		el:SetSize(w, h)
		el:InitializeViewTexture()

		if onInit ~= nil then
			onInit(windowHandle, contents, controls)
		end
	end)
end

local ReflectionProbeBaker = util.register_class("pfm.ReflectionProbeBaker", pfm.BaseBaker)
function ReflectionProbeBaker:__init()
	pfm.BaseBaker.__init(self, "ReflectionProbeBaker")
end
function ReflectionProbeBaker:SetActor(actorData, entActor)
	pfm.BaseBaker.SetActor(self, actorData, entActor)
	self.m_baker = pfm.bake.ReflectionProbeBaker(actorData, entActor)
end
function ReflectionProbeBaker:StartBaker()
	self.m_baker:Start()
end
function ReflectionProbeBaker:CancelBaker()
	self.m_baker:Clear()
end
function ReflectionProbeBaker:PollBaker()
	self.m_baker:Poll()
end
function ReflectionProbeBaker:IsBakerComplete()
	return self.m_baker:IsComplete()
end
function ReflectionProbeBaker:IsBakerSuccessful()
	return self.m_baker:IsSuccessful()
end
function ReflectionProbeBaker:GetBakerProgress()
	return self.m_baker:GetProgress()
end
function ReflectionProbeBaker:FinalizeBaker()
	local ent = self:GetActorEntity()
	local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
	return reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult():GetImage("Combined"))
end
function ReflectionProbeBaker:OpenWindow(title)
	pfm.BaseBaker.OpenWindow(self, title)
	local ent = self:GetActorEntity()
	if util.is_valid(ent) == false then
		return
	end
	pfm.util.open_reflection_probe_view_window(ent, function(windowHandle, contents, controls)
		self.m_viewWindow = windowHandle
	end)
end
function ReflectionProbeBaker:OnComplete()
	if self.m_baker:IsSuccessful() then
		local ent = self.m_baker:GetActorEntity()
		local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local res = reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult():GetImage("Combined"))
		if res == true then
			self:OpenWindow(locale.get_text("pfm_reflection_probe_view"))
		end
	end
end
