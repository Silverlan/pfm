-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMEditor", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnEntitySpawn()
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) then
		cam:GetEntity():AddComponent("pfm_work_camera")
	end
	self:SetPlayerEnabled(false)
end
function Component:GetWorkCamera()
	return game.get_primary_camera()
end
function Component:OnRemove()
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) then
		cam:GetEntity():RemoveComponent(ents.COMPONENT_PFM_WORK_CAMERA)
	end
	self:SetPlayerEnabled(true)
end
function Component:SetPlayerEnabled(enabled)
	local packet = net.Packet()
	packet:WriteBool(enabled)
	net.send(net.PROTOCOL_SLOW_RELIABLE, "sv_pfm_set_player_movement_enabled", packet)

	local pl = ents.get_local_player()
	if util.is_valid(pl) then
		local ent = pl:GetEntity()
		local inputControllerC = ent:GetComponent(ents.COMPONENT_INPUT_MOVEMENT_CONTROLLER)
		if inputControllerC ~= nil then
			inputControllerC:SetActive(enabled)
		end

		local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		if renderC ~= nil then
			renderC:SetSceneRenderPass(enabled and game.SCENE_RENDER_PASS_WORLD or game.SCENE_RENDER_PASS_NONE)
		end
	end
end
ents.register_component("pfm_editor", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
