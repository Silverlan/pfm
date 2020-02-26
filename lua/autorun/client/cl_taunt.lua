--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

console.register_command("taunt",function(pl,joystickAxisMagnitude)
	if(util.is_valid(pl) == false) then return end
	local pfmPlC = pl:GetEntity():GetComponent("pfm_player")
	if(pfmPlC ~= nil) then
		pfmPlC:Taunt()
	end
end)
