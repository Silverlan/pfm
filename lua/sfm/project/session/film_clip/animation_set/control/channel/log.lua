-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("log_layer.lua")

sfm.register_element_type("Log")
sfm.link_dmx_type("DmeBoolLog", sfm.Log)
sfm.link_dmx_type("DmeColorLog", sfm.Log)
sfm.link_dmx_type("DmeFloatLog", sfm.Log)
sfm.link_dmx_type("DmeIntLog", sfm.Log)
sfm.link_dmx_type("DmeQAngleLog", sfm.Log)
sfm.link_dmx_type("DmeQuaternionLog", sfm.Log)
sfm.link_dmx_type("DmeStringLog", sfm.Log)
sfm.link_dmx_type("DmeTimeLog", sfm.Log)
sfm.link_dmx_type("DmeVector2Log", sfm.Log)
sfm.link_dmx_type("DmeVector3Log", sfm.Log)
sfm.link_dmx_type("DmeVector4Log", sfm.Log)
sfm.link_dmx_type("DmeVMatrixLog", sfm.Log)

sfm.BaseElement.RegisterArray(sfm.Log, "layers", sfm.LogLayer)
sfm.BaseElement.RegisterArray(sfm.Log, "bookmarks", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.Log, "defaultvalue")
sfm.BaseElement.RegisterAttribute(sfm.Log, "usedefaultvalue", true)
