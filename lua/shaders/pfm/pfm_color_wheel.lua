--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMColorWheel", shader.BaseGUITextured)

shader.PFMColorWheel.FragmentShader = "programs/pfm/hsv_color_wheel"
shader.PFMColorWheel.VertexShader = "programs/gui/textured"

function shader.PFMColorWheel:__init()
	shader.BaseGUITextured.__init(self)
end
shader.register("pfm_color_wheel", shader.PFMColorWheel)
