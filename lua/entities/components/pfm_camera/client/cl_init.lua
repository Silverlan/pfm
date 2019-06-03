util.register_class("ents.PFMCamera",BaseEntityComponent)

function ents.PFMCamera:__init()
	BaseEntityComponent.__init(self)
end

function ents.PFMCamera:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
end

ents.COMPONENT_PFM_CAMERA = ents.register_component("pfm_camera",ents.PFMCamera)
