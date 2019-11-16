include("/gui/wiviewport.lua")
include("/gui/hbox.lua")
include("/gui/pfm/button.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMViewport",gui.Base)

function gui.PFMViewport:__init()
	gui.Base.__init(self)
end
function gui.PFMViewport:OnInitialize()
	gui.Base.OnInitialize(self)

	local hTop = 37
	local hBottom = 42
	local hViewport = 221
	self:SetSize(512,hViewport +hTop +hBottom)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(38,38,38))

	self.m_vpBg = gui.create("WIRect",self,0,37,self:GetWidth(),hViewport,0,0,1,1)
	self.m_vpBg:SetColor(Color.Black)
	self.m_vpBg:AddCallback("SetSize",function()
		if(util.is_valid(self.m_viewport) == false) then return end
		local size = self.m_vpBg:GetSize()
		local ratio = self:GetAspectRatio()
		local w,h = util.clamp_resolution_to_aspect_ratio(size.x,size.y,ratio)
		self.m_viewport:SetSize(w,h)
		self.m_viewport:SetPos(size.x *0.5 -w *0.5,size.y *0.5 -h *0.5)
	end)

	self.m_viewport = gui.create("WIViewport",self.m_vpBg)
	self:SetAspectRatio(16.0 /9.0)

	local function create_text_element(font,pos,color)
		local textColor = Color(182,182,182)
		local el = gui.create("WIText",self)
		el:SetFont(font)
		el:SetColor(textColor)
		el:SetPos(pos)
		return el
	end
	local textColor = Color(182,182,182)
	self.m_timeGlobal = create_text_element("pfm_large",Vector2(20,15),textColor)
	self.m_timeGlobal:SetText("00:00:17.083") -- TODO
	self.m_timeGlobal:SizeToContents()

	self.m_timeLocal = create_text_element("pfm_large",Vector2(0,15),textColor)
	self.m_timeLocal:SetText("00:00:04.958") -- TODO
	self.m_timeLocal:SizeToContents()

	textColor = Color(152,152,152)
	self.m_filmClipParent = create_text_element("pfm_medium",Vector2(0,3),textColor)
	self.m_filmClipParent:SetText("mtt_engineer") -- TODO
	self.m_filmClipParent:SizeToContents()

	self.m_filmClip = create_text_element("pfm_medium",Vector2(0,16),textColor)
	self.m_filmClip:SetText("slug") -- TODO
	self.m_filmClip:SizeToContents()

	self:InitializePlayControls()
	self:InitializeManipulatorControls()
	self:InitializeCameraControls()

	self:GetViewport():SetType(gui.WIViewport.VIEWPORT_TYPE_3D)
end
function gui.PFMViewport:InitializePlayControls()
	local controls = gui.create("WIHBox",self,0,self.m_vpBg:GetBottom() +4)
	self.m_btFirstFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_firstframe","gui/pfm/icon_cp_firstframe_activated",function()
		print("PRESS")
	end)
	self.m_btPrevClip = gui.PFMButton.create(controls,"gui/pfm/icon_cp_prevclip","gui/pfm/icon_cp_prevclip_activated",function()
		print("PRESS")
	end)
	self.m_btPrevFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_prevframe","gui/pfm/icon_cp_prevframe_activated",function()
		print("PRESS")
	end)
	self.m_btRecord = gui.PFMButton.create(controls,"gui/pfm/icon_cp_record","gui/pfm/icon_cp_record_activated",function()
		print("PRESS")
	end)
	self.m_btPlay = gui.PFMButton.create(controls,"gui/pfm/icon_cp_play","gui/pfm/icon_cp_play_activated",function()
		print("PRESS")
	end)
	self.m_btNextFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_nextframe","gui/pfm/icon_cp_nextframe_activated",function()
		print("PRESS")
	end)
	self.m_btNextClip = gui.PFMButton.create(controls,"gui/pfm/icon_cp_nextclip","gui/pfm/icon_cp_nextclip_activated",function()
		print("PRESS")
	end)
	self.m_btLastFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_lastframe","gui/pfm/icon_cp_lastframe_activated",function()
		print("PRESS")
	end)
	controls:SetHeight(self.m_btFirstFrame:GetHeight())
	controls:Update()
	controls:SetX(self:GetWidth() *0.5 -controls:GetWidth() *0.5)
	controls:SetAnchor(0.5,1,0.5,1)
	self.m_playControls = controls
end
function gui.PFMViewport:InitializeManipulatorControls()
	local controls = gui.create("WIHBox",self,0,self.m_vpBg:GetBottom() +4)
	self.m_btSelect = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_select","gui/pfm/icon_manipulator_select_activated",function()
		print("PRESS")
	end)
	self.m_btMove = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_move","gui/pfm/icon_manipulator_move_activated",function()
		print("PRESS")
	end)
	self.m_btRotate = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_rotate","gui/pfm/icon_manipulator_rotate_activated",function()
		print("PRESS")
	end)
	self.m_btScreen = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_screen","gui/pfm/icon_manipulator_screen_activated",function()
		print("PRESS")
	end)
	controls:SetHeight(self.m_btSelect:GetHeight())
	controls:Update()
	controls:SetX(3)
	controls:SetAnchor(0,1,0,1)
	self.manipulatorControls = controls
end
function gui.PFMViewport:InitializeCameraControls()
	local controls = gui.create("WIHBox",self,0,self.m_vpBg:GetBottom() +4)
	self.m_btAutoAim = gui.PFMButton.create(controls,"gui/pfm/icon_viewport_autoaim","gui/pfm/icon_viewport_autoaim_activated",function()
		print("PRESS")
	end)
	self.m_btCamera = gui.PFMButton.create(controls,"gui/pfm/icon_cp_camera","gui/pfm/icon_cp_camera_activated",function()
		print("PRESS")
	end)
	self.m_btGear = gui.PFMButton.create(controls,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("PRESS")
	end)
	controls:SetHeight(self.m_btAutoAim:GetHeight())
	controls:Update()
	controls:SetX(self:GetWidth() -controls:GetWidth() -3)
	controls:SetAnchor(1,1,1,1)
	self.manipulatorControls = controls
end
function gui.PFMViewport:GetViewport() return self.m_viewport end
function gui.PFMViewport:OnSizeChanged(w,h)
	self:Update()
end
function gui.PFMViewport:SetAspectRatio(aspectRatio)
	self.m_aspectRatio = aspectRatio

	if(util.is_valid(self.m_viewport)) then
		local scene = self.m_viewport:GetScene()
		if(scene ~= nil) then
			local cam = scene:GetActiveCamera()
			if(cam ~= nil) then
				cam:SetAspectRatio(aspectRatio)
				cam:UpdateMatrices()
			end
		end
	end
	--[[local maxResolution = engine.get_window_resolution()
	local w,h = util.clamp_resolution_to_aspect_ratio(maxResolution.x,maxResolution.y,aspectRatio)
	self.m_viewport:SetupScene(maxResolution.x,maxResolution.y)]]

	self:Update()
end
function gui.PFMViewport:GetAspectRatio() return self.m_aspectRatio end
function gui.PFMViewport:Update()
	if(util.is_valid(self.m_timeLocal)) then
		self.m_timeLocal:SetX(self:GetWidth() -self.m_timeLocal:GetWidth() -20)
	end
	if(util.is_valid(self.m_filmClipParent)) then
		self.m_filmClipParent:SetX(self:GetWidth() *0.5 -self.m_filmClipParent:GetWidth() *0.5)
	end
	if(util.is_valid(self.m_filmClip)) then
		self.m_filmClip:SetX(self:GetWidth() *0.5 -self.m_filmClip:GetWidth() *0.5)
	end
end
gui.register("WIPFMViewport",gui.PFMViewport)
