--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_selection.lua")
include("/shaders/pfm/pfm_selection_wireframe.lua")

util.register_class("pfm.SelectionManager")
function pfm.SelectionManager:__init()
	self.m_selections = {}
	self.m_listeners = {}
end

function pfm.SelectionManager:AddChangeListener(listener) table.insert(self.m_listeners,listener) end

function pfm.SelectionManager:GetSelectedObjects() return self.m_selections end

function pfm.SelectionManager:Remove()
	self:ClearSelections()
end

function pfm.SelectionManager:ClearSelections()
	local selections = self.m_selections
	self.m_selections = {}
	for object,selected in pairs(selections) do
		if(object:IsValid()) then
			for _,listener in ipairs(self.m_listeners) do
				listener(object,false)
			end
		end
	end
end

function pfm.SelectionManager:SetSelected(obj,selected)
	self.m_selections[obj] = selected or nil
	for _,listener in ipairs(self.m_listeners) do
		listener(obj,selected)
	end
end

function pfm.SelectionManager:Select(obj) self:SetSelected(obj,true) end
function pfm.SelectionManager:Deselect(obj) self:SetSelected(obj,false) end

-----------------

util.register_class("pfm.ActorSelectionManager",pfm.SelectionManager)
function pfm.ActorSelectionManager:__init()
	pfm.SelectionManager.__init(self)
	self.m_callback = game.add_callback("PrepareRendering",function(renderer)
		self:PrepareSelectionMeshesForRendering(renderer)
	end)
	self.m_material = game.load_material("white") -- game.get_error_material() -- We don't need any materials for the selection shaders, so we'll just use the error material
	self.m_shader = shader.get("pfm_selection")
	self.m_shaderWireframe = shader.get("pfm_selection_wireframe")
	self.m_valid = (self.m_material ~= nil and self.m_shader ~= nil and self.m_shaderWireframe ~= nil)
end

function pfm.ActorSelectionManager:GetSelectedActors() return self:GetSelectedObjects() end

function pfm.ActorSelectionManager:PrepareSelectionMeshesForRendering(renderer)
	if(self.m_valid == false) then return end
	for ent,selected in pairs(self.m_selections) do
		if(ent:IsValid() == false) then self.m_selections[ent] = nil
		else
			local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
			if(renderC ~= nil) then
				for _,mesh in ipairs(renderC:GetLODMeshes()) do
					for _,subMesh in ipairs(mesh:GetSubMeshes()) do
						--renderer:ScheduleMeshForRendering(game.SCENE_RENDER_PASS_WORLD,self.m_shader,self.m_material,ent,subMesh)
						--renderer:ScheduleMeshForRendering(game.SCENE_RENDER_PASS_WORLD,self.m_shaderWireframe,self.m_material,ent,subMesh)
					end
				end
			end
		end
	end
end

function pfm.ActorSelectionManager:Remove()
	pfm.SelectionManager.Remove(self)
	if(util.is_valid(self.m_callback)) then self.m_callback:Remove() end
end
