-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
gui.pfm.open_model_dialog = function(resultHandler)
    return gui.open_model_dialog(resultHandler, tool.get_filmmaker())
end
