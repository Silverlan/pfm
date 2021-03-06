--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMAnimationSet.BoneTranslationChannel",ents.PFMActorComponent.Channel)
function ents.PFMAnimationSet.BoneTranslationChannel:__init(modelC)
	ents.PFMActorComponent.Channel.__init(self)
	self.m_modelC = modelC
end
function ents.PFMAnimationSet.BoneTranslationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Lerp(value1,interpAm)
end
function ents.PFMAnimationSet.BoneTranslationChannel:ApplyValue(ent,controllerId,value)
	self.m_modelC:SetBonePos(controllerId,value)
	return true
end
