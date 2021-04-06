util.register_class("ents.UtilTransformComponent",BaseEntityComponent)

ents.UtilTransformComponent.SPACE_WORLD = 0
ents.UtilTransformComponent.SPACE_LOCAL = 1
ents.UtilTransformComponent.SPACE_VIEW = 2

function ents.UtilTransformComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	if(CLIENT) then
		self.m_translationAxisEnabled = {}
		self.m_rotationAxisEnabled = {}

		self.m_translationAxisEnabled[math.AXIS_X] = true
		self.m_translationAxisEnabled[math.AXIS_Y] = true
		self.m_translationAxisEnabled[math.AXIS_Z] = true

		self.m_rotationAxisEnabled[math.AXIS_X] = true
		self.m_rotationAxisEnabled[math.AXIS_Y] = true
		self.m_rotationAxisEnabled[math.AXIS_Z] = true

		self.m_arrows = {}
		self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

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
