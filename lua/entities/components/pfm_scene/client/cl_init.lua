util.register_class("ents.PFMScene",BaseEntityComponent)

function ents.PFMScene:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_LOGIC)
	self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
end

function ents.PFMScene:OnTick(dt)
	if(util.is_valid(self.m_entTrack) == false) then return end
	local trackC = self.m_entTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
	if(trackC == nil) then return end
	trackC:Advance(dt)
end

function ents.PFMScene:OnRemove()
	self:StopPlayback()
end

function ents.PFMScene:SetScene(scene) self.m_scene = scene end

function ents.PFMScene:StartPlayback(track)
	self:StopPlayback()
	
	local entTrack = ents.create("pfm_track")
	self.m_entTrack = entTrack
	entTrack:Spawn()
	entTrack:GetComponent(ents.COMPONENT_PFM_TRACK):SetTrack(track)
end

function ents.PFMScene:StopPlayback()
	if(util.is_valid(self.m_entTrack)) then self.m_entTrack:Remove() end
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene",ents.PFMScene)
