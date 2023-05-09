--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVrTrackedDevice", BaseEntityComponent)

Component:RegisterMember("SerialNumber", ents.MEMBER_TYPE_STRING, "", {
	flags = ents.ComponentInfo.MemberInfo.FLAG_READ_ONLY_BIT,
})
Component:RegisterMember("TargetActor", ents.MEMBER_TYPE_ENTITY, "")
Component:RegisterMember("IkControl", ents.MEMBER_TYPE_STRING, "")

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnRemove() end

function Component:OnEntitySpawn() end

function Component:SetTrackedDevice(tdC)
	self.m_trackedDevice = tdC
end
function Component:GetTrackedDevice()
	return self.m_trackedDevice
end
ents.COMPONENT_PFM_VR_TRACKED_DEVICE = ents.register_component("pfm_vr_tracked_device", Component)
