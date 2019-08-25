util.register_class("ents.PFMClip",BaseEntityComponent)

function ents.PFMClip:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = 0.0
	self.m_entities = {}
	self:AddEntityComponent(ents.COMPONENT_NAME)
end

function ents.PFMClip:OnRemove()
	self:Stop()
end

function ents.PFMClip:GetOffset() return self.m_offset end
function ents.PFMClip:SetOffset(offset)
	if(offset == self.m_offset) then return end
	self.m_offset = offset
	self:UpdateClip()
	
	self:BroadcastEvent(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,{offset})
end
function ents.PFMClip:Advance(dt) self:SetOffset(self:GetOffset() +dt) end

function ents.PFMClip:UpdateClip()
	--print("Updateing clip...")
	--
end

function ents.PFMClip:SetClip(udmClip) self.m_clip = udmClip end
function ents.PFMClip:GetClip() return self.m_clip end

function ents.PFMClip:InitializeActors()
	-- Iterate animation sets of clip and create actors accordingly
	
end

function ents.PFMClip:Start()
	if(self:IsActive()) then return end
	self.m_bActive = true
	print("Clip " .. self:GetClip():GetName() .. " has been started!")
	local clip = self:GetClip()
	if(clip:GetType() == udm.ELEMENT_TYPE_PFM_AUDIO_CLIP) then
		local entSound = ents.create("pfm_sound_source")
		entSound:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE):Setup(self,clip:GetSound())
		entSound:Spawn()
		table.insert(self.m_entities,entSound)
	end
end

function ents.PFMClip:Stop()
	if(self:IsActive() == false) then return end
	self.m_bActive = false
	print("Clip " .. self:GetClip():GetName() .. " has been stopped!")
	for _,ent in ipairs(self.m_entities) do
		if(ent:IsValid()) then ent:Remove() end
	end
	self.m_entities = {}
end

function ents.PFMClip:IsActive() return self.m_bActive end
ents.COMPONENT_PFM_CLIP = ents.register_component("pfm_clip",ents.PFMClip)
ents.PFMClip.EVENT_ON_OFFSET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_CLIP,"on_offset_changed")
