--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("generic.lua")

util.register_class("unirender.VolumeShader",unirender.GenericShader)
function unirender.VolumeShader:__init()
	unirender.GenericShader.__init(self)
end
function unirender.VolumeShader:InitializeCombinedPass(desc,outputNode)
	self:LinkDefaultVolume(desc,outputNode)
end
unirender.register_shader("volume",unirender.VolumeShader)
