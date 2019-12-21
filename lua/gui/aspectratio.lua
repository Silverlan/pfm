--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.AspectRatio",gui.Base)

function gui.AspectRatio:__init()
	gui.Base.__init(self)
end
function gui.AspectRatio:OnInitialize()
	gui.Base.OnInitialize(self)

	local hTop = 37
	local hBottom = 42
	local hViewport = 221
	self:SetSize(512,hViewport +hTop +hBottom)

	self.m_contents = gui.create("WIBase",self,0,37,self:GetWidth(),hViewport,0,0,1,1)
	self.m_contents:SetColor(Color.Black)
	self.m_contents:AddCallback("SetSize",function()
		self:Update()
	end)

	self:AddCallback("OnChildAdded",function(el,elChild)
		self.m_targetElement = elChild
	end)
	self:AddCallback("OnChildRemoved",function(el,elChild)
		if(elChild == self.m_targetElement) then
			self.m_targetElement = nil
		end
	end)

	self.m_aspectRatio = util.FloatProperty(1.0)
	self:SetAspectRatio(16.0 /9.0)
end
function gui.AspectRatio:SetAspectRatio(aspectRatio)
	self.m_aspectRatio:Set(aspectRatio)
	self:Update()
	self:CallCallbacks("OnAspectRatioChanged",aspectRatio)
end
function gui.AspectRatio:GetAspectRatio() return self.m_aspectRatio:Get() end
function gui.AspectRatio:GetAspectRatioProperty() return self.m_aspectRatio end
function gui.AspectRatio:OnUpdate()
	if(util.is_valid(self.m_targetElement) == false) then return end
	local size = self:GetSize()
	local ratio = self:GetAspectRatio()
	local w,h = util.clamp_resolution_to_aspect_ratio(size.x,size.y,ratio)
	self.m_targetElement:SetSize(w,h)
	self.m_targetElement:SetPos(size.x *0.5 -w *0.5,size.y *0.5 -h *0.5)
end
gui.register("WIAspectRatio",gui.AspectRatio)
