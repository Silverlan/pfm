--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_selection.lua")
include("/shaders/pfm/pfm_selection_wireframe.lua")

util.register_class("pfm.SelectionManager")
function pfm.SelectionManager:__init()
	self.m_callback = game.add_callback("PrepareRendering",function(renderer)
		self:PrepareSelectionMeshesForRendering(renderer)
	end)
	self.m_material = game.get_error_material() -- We don't need any materials for the selection shaders, so we'll just use the error material
	self.m_selections = {}
	self.m_shader = shader.get("pfm_selection")
	self.m_shaderWireframe = shader.get("pfm_selection_wireframe")
	self.m_valid = (self.m_material ~= nil and self.m_shader ~= nil and self.m_shaderWireframe ~= nil)
end

function pfm.SelectionManager:PrepareSelectionMeshesForRendering(renderer)
	if(self.m_valid == false) then return end
	for ent,selected in pairs(self.m_selections) do
		local renderC = ent:IsValid() and ent:GetComponent(ents.COMPONENT_RENDER) or nil
		if(renderC == nil) then
			self.m_selections[ent] = nil
		else
			for _,mesh in ipairs(renderC:GetLODMeshes()) do
				for _,subMesh in ipairs(mesh:GetSubMeshes()) do
					renderer:ScheduleMeshForRendering(ents.RenderComponent.RENDERMODE_WORLD,self.m_shader,self.m_material,ent,subMesh)
					renderer:ScheduleMeshForRendering(ents.RenderComponent.RENDERMODE_WORLD,self.m_shaderWireframe,self.m_material,ent,subMesh)
				end
			end
		end
	end
end

function pfm.SelectionManager:Remove()
	self:ClearSelections()
	if(util.is_valid(self.m_callback)) then self.m_callback:Remove() end
end

function pfm.SelectionManager:ClearSelections()
	self.m_selections = {}
end

function pfm.SelectionManager:SetSelected(ent,selected)
	self.m_selections[ent] = selected or nil
end

function pfm.SelectionManager:Select(ent) self:SetSelected(ent,true) end
function pfm.SelectionManager:Deselect(ent) self:SetSelected(ent,false) end
