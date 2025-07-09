-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMActorComponent.TranslationChannel", ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.TranslationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.TranslationChannel:GetInterpolatedValue(value0, value1, interpAm)
	return value0:Lerp(value1, interpAm)
end
function ents.PFMActorComponent.TranslationChannel:ApplyValue(ent, controllerId, value)
	ent:SetPos(value)
	return true
end
