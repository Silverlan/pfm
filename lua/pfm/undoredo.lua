--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/log.lua")

pfm.register_log_category("pfm_undoredo")

local UNDO_LIMIT = 100

pfm = pfm or {}
pfm.undoredo = pfm.undoredo or {}
pfm.undoredo.stack = pfm.undoredo.stack or {}
pfm.undoredo.detail = pfm.undoredo.detail or {}
pfm.undoredo.action_position = 0
pfm.undoredo.push = function(name,actionDo,undo)
	local pos = pfm.undoredo.action_position +1
	pfm.log("Pushing action '" .. locale.get_text(name) .. "' to undoredo stack (#" .. pos .. ").",pfm.LOG_CATEGORY_PFM_UNDOREDO)
	pfm.undoredo.stack[pos] = {
		name = name,
		action = actionDo,
		undo = undo
	}
	pfm.undoredo.action_position = pos
	while(#pfm.undoredo.stack > pos) do pfm.undoredo.stack[#pfm.undoredo.stack] = nil end
	return actionDo
end

pfm.undoredo.clear = function()
	pfm.log("Clearing undoredo stack.",pfm.LOG_CATEGORY_PFM_UNDOREDO)
	pfm.undoredo.stack = {}
	pfm.undoredo.action_position = 0
end

pfm.undo = function()
	local pos = pfm.undoredo.action_position
	local data = pfm.undoredo.stack[pos]
	if(data == nil) then return end
	pfm.log("Undoing action #" .. pos .. " '" .. locale.get_text(data.name) .. "'...",pfm.LOG_CATEGORY_PFM_UNDOREDO)
	data.undo()
	pfm.undoredo.action_position = pos -1

	pfm.tag_render_scene_as_dirty()
end

pfm.redo = function()
	local pos = pfm.undoredo.action_position +1
	local data = pfm.undoredo.stack[pos]
	if(data == nil) then return end
	pfm.log("Redoing action #" .. pos .. " '" .. locale.get_text(data.name) .. "'...",pfm.LOG_CATEGORY_PFM_UNDOREDO)
	data.action()
	pfm.undoredo.action_position = pos

	pfm.tag_render_scene_as_dirty()
end

pfm.undoredo.detail.print = function()
	print("Position: ",pfm.undoredo.action_position)
	print("Stack:")
	console.print_table(pfm.undoredo.stack)
end

pfm.undoredo.detail.unit_test = function()
	local function push_case(i) pfm.undoredo.push(tostring(i),function() print("Do (" .. i .. ")") end,function() print("Undo (" .. i .. ")") end) end
	print("Test 1")
	pfm.undoredo.clear()
	push_case(1)
	print("Expected output: Undo (1); Do (1)")
	pfm.undo()
	pfm.redo()
	print("\n")

	print("Test 2")
	pfm.undoredo.clear()
	push_case(1)
	push_case(2)
	push_case(3)
	print("Expected output: Undo (3); Undo (2); Do (2); Do (3)")
	pfm.undo()
	pfm.undo()
	pfm.redo()
	pfm.redo()
	print("\n")

	print("Test 3")
	pfm.undoredo.clear()
	push_case(1)
	push_case(2)
	push_case(3)
	print("Expected output: Undo (3); Undo (2); Undo (4); Undo (1); Do (1); Do (4)")
	pfm.undo()
	pfm.undo()
	push_case(4)
	pfm.undo()
	pfm.undo()
	pfm.redo()
	pfm.redo()
	print("\n")
end
