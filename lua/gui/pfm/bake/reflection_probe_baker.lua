--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")
include("/gui/pfm/controls_menu.lua")
include("/gui/cubemap_view.lua")

util.register_class("WIReflectionProbeBaker",WIBaseBaker)
function WIReflectionProbeBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:OnRemove()
	self:CloseWindow()
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
function WIReflectionProbeBaker:CloseWindow()
	if(util.is_valid(self.m_viewWindow) == false) then return end
	util.remove(gui.get_base_element(self.m_viewWindow))
	self.m_viewWindow:Close()
	self.m_viewWindow = nil
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

			self:CloseWindow()
			time.create_simple_timer(0.0,function()
				local w = 512
				local h = 512
				local createInfo = prosper.WindowCreateInfo()
				createInfo.width = w
				createInfo.height = h
				createInfo.title = "Reflection Probe View"

				local windowHandle = prosper.create_window(createInfo)
				if(windowHandle ~= nil) then
					local elBase = gui.get_base_element(windowHandle)
					if(util.is_valid(elBase)) then
						local bg = gui.create("WIRect")
						bg:SetColor(Color.White)
						bg:SetSize(512,512)

						local contents = gui.create("WIVBox",bg,0,0,bg:GetWidth(),bg:GetHeight(),0,0,1,1)
						contents:SetAutoFillContents(true)

						local p = gui.create("WIPFMControlsMenu",contents)
						p:SetAutoFillContentsToWidth(true)
						p:SetAutoFillContentsToHeight(false)

						local matPath = util.Path.CreateFilePath(reflC:GetIBLMaterialFilePath())
						matPath:PopFront()

						local el = gui.create("WICubemapView",contents)
						local mat = game.load_material(matPath:GetString())
						if(util.is_valid(mat)) then
							local texIn = mat:GetTextureInfo("prefilter"):GetTexture():GetVkTexture()
							local elCubemap
							local wrapper
							elCubemap,wrapper = p:AddDropDownMenu("Texture","show_external_assets",{
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

						p:Update()
						p:SizeToContents()

						el:SetViewResolution(w,h)
						el:SetSize(w,h)
						el:InitializeViewTexture()

						bg:SetParentAndUpdateWindow(elBase)
						bg:SetAnchor(0,0,1,1)
						bg:TrapFocus(true)
						bg:RequestFocus()
					end
				end

				self.m_viewWindow = windowHandle
			end)
		end
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
gui.register("WIReflectionProbeBaker",WIReflectionProbeBaker)
