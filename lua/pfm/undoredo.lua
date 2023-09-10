--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/log.lua")
include("commands.lua")

locale.load("pfm_undoredo.txt")

pfm.register_log_category("pfm_undoredo")

pfm = pfm or {}
pfm.undoredo = pfm.undoredo or {}
pfm.undoredo.stack = pfm.undoredo.stack or {}
pfm.undoredo.detail = pfm.undoredo.detail or {}
pfm.undoredo.detail.callback_handler = pfm.undoredo.detail.callback_handler or util.CallbackHandler()
pfm.undoredo.action_position = 0
pfm.undoredo.is_empty = function()
	return pfm.undoredo.stack[1] == nil
end

pfm.undoredo.add_callback = function(name, f)
	return pfm.undoredo.detail.callback_handler:AddCallback(name, f)
end

pfm.undoredo.get_undo_position = function()
	return pfm.undoredo.action_position
end

pfm.undoredo.get_locale_identifier = function(baseName)
	return "pfm_undoredo_" .. baseName
end

pfm.undoredo.push = function(name, actionDo, undo)
	name = pfm.undoredo.get_locale_identifier(name)
	if actionDo == nil then
		return function() end
	end
	local pos = pfm.undoredo.action_position + 1
	pfm.log(
		"Pushing action '" .. locale.get_text(name) .. "' to undoredo stack (#" .. pos .. ").",
		pfm.LOG_CATEGORY_PFM_UNDOREDO
	)
	local isCommand = (undo == nil)
	if isCommand then
		pfm.undoredo.stack[pos] = {
			name = name,
			command = actionDo,
		}
	else
		pfm.undoredo.stack[pos] = {
			name = name,
			action = actionDo,
			undo = undo,
		}
	end
	pfm.undoredo.action_position = pos
	while #pfm.undoredo.stack > pos do
		pfm.undoredo.stack[#pfm.undoredo.stack] = nil
	end
	local undoLimit = console.get_convar_int("pfm_max_undo_steps")
	while #pfm.undoredo.stack > undoLimit do
		pfm.log(
			"Undo limit reached, deleting undo step '" .. locale.get_text(pfm.undoredo.stack[1].name) .. "'...",
			pfm.LOG_CATEGORY_PFM_UNDOREDO
		)
		table.remove(pfm.undoredo.stack, 1)
		pfm.undoredo.action_position = pfm.undoredo.action_position - 1
	end
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnPush", name)
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnChange")
	if not isCommand then
		return actionDo
	end
	return function()
		return actionDo:Execute()
	end
end

pfm.undoredo.serialize = function(udmUndoRedo)
	local stack = pfm.undoredo.get_stack()
	udmUndoRedo:SetValue("undoPosition", udm.TYPE_UINT32, pfm.undoredo.get_undo_position())

	udmUndoRedo:RemoveValue("stack")
	udmUndoRedo:AddArray("stack", #stack, udm.TYPE_ELEMENT)

	pfm.log("Saving undo/redo stack with " .. #stack .. " items...", pfm.LOG_CATEGORY_PFM)
	local udmStack = udmUndoRedo:Get("stack")
	udmStack:Resize(#stack)
	local function write_command(udmData, cmd, name)
		udmData:Clear()
		udmData:SetValue("command", udm.TYPE_STRING, cmd:GetIdentifier())
		if name ~= nil then
			udmData:SetValue("name", udm.TYPE_STRING, name)
		end
		local subCommands = cmd:GetSubCommands()
		udmData:AddArray("subCommands", #subCommands, udm.TYPE_ELEMENT)
		local udmSubCmds = udmData:Get("subCommands")
		for i, subCmd in ipairs(subCommands) do
			write_command(udmSubCmds:Get(i - 1), subCmd)
		end
		local udmCmdData = udmData:Add("data")
		local data = cmd:GetData()
		udmCmdData:Merge(data, udm.MERGE_FLAG_BIT_DEEP_COPY)
	end
	for i, cmdData in ipairs(stack) do
		write_command(udmStack:Get(i - 1), cmdData.command, cmdData.command:GetIdentifier())
	end
end

pfm.undoredo.deserialize = function(udmUndoRedo)
	local udmStack = udmUndoRedo:Get("stack")
	local undoPosition = udmUndoRedo:GetValue("undoPosition", udm.TYPE_UINT32)

	pfm.log("Restoring undo/redo stack with " .. udmStack:GetSize() .. " items...", pfm.LOG_CATEGORY_PFM)
	local stack = {}
	local function read_command(udmData)
		local identifier = udmData:GetValue("command", udm.TYPE_STRING)
		local udmCmdData = udmData:Get("data")
		local cmd = pfm.create_command_object(identifier)
		if cmd ~= nil then
			cmd:GetData():Merge(udmCmdData, udm.MERGE_FLAG_BIT_DEEP_COPY)

			local udmSubCmds = udmData:Get("subCommands")
			for i = 0, udmSubCmds:GetSize() - 1 do
				local udmSubCmd = udmSubCmds:Get(i)
				local subCmd = read_command(udmSubCmd)
				if subCmd ~= nil then
					cmd:AddSubCommandObject(subCmd)
				end
			end
			return cmd
		else
			pfm.log(
				"Failed to restore undo/redo command '" .. identifier .. "' from project: Command not found!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_ERROR
			)
		end
	end
	for i = 0, udmStack:GetSize() - 1 do
		local udmData = udmStack:Get(i)
		local cmd = read_command(udmData)
		if cmd ~= nil then
			local name = udmData:GetValue("name", udm.TYPE_STRING)
			table.insert(stack, {
				name = pfm.undoredo.get_locale_identifier(name),
				command = cmd,
			})
		end
	end
	pfm.undoredo.set_stack(stack, undoPosition)
end

pfm.undoredo.clear = function()
	pfm.log("Clearing undoredo stack.", pfm.LOG_CATEGORY_PFM_UNDOREDO)
	pfm.undoredo.stack = {}
	pfm.undoredo.action_position = 0
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnClear")
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnChange")
end

pfm.has_undo = function()
	local pos = pfm.undoredo.action_position
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return false
	end
	return true
end

pfm.get_undo_text = function()
	local pos = pfm.undoredo.action_position
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return
	end
	return locale.get_text(data.name)
end

pfm.undo = function()
	local pos = pfm.undoredo.action_position
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return
	end
	pfm.log("Undoing action #" .. pos .. " '" .. locale.get_text(data.name) .. "'...", pfm.LOG_CATEGORY_PFM_UNDOREDO)
	local pm = pfm.get_project_manager()
	if util.is_valid(pm) then
		pm:AddUndoMessage(locale.get_text("undo") .. ": " .. locale.get_text(data.name))
	end
	if data.command ~= nil then
		data.command:Undo()
	else
		data.undo()
	end
	pfm.undoredo.action_position = pos - 1

	pfm.tag_render_scene_as_dirty()
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnUndo", data.name)
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnChange")
end

pfm.has_redo = function()
	local pos = pfm.undoredo.action_position + 1
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return false
	end
	return true
end

pfm.get_redo_text = function()
	local pos = pfm.undoredo.action_position + 1
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return
	end
	return locale.get_text(data.name)
end

pfm.redo = function()
	local pos = pfm.undoredo.action_position + 1
	local data = pfm.undoredo.stack[pos]
	if data == nil then
		return
	end
	pfm.log("Redoing action #" .. pos .. " '" .. locale.get_text(data.name) .. "'...", pfm.LOG_CATEGORY_PFM_UNDOREDO)
	local pm = pfm.get_project_manager()
	if util.is_valid(pm) then
		pm:AddUndoMessage(locale.get_text("redo") .. ": " .. locale.get_text(data.name))
	end
	if data.command ~= nil then
		data.command:Execute()
	else
		data.action()
	end
	pfm.undoredo.action_position = pos

	pfm.tag_render_scene_as_dirty()
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnRedo", data.name)
	pfm.undoredo.detail.callback_handler:CallCallbacks("OnChange")
end

pfm.undoredo.get_stack = function()
	return pfm.undoredo.stack
end

pfm.undoredo.set_stack = function(stack, undoPosition)
	pfm.undoredo.stack = stack
	pfm.undoredo.action_position = undoPosition
end

pfm.undoredo.detail.print = function()
	print("Position: ", pfm.undoredo.action_position)
	print("Stack:")
	console.print_table(pfm.undoredo.stack)
end

pfm.undoredo.detail.unit_test = function()
	local function push_case(i)
		pfm.undoredo.push(tostring(i), function()
			print("Do (" .. i .. ")")
		end, function()
			print("Undo (" .. i .. ")")
		end)
	end
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
