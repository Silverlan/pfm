-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMActorComponent.RotationChannel", ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.RotationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.RotationChannel:GetInterpolatedValue(value0, value1, interpAm)
	return value0:Slerp(value1, interpAm)
end
function ents.PFMActorComponent.RotationChannel:ApplyValue(ent, controllerId, value)
	ent:SetRotation(value)
	return true
end
