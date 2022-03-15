--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("util.GraphAxis",util.CallbackHandler)

local ZOOM_LEVEL_STRENGTH = 10.0
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
function util.GraphAxis:GetStrideX(w)
	local stridePerSecond = self:GetStridePerUnit()
	local strideX = stridePerSecond /10.0
	return strideX /w
end
function util.GraphAxis:GetStrideXTest(w)
	local stridePerSecond = self:GetStridePerUnitTest()
	local strideX = stridePerSecond /10.0
	return strideX /w
end
function util.GraphAxis:SetZoomLevelLimits(min,max) self.m_zoomLevelLimits = {min,max} end
function util.GraphAxis:GetZoomLevelLimits() return self.m_zoomLevelLimits end
function util.GraphAxis:SetZoomLevel(zoomLevel)
	zoomLevel = math.clamp(zoomLevel,-3,3)
	self.m_zoomLevel:Set(zoomLevel)
end
local function tfloor(f)
	return math.ceil(f)--math.floor(math.abs(f)) *math.sign(f)
end
function util.GraphAxis:GetZoomLevel() return self.m_zoomLevel:Get() end
function util.GraphAxis:GetZoomLevelProperty() return self.m_zoomLevel end
function util.GraphAxis:GetUnitZoomLevel() return self:GetUnitZoomLevelTest() end -- return self:GetZoomLevel() end --  %1.0 end
function util.GraphAxis:GetBaseZoomLevelTest() return self:GetZoomLevel() end
function util.GraphAxis:GetUnitZoomLevelTest() return (math.abs(self:GetBaseZoomLevelTest()) %1.0) *math.sin(self:GetBaseZoomLevelTest()) end
function util.GraphAxis:GetZoomLevelMultiplier() return self:GetZoomLevelMultiplierTest() end -- return 1.0 end -- 10 ^math.floor(self:GetZoomLevel()) end
function util.GraphAxis:GetZoomLevelMultiplierTest2() return 10 ^self:GetBaseZoomLevelTest() end
function util.GraphAxis:GetZoomLevelMultiplierTest() return 10 ^(tfloor(self:GetBaseZoomLevelTest())) end
function util.GraphAxis:SetStartOffset(offset) self.m_startOffset:Set(offset) end
function util.GraphAxis:GetStartOffset() return self.m_startOffset:Get() end
function util.GraphAxis:GetStartOffsetProperty() return self.m_startOffset end
function util.GraphAxis:GetStridePerUnit() return self:GetStridePerUnitTest() end -- return (1.0 +(1.0 -self:GetUnitZoomLevel())) *self:GetStrideInPixels() end
function util.GraphAxis:GetStridePerUnitTest() return (1.0 /self:GetZoomLevelMultiplierTest2()) *self.m_strideInPixels end -- return (1.0 +(1.0 -self:GetUnitZoomLevelTest())) *self:GetStrideInPixels() *ZOOM_LEVEL_STRENGTH end
function util.GraphAxis:SetStrideInPixels(stride) self.m_strideInPixels = stride end
function util.GraphAxis:GetStrideInPixels() return self.m_strideInPixels end
function util.GraphAxis:XDeltaToValue(x)
	return self:XDeltaToValueTest(x)--x /self:GetStridePerUnit() *self:GetZoomLevelMultiplier()
end
function util.GraphAxis:XOffsetToValue(x)
	return self:XOffsetToValueTest(x)--self:XDeltaToValue(x) +self:GetStartOffset()
end
function util.GraphAxis:ValueToXOffset(value)
	--value = (value -self:GetStartOffset()) /self:GetZoomLevelMultiplier()
	--return value *self:GetStridePerUnit()
	return self:ValueToXOffsetTest(value)
end

function util.GraphAxis:XDeltaToValueTest(x)
	-- Correct confirmed
	return x /self:GetStridePerUnitTest()
end
function util.GraphAxis:XOffsetToValueTest(x)
	-- Correct confirmed
	return self:XDeltaToValueTest(x) +self:GetStartOffset()
end
function util.GraphAxis:ValueToXOffsetTest(value)
	-- Correct confirmed
	value = value -self:GetStartOffset()
	return value *self:GetStridePerUnitTest()
end
function util.GraphAxis:ValueToXOffsetTest2(value)
	value = value -self:GetStartOffset()
	return value *self:GetStridePerUnitTest()
end
--[[
function gui.Timeline:ValueToXOffset(timeInSeconds)
	timeInSeconds = timeInSeconds -self:GetStartOffset()
	return (timeInSeconds /self:GetZoomLevelMultiplier()) *self:GetTimeStridePerUnit()
end
]]
