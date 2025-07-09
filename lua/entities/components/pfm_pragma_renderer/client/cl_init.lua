-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
ents.register_component("pfm_pragma_renderer", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
