--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMActorComponent.RotationChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.RotationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.RotationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Slerp(value1,interpAm)
end
function ents.PFMActorComponent.RotationChannel:ApplyValue(ent,controllerId,value)
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return false end
	if(controllerId == ents.PFMActorComponent.ROOT_TRANSFORM_ID) then
		ent:SetRotation(value)
		return true
	end
	animC:SetBoneRot(controllerId,value)
	return true
end
