-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/pfm.lua")

if tool.is_filmmaker_open() == false then
	pfm.launch(nil)
end

return true
