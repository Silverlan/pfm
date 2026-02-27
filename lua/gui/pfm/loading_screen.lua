-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/overlay/base_loading_screen.lua")

pfm.show_loading_screen = function(enabled, loadText)
	return pfm.show_base_loading_screen(enabled, "pragma filmmaker", "pfm/logo/pfm_logo", loadText)
end
