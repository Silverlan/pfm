--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMActorComponent.TranslationChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.TranslationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.TranslationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Lerp(value1,interpAm)
end
function ents.PFMActorComponent.TranslationChannel:ApplyValue(ent,controllerId,value)
	ent:SetPos(value)
	return true
end
