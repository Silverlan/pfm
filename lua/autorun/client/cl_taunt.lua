-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

console.register_command("taunt", function(pl, joystickAxisMagnitude)
	if util.is_valid(pl) == false then
		return
	end
	local pfmPlC = pl:GetEntity():GetComponent("pfm_player")
	if pfmPlC ~= nil then
		pfmPlC:Taunt()
	end
end)
