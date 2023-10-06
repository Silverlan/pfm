--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

console.register_variable(
	"pfm_save_undo_stack",
	udm.TYPE_BOOLEAN,
	true,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, the undo/redo stack will be saved with the project file and restored when the project is loaded."
)

pfm = pfm or {}
pfm.impl = pfm.impl or {}
pfm.impl.commands = pfm.impl.commands or {}
pfm.impl.commandToIdentifier = pfm.impl.commandToIdentifier or {}
function pfm.register_command(identifier, class)
	pfm.impl.commands[identifier] = {
		class = class,
	}
	pfm.impl.commandToIdentifier[class] = identifier
end
function pfm.create_command_object(identifier, ...)
	local cmd = pfm.impl.commands[identifier]
	if cmd == nil then
		return
	end
	local o = cmd.class()
	o.m_identifier = identifier
	return o
end
function pfm.create_command(identifier, ...)
	local o = pfm.create_command_object(identifier, ...)
	if o == nil then
		return
	end
	local res = o:Initialize(...)
	if res == pfm.Command.RESULT_FAILURE or res == pfm.Command.RESULT_NO_OP then
		return
	end
	return o
end
function pfm.run_command(identifier, ...)
	local cmd = pfm.impl.commands[identifier]
	if cmd == nil then
		return
	end
	local o = cmd(...)
	o:Execute()
end

local BaseCommand = util.register_class("pfm.Command")
BaseCommand.RESULT_SUCCESS = 0
BaseCommand.RESULT_FAILURE = 1
BaseCommand.RESULT_NO_OP = 2
BaseCommand.RESULT_INVALID_COMMAND = 3

BaseCommand.ACTION_DO = 0
BaseCommand.ACTION_UNDO = 1

function BaseCommand:__init()
	self.m_data = udm.create("PFMCMD", 1)
	self.m_subCommands = {}
end
function BaseCommand:Initialize()
	return false
end
function BaseCommand:GetIdentifier()
	return self.m_identifier or ""
end
function BaseCommand:GetData()
	return self.m_data:GetAssetData():GetData()
end
function BaseCommand:DoExecute() end
function BaseCommand:StartExecute(depth)
	pfm.log(
		string.rep(" ", depth) .. 'Executing command "' .. tostring(self:GetIdentifier() .. '"...'),
		pfm.LOG_CATEGORY_PFM
	)
end
function BaseCommand:Execute(depth)
	depth = depth or 0
	self:StartExecute(depth)

	for _, subCmd in ipairs(self.m_subCommands) do
		subCmd:Execute(depth + 1)
	end
	return self:DoExecute(self:GetData())
end
function BaseCommand:DoUndo() end
function BaseCommand:StartUndo(depth)
	pfm.log(
		string.rep(" ", depth) .. 'Undoing command "' .. tostring(self:GetIdentifier() .. '"...'),
		pfm.LOG_CATEGORY_PFM
	)
end
function BaseCommand:Undo(depth)
	depth = depth or 0
	self:StartUndo(depth)

	local results = { self:DoUndo(self:GetData()) }
	for i = #self.m_subCommands, 1, -1 do
		local subCmd = self.m_subCommands[i]
		subCmd:Undo(depth + 1)
	end
	return unpack(results)
end
function BaseCommand:GetProjectManager()
	return pfm.get_project_manager()
end
function BaseCommand:GetAnimationManager()
	return self:GetProjectManager():GetAnimationManager()
end
function BaseCommand:SetActorPropertyDirty(actor, property)
	self:GetAnimationManager():SetAnimationDirty(actor)
	local pm = self:GetProjectManager()
	local actorEditor = pm:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:UpdateActorProperty(actor, property)
	end
	pfm.tag_render_scene_as_dirty()
end
function BaseCommand:LogFailure(msg)
	pfm.log(
		"Failed to execute command '" .. self:GetIdentifier() .. "': " .. msg,
		pfm.LOG_CATEGORY_PFM,
		pfm.LOG_SEVERITY_WARNING
	)
end
function BaseCommand:GetSubCommands()
	return self.m_subCommands
end
function BaseCommand:AddSubCommandObject(o)
	table.insert(self.m_subCommands, o)
end
function BaseCommand:AddSubCommand(identifier, ...)
	local o
	if type(identifier) == "string" then
		o = pfm.create_command_object(identifier, ...)
		if o == nil then
			self:LogFailure("Failed to create sub-command '" .. identifier .. "': No such command found!")
			return pfm.Command.RESULT_INVALID_COMMAND
		end
	else
		o = identifier
		identifier = o:GetIdentifier()
	end

	local res = o:Initialize(...)
	if res == pfm.Command.RESULT_FAILURE then
		self:LogFailure("Failed to create sub-command '" .. identifier .. "'!")
		return res
	elseif res == pfm.Command.RESULT_NO_OP then
		return res
	end
	self:AddSubCommandObject(o)
	return res, o
end

local CommandComposition = util.register_class("pfm.CommandComposition", pfm.Command)
function CommandComposition:Initialize(cmds)
	for _, cmd in ipairs(cmds or {}) do
		self:AddSubCommand(cmd)
	end
end
pfm.register_command("composition", CommandComposition)

include("commands")
