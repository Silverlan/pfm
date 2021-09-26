--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMSky",BaseEntityComponent)

local Component = ents.PFMSky
Component:RegisterMember("Strength",udm.TYPE_FLOAT,1.0,{
	min = 0.0,
	max = 10.0
})
Component:RegisterMember("Transparent",udm.TYPE_BOOLEAN,false)
Component:RegisterMember("SkyTexture",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	metaData = {
		rootPath = "materials/skies/",
		basePath = "skies/",
		extensions = {"hdr"},
		stripExtension = true
	}
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_callbacks = {}
	table.insert(self.m_callbacks,ents.add_component_creation_listener("unirender",function(c)
		table.insert(self.m_callbacks,c:AddEventCallback(ents.UnirenderComponent.EVENT_INITIALIZE_SCENE,function(scene,renderSettings)
			scene:SetSkyAngles(self:GetEntity():GetAngles())
			scene:SetSkyStrength(self:GetStrength())
			local tex = self:GetSkyTexture()
			if(#tex > 0) then scene:SetSky(tex) end
			scene:SetSkyTransparent(self:GetTransparent())
		end))
	end))
end
function Component:OnRemove()
	util.remove(self.m_callbacks)
end
ents.COMPONENT_PFM_SKY = ents.register_component("pfm_sky",Component)
