util.register_class("ents.UtilTransformComponent",BaseEntityComponent)

function ents.UtilTransformComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	if(CLIENT) then
		self.m_arrows = {}
		self:AddEntityComponent(ents.COMPONENT_LOGIC)
		self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")

		self:GetTranslationEnabledProperty():AddCallback(function()
			if(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION] == nil) then return end
			for axis,ent in pairs(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION]) do
				if(ent:IsValid()) then ent:RemoveSafely() end
			end
			self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION] = nil
		end)
		self:GetRotationEnabledProperty():AddCallback(function()
			if(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION] == nil) then return end
			for axis,ent in pairs(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION]) do
				if(ent:IsValid()) then ent:RemoveSafely() end
			end
			self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION] = nil
		end)
	end
end
ents.COMPONENT_UTIL_TRANSFORM = ents.register_component("util_transform",ents.UtilTransformComponent)
