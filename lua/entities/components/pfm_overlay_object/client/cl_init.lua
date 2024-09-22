--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
