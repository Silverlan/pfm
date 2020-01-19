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
	end
end
ents.COMPONENT_UTIL_TRANSFORM = ents.register_component("util_transform",ents.UtilTransformComponent)
