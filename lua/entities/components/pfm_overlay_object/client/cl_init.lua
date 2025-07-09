-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMOverlayObject", BaseEntityComponent)

function Component:Initialize() end
function Component:OnEntitySpawn()
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	local scene = pm:GetOverlayScene()
	if util.is_valid(scene) then
		self:GetEntity():AddToScene(scene)
	end
end
function Component:OnRemove()
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	local scene = pm:GetOverlayScene()
	if util.is_valid(scene) then
		self:GetEntity():RemoveFromScene(scene)
	end
end
ents.register_component("pfm_overlay_object", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
