--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/button.lua")

pfm = pfm or {}
pfm.util = pfm.util or {}

pfm.util.open_simple_window = function(title, onOpen)
	time.create_simple_timer(0.0, function()
		local w = 512
		local h = 512
		local createInfo = prosper.WindowCreateInfo()
		createInfo.width = w
		createInfo.height = h
		if title ~= nil then
			createInfo.title = title
		end

		local windowHandle = prosper.create_window(createInfo)

		if windowHandle ~= nil then
			local elBase = gui.get_base_element(windowHandle)
			if util.is_valid(elBase) then
				local bg = gui.create("WIRect")
				bg:SetColor(Color.White)
				bg:SetSize(512, 512)

				local contents = gui.create("WIVBox", bg, 0, 0, bg:GetWidth(), bg:GetHeight(), 0, 0, 1, 1)
				contents:SetAutoFillContents(true)

				local p = gui.create("WIPFMControlsMenu", contents)
				p:SetAutoFillContentsToWidth(true)
				p:SetAutoFillContentsToHeight(false)

				if onOpen ~= nil then
					onOpen(windowHandle, contents, p)
				end
				p:Update()
				p:SizeToContents()

				bg:SetParentAndUpdateWindow(elBase)
				bg:SetAnchor(0, 0, 1, 1)
				bg:TrapFocus(true)
				bg:RequestFocus()
			end
		end
	end)
end

local BaseBaker = util.register_class("pfm.BaseBaker", util.CallbackHandler)
function BaseBaker:__init(name)
	util.CallbackHandler.__init(self)
	self.m_name = name
end
function BaseBaker:__finalize()
	self:Clear()
end
function BaseBaker:SetActor(actorData, entActor)
	self.m_actorData = actorData
	self.m_entActor = entActor
end
function BaseBaker:GetActorData()
	return self.m_actorData
end
function BaseBaker:GetActorEntity()
	return self.m_entActor
end
function BaseBaker:Cancel()
	if self.m_baking == true then
		self:CancelBaker()
		util.remove(self.m_cbTick)
		self:Reset()
		self:CallCallbacks("OnCancel")
	end
	self.m_baking = false
end
function BaseBaker:Clear()
	self:Cancel()
	self:CloseWindow()
	util.remove(self.m_cbTick)
	util.remove(self.m_progressBar)
end
function BaseBaker:CloseWindow()
	if util.is_valid(self.m_viewWindow) == false then
		return
	end
	util.remove(gui.get_base_element(self.m_viewWindow))
	self.m_viewWindow:Close()
	self.m_viewWindow = nil
end
function BaseBaker:OpenWindow(title)
	self:CloseWindow()
end
function BaseBaker:StartBake()
	self:StartBaker()
	self.m_baking = true
	self.m_startBakeTime = time.time_since_epoch()
	self:CallCallbacks("OnBakingStarted")

	util.remove(self.m_cbTick)
	self.m_cbTick = game.add_callback("Tick", function()
		self:Poll()
	end)

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		util.remove(self.m_progressBar)
		self.m_progressBar =
			pm:AddProgressStatusBar("bake_" .. self.m_name, locale.get_text("pfm_bake", { self.m_name }))
	end
end
function BaseBaker:Poll()
	if self.m_baking ~= true then
		return
	end
	self:PollBaker()

	if util.is_valid(self.m_progressBar) then
		self.m_progressBar:SetProgress(self:GetBakerProgress())
	end
	if self:IsBakerComplete() then
		self.m_baking = false
		util.remove(self.m_cbTick)
		util.remove(self.m_progressBar)
		local res = self:OnComplete()
		self:CallCallbacks("OnBakingCompleted", res)
	end
end
function BaseBaker:OnComplete()
	self.m_baking = false
	if self:IsBakerSuccessful() == false then
		return false
	end
	local res = self:FinalizeBaker()
	local dt = time.time_since_epoch() - self.m_startBakeTime
	print("Baking complete. Baking took " .. util.get_pretty_time(dt / 1000000000.0) .. "!")
	return res
end
function BaseBaker:IsBaking()
	return self.m_baking or false
end
function BaseBaker:FinalizeBaker()
	return false
end
function BaseBaker:Reset()
	self:CallCallbacks("OnReset")
end
function BaseBaker:StartBaker() end
function BaseBaker:CancelBaker() end
function BaseBaker:PollBaker() end
function BaseBaker:IsBakerComplete()
	return false
end
function BaseBaker:IsBakerSuccessful()
	return false
end
function BaseBaker:GetBakerProgress()
	return 1.0
end

-----------

local WIPFMActionButton = util.register_class("WIPFMActionButton", gui.PFMButton)
function WIPFMActionButton:OnInitialize()
	gui.PFMButton.OnInitialize(self)

	self:SetSize(64, 24)
	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HAND)
end
gui.register("WIPFMActionButton", WIPFMActionButton)

-----------

local WIBakeButton = util.register_class("WIBakeButton", WIPFMActionButton)
function WIBakeButton:OnInitialize()
	WIPFMActionButton.OnInitialize(self)

	self:SetSize(64, 24)
	self:InitializeProgressBar()
	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HAND)
	self.m_bakerCallbacks = {}

	self:SetBakeText("Bake")
end
function WIBakeButton:SetBakeText(text)
	self.m_bakeText = text
	self:SetText(text)
end
function WIBakeButton:OnPressed()
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) and pm:CheckBuildKernels() then
		return
	end
	if self.m_baker:IsBaking() == true then
		self.m_baker:Cancel()
		return
	end
	self.m_baker:StartBake()
end
function WIBakeButton:OnRemove()
	self:ClearBaker()
end
function WIBakeButton:ClearBaker()
	self.m_baker = nil
	util.remove(self.m_bakerCallbacks)
	self.m_bakerCallbacks = {}
end
function WIBakeButton:SetBaker(baker)
	self:ClearBaker()
	self.m_baker = baker
	table.insert(
		self.m_bakerCallbacks,
		baker:AddCallback("OnCancel", function()
			if util.is_valid(self.m_progressBar) then
				self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
			end
		end)
	)
	table.insert(
		self.m_bakerCallbacks,
		baker:AddCallback("OnBakingStarted", function()
			self:SetBakingState()
		end)
	)
	table.insert(
		self.m_bakerCallbacks,
		baker:AddCallback("OnBakingCompleted", function(result)
			if self.m_baker:IsBakerSuccessful() then
				if result == false then
					self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
				else
					self.m_baker:Reset()
					self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))
				end
			else
				self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
			end
			self:SetThinkingEnabled(false)
		end)
	)
	table.insert(
		self.m_bakerCallbacks,
		baker:AddCallback("OnReset", function(baker, result)
			self:SetText(self.m_bakeText)
		end)
	)

	if baker:IsBaking() then
		self:SetBakingState()
	end
end
function WIBakeButton:SetBakingState()
	self.m_progressBar:SetColor(pfm.get_color_scheme_color("darkGrey"))
	self:SetText(locale.get_text("cancel"))
	self:SetThinkingEnabled(true)
end
function WIBakeButton:OnThink()
	if self.m_baker:IsBaking() ~= true then
		return
	end
	local progress = self.m_baker:GetBakerProgress()
	if progress ~= self.m_prevProgress then
		self.m_prevProgress = progress
		local niceProgress = progress * 10000.0
		niceProgress = math.round(niceProgress)
		niceProgress = niceProgress / 100.0
		self:SetTooltip(locale.get_text("progress") .. ": " .. niceProgress .. "%")
	end
	self.m_progressBar:SetProgress(self.m_baker:GetBakerProgress())
end
function WIBakeButton:InitializeProgressBar()
	local progressBar = gui.create("WIProgressBar", self)
	progressBar:SetSize(self:GetWidth(), self:GetHeight())
	progressBar:SetPos(0, 0)
	progressBar:SetColor(Color.Gray)
	progressBar:SetAnchor(0, 0, 1, 1)
	progressBar:SetZPos(-2)
	progressBar:SetLabelVisible(false)
	self.m_progressBar = progressBar
end
gui.register("WIBakeButton", WIBakeButton)
