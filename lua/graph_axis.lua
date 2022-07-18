--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("util.GraphAxis",util.CallbackHandler)

function util.GraphAxis:__init()
	util.CallbackHandler.__init(self)
	self.m_startOffset = util.FloatProperty(0.0)
	self.m_zoomLevel = util.FloatProperty(0.0)
	self.m_zoomLevelLimits = {-3,3}
	self:SetStrideInPixels(30)

	local fOnPropsChanged = function() self:CallCallbacks("OnPropertiesChanged") end
	self.m_startOffset:AddCallback(fOnPropsChanged)
	self.m_zoomLevel:AddCallback(fOnPropsChanged)
end
function util.GraphAxis:GetPixelStrideX(stepSize)
	stepSize = stepSize or 0.1
	local stridePerSecond = self:GetStridePerUnit()
	local strideX = stridePerSecond *stepSize
	return strideX
end
function util.GraphAxis:GetStrideX(w,stepSize)
	return self:GetPixelStrideX(stepSize) /w
end
function util.GraphAxis:SetZoomLevelLimits(min,max) self.m_zoomLevelLimits = {min,max} end
function util.GraphAxis:GetZoomLevelLimits() return self.m_zoomLevelLimits end
function util.GraphAxis:SetZoomLevel(zoomLevel,pivot)
	if(pivot ~= nil) then
		local xOffsetPlayhead = self:ValueToXOffset(pivot)
		self:SetZoomLevel(zoomLevel)

		local newXOffsetPlayhead = self:ValueToXOffset(pivot)
		local startOffset = self:GetStartOffset() -self:XDeltaToValue(xOffsetPlayhead -newXOffsetPlayhead)
		self:SetStartOffset(startOffset)
		return self:ValueToXOffset(pivot)
	end
	zoomLevel = math.clamp(zoomLevel,-3,3)
	self.m_zoomLevel:Set(zoomLevel)
end
function util.GraphAxis:GetZoomLevel() return self.m_zoomLevel:Get() end
function util.GraphAxis:GetZoomLevelProperty() return self.m_zoomLevel end
function util.GraphAxis:GetZoomLevelMultiplier() return self:GetZoomLevelMultiplier() end
function util.GraphAxis:GetZoomLevelMultiplierFraction() return 10 ^self:GetZoomLevel() end
function util.GraphAxis:GetZoomLevelMultiplier() return 10 ^math.ceil(self:GetZoomLevel()) end
function util.GraphAxis:SetStartOffset(offset) self.m_startOffset:Set(offset) end
function util.GraphAxis:GetStartOffset() return self.m_startOffset:Get() end
function util.GraphAxis:GetStartOffsetProperty() return self.m_startOffset end
function util.GraphAxis:GetStridePerUnit() return (1.0 /self:GetZoomLevelMultiplierFraction()) *self.m_strideInPixels end
function util.GraphAxis:SetStrideInPixels(stride) self.m_strideInPixels = stride end
function util.GraphAxis:GetStrideInPixels() return self.m_strideInPixels end
function util.GraphAxis:XDeltaToValue(x) return x /self:GetStridePerUnit() end
function util.GraphAxis:ValueToXDelta(v) return v *self:GetStridePerUnit() end
function util.GraphAxis:XOffsetToValue(x) return self:XDeltaToValue(x) +self:GetStartOffset() end
function util.GraphAxis:ValueToXOffset(value)
	value = value -self:GetStartOffset()
	return value *self:GetStridePerUnit()
end
function util.GraphAxis:ValueRangeToZoomFactor(dt,w)
	local strideInPixels = self:GetStrideInPixels()
	local stridePerUnit = w /dt
	stridePerUnit = stridePerUnit /strideInPixels
	local zoomLevelMultiplierFraction = 1.0 /stridePerUnit
	return math.log10(zoomLevelMultiplierFraction)
end
function util.GraphAxis:SetRange(startValue,endValue,w)
	self:SetStartOffset(startValue)
	self:SetZoomLevel(self:ValueRangeToZoomFactor(endValue -startValue,w))
end
