-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.AspectRatio", gui.Base)

function gui.AspectRatio:__init()
	gui.Base.__init(self)
end
function gui.AspectRatio:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 512)

	self.m_background = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_background:SetColor(Color.Black)
	self.m_background:AddCallback("SetSize", function()
		self:Update()
	end)

	self:AddCallback("OnChildAdded", function(el, elChild)
		self.m_targetElement = elChild
	end)
	self:AddCallback("OnChildRemoved", function(el, elChild)
		if elChild == self.m_targetElement then
			self.m_targetElement = nil
		end
	end)

	self.m_aspectRatio = util.FloatProperty(1.0)
	self:SetAspectRatio(16.0 / 9.0)
end
function gui.AspectRatio:SetBackgroundColor(col)
	self.m_background:SetColor(col)
end
function gui.AspectRatio:SetAspectRatio(aspectRatio)
	self.m_aspectRatio:Set(aspectRatio)
	self:Update()
	self:CallCallbacks("OnAspectRatioChanged", aspectRatio)
end
function gui.AspectRatio:GetAspectRatio()
	return self.m_aspectRatio:Get()
end
function gui.AspectRatio:GetAspectRatioProperty()
	return self.m_aspectRatio
end
function gui.AspectRatio:OnUpdate()
	if util.is_valid(self.m_targetElement) == false then
		return
	end
	local size = self:GetSize()
	local ratio = self:GetAspectRatio()
	local w, h = util.clamp_resolution_to_aspect_ratio(size.x, size.y, ratio)
	self.m_targetElement:SetSize(w, h)
	self.m_targetElement:SetPos(size.x * 0.5 - w * 0.5, size.y * 0.5 - h * 0.5)
end
gui.register("WIAspectRatio", gui.AspectRatio)
