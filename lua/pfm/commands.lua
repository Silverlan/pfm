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
function pfm.register_command(identifier, class)
	pfm.impl.commands[identifier] = {
		class = class,
	}
end
function pfm.create_command(identifier, ...)
	local cmd = pfm.impl.commands[identifier]
	if cmd == nil then
		return
	end
	local o = cmd.class()
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

function BaseCommand:__init()
	self.m_data = udm.create("PFMCMD", 1)
	self.m_subCommands = {}
end
function BaseCommand:Initialize()
	return false
end
function BaseCommand:GetIdentifier()
	return util.get_type_name(self)
end
function BaseCommand:GetData()
	return self.m_data:GetAssetData():GetData()
end
function BaseCommand:DoExecute() end
function BaseCommand:Execute()
	for _, subCmd in ipairs(self.m_subCommands) do
		subCmd:Execute()
	end
	return self:DoExecute(self:GetData())
end
function BaseCommand:DoUndo() end
function BaseCommand:Undo()
	local results = { self:DoUndo(self:GetData()) }
	for _, subCmd in ipairs(self.m_subCommands) do
		subCmd:Undo()
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
function BaseCommand:AddSubCommand(identifier, ...)
	local o
	if type(identifier) == "string" then
		local cmd = pfm.impl.commands[identifier]
		if cmd == nil then
			self:LogFailure("Failed to create sub-command '" .. identifier .. "': No such command found!")
			return
		end
		o = cmd.class()
	else
		o = identifier
		identifier = o:GetIdentifier()
	end

	local res = o:Initialize(...)
	if res == pfm.Command.RESULT_FAILURE then
		self:LogFailure("Failed to create sub-command '" .. identifier .. "'!")
		return
	elseif res == pfm.Command.RESULT_NO_OP then
		return
	end
	table.insert(self.m_subCommands, o)
end

local CommandComposition = util.register_class("pfm.CommandComposition", pfm.Command)
function CommandComposition:Initialize(cmds)
	for _, cmd in ipairs(cmds) do
		self:AddSubCommand(cmd)
	end
end

include("commands")