--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("controls_menu.lua")

local Element = util.register_class("gui.PFMSettings",gui.Base)

function Element:__init()
	gui.Base.__init(self)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)

	local p = gui.create("WIPFMControlsMenu",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p

	local skipCallbacks = true
	local elWindowMode,wrapper
	elWindowMode,wrapper = p:AddDropDownMenu(locale.get_text("window_mode"),"window_mode",{
		{"0",locale.get_text("windowmode_fullscreen")},
		{"1",locale.get_text("windowmode_windowed")},
		{"2",locale.get_text("windowmode_noborder_window")}
	},"1",function()
		if(skipCallbacks) then return end
		local windowMode = toint(elWindowMode:GetOptionValue(elWindowMode:GetSelectedOption()))
		time.create_simple_timer(0.0,function() console.run("cl_render_window_mode",tostring(windowMode)) end)
	end)
	wrapper:SetUseAltMode(true)

	local options = {}
	local resMap = {}
	for _,vm in ipairs(gui.get_supported_video_modes()) do
		local resolution = tostring(vm.width) .. "x" .. tostring(vm.height)
		if(resMap[resolution] == nil) then
			resMap[resolution] = true
			table.insert(options,{resolution,resolution})
		end
	end
	local elResolution,wrapper
	elResolution,wrapper = p:AddDropDownMenu(locale.get_text("resolution"),"resolution",options,console.get_convar_string("cl_window_resolution"),function()
		if(skipCallbacks) then return end
		local resolution = elResolution:GetOptionValue(elResolution:GetSelectedOption())
		time.create_simple_timer(0.0,function() console.run("cl_window_resolution",resolution) end)
	end)
	wrapper:SetUseAltMode(true)

	local pEnableExperimentalUpdates = p:AddToggleControl(locale.get_text("pfm_enable_experimental_updates"),"enable_experimental_updates",console.get_convar_bool("pfm_enable_experimental_updates"),function(el,checked)
		console.run("pfm_enable_experimental_updates",checked and "1" or "0")
	end)

	p:Update()
	p:SizeToContents()

	p:ResetControls()
	skipCallbacks = false
end
function Element:GetPlayControls() return self.m_playbackControls end
function Element:GetVideoPlayerElement() return self.m_videoPlayer end
gui.register("WIPFMSettings",Element)
