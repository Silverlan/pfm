util.register_class("ents.UtilTransformComponent", BaseEntityComponent)

ents.UtilTransformComponent.SPACE_WORLD = math.COORDINATE_SPACE_WORLD
ents.UtilTransformComponent.SPACE_LOCAL = math.COORDINATE_SPACE_LOCAL
ents.UtilTransformComponent.SPACE_VIEW = math.COORDINATE_SPACE_VIEW

function ents.UtilTransformComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	if CLIENT then
		self.m_translationAxisEnabled = {}
		self.m_rotationAxisEnabled = {}
		self.m_scaleAxisEnabled = {}

		self.m_translationAxisEnabled[math.AXIS_X] = true
		self.m_translationAxisEnabled[math.AXIS_Y] = true
		self.m_translationAxisEnabled[math.AXIS_Z] = true

		self.m_rotationAxisEnabled[math.AXIS_X] = true
		self.m_rotationAxisEnabled[math.AXIS_Y] = true
		self.m_rotationAxisEnabled[math.AXIS_Z] = true

		self.m_scaleAxisEnabled[math.AXIS_X] = true
		self.m_scaleAxisEnabled[math.AXIS_Y] = true
		self.m_scaleAxisEnabled[math.AXIS_Z] = true

		self.m_arrows = {}

		self:GetTranslationEnabledProperty():AddCallback(function()
			if self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION] == nil then
				return
			end
			for axis, ents in pairs(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION]) do
				for id, ent in pairs(ents) do
					if ent:IsValid() then
						ent:RemoveSafely()
					end
				end
			end
			self.m_arrows[ents.UtilTransformArrowComponent.TYPE_TRANSLATION] = nil
		end)
		self:GetRotationEnabledProperty():AddCallback(function()
			if self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION] == nil then
				return
			end
			for axis, ents in pairs(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION]) do
				for id, ent in pairs(ents) do
					if ent:IsValid() then
						ent:RemoveSafely()
					end
				end
			end
			self.m_arrows[ents.UtilTransformArrowComponent.TYPE_ROTATION] = nil
		end)
		self:GetScaleEnabledProperty():AddCallback(function()
			if self.m_arrows[ents.UtilTransformArrowComponent.TYPE_SCALE] == nil then
				return
			end
			for axis, ents in pairs(self.m_arrows[ents.UtilTransformArrowComponent.TYPE_SCALE]) do
				for id, ent in pairs(ents) do
					if ent:IsValid() then
						ent:RemoveSafely()
					end
				end
			end
			self.m_arrows[ents.UtilTransformArrowComponent.TYPE_SCALE] = nil
		end)
	end
end
ents.COMPONENT_UTIL_TRANSFORM = ents.register_component("util_transform", ents.UtilTransformComponent)
