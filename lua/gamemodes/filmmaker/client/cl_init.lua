--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gamemodes/generic/client/cl_init.lua")
include("../shared.lua")
local Component = ents.GmPfm

function Component:OpenPfm()
	console.run("pfm")
end
