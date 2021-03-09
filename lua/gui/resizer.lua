--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.Resizer",gui.Base)

gui.Resizer.RESIZE_MODE_HORIZONTAL = 0
gui.Resizer.RESIZE_MODE_VERTICAL = 1
function gui.Resizer:__init()
	gui.Base.__init(self)
end
function gui.Resizer:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetMouseInputEnabled(true)

	self:SetSize(8,8)
	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:GetColorProperty():Link(self:GetColorProperty())
	self:SetColor(Color(38,38,38))

	self.m_dotContainer = gui.create("WIBase",self)
	self.m_dots = {}
	for i=1,3 do
		local p = gui.create("WIRect",self.m_dotContainer)
		p:SetColor(Color(154,154,154))
		p:SetSize(2,2)
		table.insert(self.m_dots,p)
	end

	local parent = self:GetParent()
	if(parent:GetClass() == "wihbox") then
		self:SetResizeMode(gui.Resizer.RESIZE_MODE_VERTICAL)
	else
		self:SetResizeMode(gui.Resizer.RESIZE_MODE_HORIZONTAL)
	end
	self:SetFraction(0.5)
	parent:AddCallback("SetSize",function(p)
		self.m_updateRequired = true
	end)
	parent:AddCallback("OnContentsUpdated",function(p)
		if(self.m_updateRequired ~= true) then return end
		self.m_updateRequired = nil
		self:ScheduleUpdate()
	end)
	self:ScheduleUpdate()
end
function gui.Resizer:OnUpdate()
	local parent = self:GetParent()
	if(parent:GetClass() ~= "wihbox" and parent:GetClass() ~= "wivbox") then return end
	-- If we're a parent of a hbox or vbox, we'll assign some default parameters for convenience
	local mode = self:GetResizeMode()
	if(mode == gui.Resizer.RESIZE_MODE_VERTICAL) then self:SetHeight(parent:GetHeight())
	elseif(mode == gui.Resizer.RESIZE_MODE_HORIZONTAL) then self:SetWidth(parent:GetWidth()) end

	-- We'll assume the resizer should affect the previous and next elements of its parents children
	local child0
	local child1
	local children = parent:GetChildren()
	for i,child in ipairs(children) do
		if(child == self) then
			child0 = children[i -1]
			child1 = children[i +1]
			break
		end
	end
	self:SetElements(child0,child1)
	if(util.is_valid(child0) and util.is_valid(child1)) then
		if(mode == gui.Resizer.RESIZE_MODE_VERTICAL) then
			local w = child0:GetWidth() +child1:GetWidth()
			local w0 = math.floor(w *0.5)
			child0:SetWidth(w0)
			child1:SetWidth(w -w0)
		elseif(mode == gui.Resizer.RESIZE_MODE_HORIZONTAL) then
			local h = child0:GetHeight() +child1:GetHeight()
			local h0 = math.floor(h *0.5)
			child0:SetHeight(h0)
			child1:SetHeight(h -h0)
		end
	end
	self:UpdateFraction()
end
function gui.Resizer:SetResizeMode(mode)
	self.m_resizeMode = mode
	if(mode == gui.Resizer.RESIZE_MODE_VERTICAL) then
		self:SetCursor(gui.CURSOR_SHAPE_HRESIZE)

		self:SetHeight(8)
		local y = 0
		for i,p in ipairs(self.m_dots) do
			if(p:IsValid()) then
				p:SetPos(0,y)
				y = y +p:GetHeight() +3
			end
		end
	elseif(mode == gui.Resizer.RESIZE_MODE_HORIZONTAL) then
		self:SetCursor(gui.CURSOR_SHAPE_VRESIZE)

		self:SetWidth(8)
		local x = 0
		for i,p in ipairs(self.m_dots) do
			if(p:IsValid()) then
				p:SetPos(x,0)
				x = x +p:GetWidth() +3
			end
		end
	end
	if(self.m_dotContainer:IsValid()) then
		self.m_dotContainer:SizeToContents()
		self.m_dotContainer:SetPos(
			self:GetWidth() *0.5 -self.m_dotContainer:GetWidth() *0.5,
			self:GetHeight() *0.5 -self.m_dotContainer:GetHeight() *0.5
		)
		self.m_dotContainer:SetAnchor(0.5,0.5,0.5,0.5)
	end
end
function gui.Resizer:GetResizeMode() return self.m_resizeMode end
function gui.Resizer:SetElements(el0,el1)
	self.m_element0 = el0
	self.m_element1 = el1
end
function gui.Resizer:SetFraction(fraction)
	fraction = math.clamp(fraction,0.0,1.0)
	self.m_fraction = fraction
	self:ScheduleUpdate()
end
function gui.Resizer:GetFraction() return self.m_fraction end
function gui.Resizer:GetRangeExtents()
	if(util.is_valid(self.m_element0) == false or util.is_valid(self.m_element1) == false) then return 0.0 end
	return self:GetExtent(self.m_element0) +self:GetExtent(self) +self:GetExtent(self.m_element1)
end
function gui.Resizer:FindBorderingElements()
	local before,after
	local children = self:GetParent():GetChildren()
	for i,child in ipairs(children) do
		if(child == self.m_element0) then before = children[i -1]
		elseif(child == self.m_element1) then after = children[i +1] end
	end
	return before,after
end
function gui.Resizer:ClampFraction(fraction)
	local before,after = self:FindBorderingElements()
	local minFraction = ((before and (self:GetCoord(before) +self:GetExtent(before)) or 0.0) +self:GetExtent(self) /2.0) /self:GetExtent(self:GetParent())
	local maxFraction = ((after and self:GetCoord(after) or self:GetExtent(self:GetParent())) -self:GetExtent(self) /2.0) /self:GetExtent(self:GetParent())
	return math.clamp(fraction,minFraction,maxFraction)
end
function gui.Resizer:GetRelativeFraction(fraction)
	if(util.is_valid(self.m_element0) == false or util.is_valid(self.m_element1) == false) then return 0.0 end
	local w = self:GetExtent(self:GetParent())

	local start = self:GetCoord(self.m_element0)
	local wLocal = self:GetRangeExtents()
	return ((fraction *w) -start) /wLocal
end
function gui.Resizer:UpdateFraction()
	if(util.is_valid(self.m_element0) == false or util.is_valid(self.m_element1) == false) then return end
	local fraction = self:GetRelativeFraction(self:GetFraction())
	local e = self:GetRangeExtents()
	local e0 = math.floor(fraction *e) -self:GetExtent(self) /2
	local e1 = e -e0 -self:GetExtent(self)
	self:SetExtent(self.m_element0,e0)
	self:SetExtent(self.m_element1,e1)
	-- We need to update the parent VBox/HBox element right away,
	-- in case there are other resizer elements within it
	self:GetParent():Update()
end
function gui.Resizer:GetExtent(el)
	local mode = self:GetResizeMode()
	return (mode == gui.Resizer.RESIZE_MODE_VERTICAL) and el:GetWidth() or el:GetHeight()
end
function gui.Resizer:GetCoord(el)
	local mode = self:GetResizeMode()
	return (mode == gui.Resizer.RESIZE_MODE_VERTICAL) and el:GetX() or el:GetY()
end
function gui.Resizer:SetExtent(el,ext)
	local mode = self:GetResizeMode()
	if(mode == gui.Resizer.RESIZE_MODE_VERTICAL) then el:SetWidth(ext)
	else el:SetHeight(ext) end
end
function gui.Resizer:GetFullExtent()
	if(util.is_valid(self.m_element0) == false or util.is_valid(self.m_element1) == false) then return 0.0 end
	return self:GetExtent(self.m_element0) +self:GetExtent(self.m_element1) +self:GetExtent(self)
end
function gui.Resizer:CalcFraction(pos)
	return pos /self:GetExtent(self:GetParent())
end
function gui.Resizer:MouseCallback(mouseButton,state,mods)
	if(mouseButton == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			self:SetCursorMovementCheckEnabled(true)
			if(util.is_valid(self.m_cbMove) == false) then
				local mode = self:GetResizeMode()
				if(mode == gui.Resizer.RESIZE_MODE_VERTICAL) then
					local xStart = self:GetCursorPos().x
					self.m_cbMove = self:AddCallback("OnCursorMoved",function(el,x,y)
						local fraction = self:CalcFraction(self:GetX() +self:GetExtent(self) /2.0 +(x -xStart))
						fraction = self:ClampFraction(fraction)
						self:SetFraction(fraction)
						self:UpdateFraction()
					end)
				elseif(mode == gui.Resizer.RESIZE_MODE_HORIZONTAL) then
					local yStart = self:GetCursorPos().y
					self.m_cbMove = self:AddCallback("OnCursorMoved",function(el,x,y)
						local fraction = self:CalcFraction(self:GetY() +self:GetExtent(self) /2.0 +(y -yStart))
						fraction = self:ClampFraction(fraction)
						self:SetFraction(fraction)
						self:UpdateFraction()
					end)
				end
			end
		elseif(state == input.STATE_RELEASE) then
			self:SetCursorMovementCheckEnabled(false)
			if(util.is_valid(self.m_cbMove)) then self.m_cbMove:Remove() end
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
gui.register("WIResizer",gui.Resizer)
