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
