--[[
    Copyright (C) 2021 Silverlan

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
	ent:SetRotation(value)
	return true
end
