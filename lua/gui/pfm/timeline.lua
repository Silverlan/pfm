--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/timeline.lua")

util.register_class("gui.PFMTimeline",gui.Base)

function gui.PFMTimeline:__init()
	gui.Base.__init(self)
end
function gui.PFMTimeline:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,128)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self:InitializeToolbar()
	gui.create("WIBase",self.m_contents):SetSize(1,7) -- Gap

	self.m_contents:Update()
	self.m_timeline = gui.create("WITimeline",self)
	self.m_timeline:SetY(self.m_contents:GetBottom())
	self.m_timeline:SetWidth(self:GetWidth())
	self.m_timeline:SetHeight(self:GetHeight() -self.m_contents:GetHeight() -5)
	self.m_timeline:SetAnchor(0,0,1,1)

	self.m_timeline:SetZoomLevel(0.0)
	self.m_timeline:SetStartOffset(1.0)
	self.m_timeline:Update()
end
function gui.PFMTimeline:GetTimeline() return self.m_timeline end
function gui.PFMTimeline:GetPlayhead() return util.is_valid(self.m_timeline) and self.m_timeline:GetPlayhead() or nil end
function gui.PFMTimeline:InitializeToolbar()
	local toolbar = gui.create("WIBase",self.m_contents,0,0,self:GetWidth(),0)
	local toolbarLeft = gui.create("WIHBox",toolbar,0,0)
	self.m_btClipEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_timeline","gui/pfm/icon_mode_timeline_activated",function()
		print("PRESS")
	end)
	self.m_btMotionEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_motioneditor","gui/pfm/icon_mode_motioneditor_activated",function()
		print("PRESS")
	end)
	self.m_btGraphEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_grapheditor","gui/pfm/icon_mode_grapheditor_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarLeft):SetSize(32,1) -- Gap
	self.m_btBoomark = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_bookmark","gui/pfm/icon_bookmark_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarLeft):SetSize(6,1) -- Gap
	self.m_btAddTrackGroup = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_cp_plus_drop","gui/pfm/icon_cp_plus_drop_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarLeft):SetSize(18,1) -- Gap
	self.m_btUp = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_timeline_up","gui/pfm/icon_timeline_up_activated",function()
		print("PRESS")
	end)
	toolbarLeft:SetHeight(self.m_btClipEditor:GetHeight())

	local toolbarRight = gui.create("WIHBox",toolbar,0,0)
	self.m_btLockPlayhead = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_timeline_head","gui/pfm/icon_timeline_head_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btSnap = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_snap","gui/pfm/icon_snap_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btSnapFrame = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_snap_frame","gui/pfm/icon_snap_frame_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarRight):SetSize(18,1) -- Gap
	self.m_btPlayOnce = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_cp_play_once","gui/pfm/icon_cp_play_once_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btMute = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_mute","gui/pfm/icon_mute_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btTools = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("PRESS")
	end)
	toolbarRight:SetHeight(self.m_btLockPlayhead:GetHeight())
	toolbarRight:Update()
	toolbarRight:SetX(toolbar:GetWidth() -toolbarRight:GetWidth())
	toolbarRight:SetAnchor(1,0,1,0)
	toolbar:SetHeight(toolbarLeft:GetHeight())
	toolbar:SetAnchor(0,0,1,0)
end
gui.register("WIPFMTimeline",gui.PFMTimeline)
