--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.ElementSelectionOutline",gui.Base)
Element.OUTLINE_TYPE_MAJOR = 0
Element.OUTLINE_TYPE_MINOR = 1
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)

	local elOutline = gui.create("WIOutlinedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	elOutline:SetColor(Color.Red)
	elOutline:SetOutlineWidth(2)
	self.m_elOutline = elOutline

	self.m_elCallbacks = {}
end
function Element:SetOutlineType(type)
	if(type == Element.OUTLINE_TYPE_MINOR) then
		self.m_elOutline:SetOutlineWidth(1)
		self.m_elOutline:SetColor(Color.Gray)
	end
end
function Element:OnRemove()
	util.remove(self.m_elCallbacks)
end
function Element:SetTargetElement(el)
	util.remove(self.m_elCallbacks)
	self.m_targetElement = el
	table.insert(self.m_elCallbacks,el:AddCallback("SetSize",function() self:ScheduleUpdate() end))
	table.insert(self.m_elCallbacks,el:AddCallback("SetPos",function() self:ScheduleUpdate() end))

	self:ScheduleUpdate()
end
function Element:GetTargetElement() return self.m_targetElement end
function Element:UpdateBounds()
	if(util.is_valid(self.m_targetElement) == false) then return end
	if(self.m_targetElement:IsHidden()) then
		self:SetVisible(false)
		return
	end
	self:SetVisible(true)
	local absPos = self.m_targetElement:GetAbsolutePos()
	local size = self.m_targetElement:GetSize()
	self:SetAbsolutePos(absPos)
	self:SetSize(size)
end
function Element:OnUpdate()
	self:UpdateBounds()
end
gui.register("WIElementSelectionOutline",Element)

-----------------

local Element = util.register_class("gui.GameObjectSelectionOutline",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)

	local elOutline = gui.create("WIOutlinedRect",self)
	elOutline:SetColor(Color.Aqua)
	elOutline:SetOutlineWidth(1)
	elOutline:SetVisible(false)
	self.m_elOutline = elOutline

	self.m_elCallbacks = {}

	self:SetThinkingEnabled(true)
end
function Element:SetOutlineType(type)
	if(type == Element.OUTLINE_TYPE_MINOR) then
		self.m_elOutline:SetOutlineWidth(1)
		self.m_elOutline:SetColor(Color.Gray)
	end
end
function Element:OnRemove()
	util.remove(self.m_elCallbacks)
end
function Element:SetTarget(vp,ent)
	self.m_viewport = vp
	self.m_targetEntity = ent

	self:SetParent(vp)
	self:SetSize(vp:GetSize())
	self:SetAnchor(0,0,1,1)

	self:ScheduleUpdate()
end
function Element:GetTargetPoints()
	if(util.is_valid(self.m_targetEntity) == false) then return {} end
	local renderC = self.m_targetEntity:GetComponent(ents.COMPONENT_RENDER)
	if(renderC == nil) then return {} end
	local min,max = renderC:GetAbsoluteRenderBounds()
	return {
		Vector(min.x, min.y, min.z),
		Vector(min.x, min.y, max.z),
		Vector(min.x, max.y, min.z),
		Vector(min.x, max.y, max.z),
		Vector(max.x, min.y, min.z),
		Vector(max.x, min.y, max.z),
		Vector(max.x, max.y, min.z),
		Vector(max.x, max.y, max.z)
	}
end
function Element:IsTargetInView()
	if(util.is_valid(self.m_viewport) == false or util.is_valid(self.m_targetEntity) == false or self.m_targetEntity:HasComponent(ents.COMPONENT_RENDER) == false) then return false end
	local vpData = ents.ClickComponent.get_viewport_data(self.m_viewport)
	if(util.is_valid(vpData.camera) == false) then return false end
	local plane = math.Plane(vpData.camera:GetEntity():GetForward(),vpData.camera:GetNearPlaneCenter())
	local points = {self.m_targetEntity:GetPos()}
	for _,p in ipairs(points) do
		local side = geometry.get_side_of_point_to_plane(plane:GetNormal(),plane:GetDistance(),p)
		if(side == geometry.PLANE_SIDE_BACK) then return false end
	end
	return true,vpData
end
function Element:IsPointInView(pos)
	if(util.is_valid(self.m_viewport) == false or util.is_valid(self.m_targetEntity) == false) then return false end
	local vpData = ents.ClickComponent.get_viewport_data(self.m_viewport)
	if(util.is_valid(vpData.camera) == false) then return false end
	local plane = math.Plane(vpData.camera:GetEntity():GetForward(),vpData.camera:GetNearPlaneCenter())
	local side = geometry.get_side_of_point_to_plane(plane:GetNormal(),plane:GetDistance(),pos)
	if(side == geometry.PLANE_SIDE_BACK) then return false end
	return true,vpData
end
function Element:IsTargetInFullView()
	if(self.m_elOutline:IsVisible() == false) then return false end
	local function is_point_in_bounds(p)
		return p.x >= 0 and p.y >= 0 and p.x < self:GetWidth() and p.y < self:GetHeight()
	end
	return is_point_in_bounds(self.m_elOutline:GetPos()) and is_point_in_bounds(Vector2(self.m_elOutline:GetRight(),self.m_elOutline:GetBottom()))
end
function Element:OnThink()
	local inView,vpData = self:IsTargetInView()
	if(inView == false) then
		self.m_elOutline:SetVisible(false)
		return
	end
	self.m_elOutline:SetVisible(true)
	local points = self:GetTargetPoints()

	local min2d = Vector2(math.huge,math.huge)
	local max2d = Vector2(-math.huge,-math.huge)
	local points2d = {}
	for _,p in ipairs(points) do
		local uv = ents.ClickComponent.world_space_point_to_screen_space_uv(p,nil,vpData)
		local p = Vector2(uv.x *vpData.width,uv.y *vpData.height)
		min2d.x = math.min(min2d.x,p.x)
		min2d.y = math.min(min2d.y,p.y)

		max2d.x = math.max(max2d.x,p.x)
		max2d.y = math.max(max2d.y,p.y)
	end

	self.m_elOutline:SetPos(min2d)
	self.m_elOutline:SetSize(max2d -min2d)
	--local min,max = renderC:GetRenderBounds()
	--
	--function ents.ClickComponent.world_space_point_to_screen_space_uv(point,callback,vpData)
end
function Element:UpdateBounds()
	if(util.is_valid(self.m_targetElement) == false) then return end

	--[[if(self.m_targetElement:IsHidden()) then
		self:SetVisible(false)
		return
	end
	self:SetVisible(true)
	local absPos = self.m_targetElement:GetAbsolutePos()
	local size = self.m_targetElement:GetSize()
	self:SetAbsolutePos(absPos)
	self:SetSize(size)]]
end
function Element:OnUpdate()
	self:UpdateBounds()
end
gui.register("WIGameObjectSelectionOutline",Element)