util.register_class("ents.PFMActorComponent.TranslationChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.TranslationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.TranslationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Lerp(value1,interpAm)
end
function ents.PFMActorComponent.TranslationChannel:ApplyValue(ent,controllerId,value)
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return false end
	if(controllerId == ents.PFMActorComponent.ROOT_TRANSFORM_ID) then
		ent:SetPos(value)
		return true
	end
	animC:SetBonePos(controllerId,value)
	return true
end
