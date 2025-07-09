-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.PFMColorWheel", shader.BaseGUITextured)

shader.PFMColorWheel.FragmentShader = "programs/pfm/hsv_color_wheel"
shader.PFMColorWheel.VertexShader = "programs/gui/textured"

function shader.PFMColorWheel:__init()
	shader.BaseGUITextured.__init(self)
end
shader.register("pfm_color_wheel", shader.PFMColorWheel)
