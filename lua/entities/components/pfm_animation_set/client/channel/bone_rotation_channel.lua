--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMAnimationSet.BoneRotationChannel",ents.PFMActorComponent.Channel)
function ents.PFMAnimationSet.BoneRotationChannel:__init(modelC)
	ents.PFMActorComponent.Channel.__init(self)
	self.m_modelC = modelC
end
function ents.PFMAnimationSet.BoneRotationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Slerp(value1,interpAm)
end
function ents.PFMAnimationSet.BoneRotationChannel:ApplyValue(ent,controllerId,value)
	self.m_modelC:SetBoneRot(controllerId,value)
	return true
end
