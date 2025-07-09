-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("LogLayer")
sfm.link_dmx_type("DmeBoolLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeColorLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeFloatLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeIntLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeQAngleLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeQuaternionLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeStringLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeTimeLogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeVector2LogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeVector3LogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeVector4LogLayer", sfm.LogLayer)
sfm.link_dmx_type("DmeVMatrixLogLayer", sfm.LogLayer)

function sfm.LogLayer:Initialize()
	self.m_times = {}
	self.m_values = {}
end

function sfm.LogLayer:Load(el)
	sfm.BaseElement.Load(self, el)
	for _, elValue in ipairs(el:GetAttrV("values")) do
		table.insert(self.m_values, elValue:GetValue())
	end

	for _, elValue in ipairs(el:GetAttrV("times")) do
		table.insert(self.m_times, elValue:GetValue())
	end
end

function sfm.LogLayer:GetTimes()
	return self.m_times
end
function sfm.LogLayer:GetValues()
	return self.m_values
end
function sfm.LogLayer:GetType()
	return self.m_type
end
