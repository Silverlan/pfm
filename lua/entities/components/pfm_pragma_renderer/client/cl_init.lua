--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMPragmaRenderer", BaseEntityComponent)
function Component:Initialize() end
function Component:OnRender()
	local motionBlurId = ents.get_component_id("pfm_motion_blur")
	if motionBlurId == nil then
		return
	end
	local e, c = ents.citerator(motionBlurId)()
	if c ~= nil then
		local rendererC = self:GetEntity():GetComponent(ents.COMPONENT_RENDERER)
		if rendererC ~= nil then
			c:AddRenderer(rendererC)
		end
	end
end
 ents.register_component("pfm_pragma_renderer", Component,"pfm")
