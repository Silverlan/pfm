util.register_class("ents.PFMScene",BaseEntityComponent)

function ents.PFMScene:Initialize()
	BaseEntityComponent.Initialize(self)
	
	--self:AddEntityComponent(ents.COMPONENT_LOGIC)
	--self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
end

--[[function ents.PFMScene:OnTick(dt)
	if(util.is_valid(self.m_entTrack) == false) then return end
	local trackC = self.m_entTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
	if(trackC == nil) then return end
	trackC:Advance(dt)
end]]

function ents.PFMScene:OnRemove()
	self:StopPlayback()
end

function ents.PFMScene:SetScene(scene) self.m_scene = scene end

function ents.PFMScene:SetOffset(offset)
	if(util.is_valid(self.m_entTrack)) then
		local trackC = self.m_entTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:SetOffset(offset) end
	end
end

function ents.PFMScene:GetOffset()
	if(util.is_valid(self.m_entTrack) == false) then return 0.0 end
	local trackC = self.m_entTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
	return (trackC ~= nil) and trackC:GetOffset() or 0.0
end

function ents.PFMScene:GetTrackTimeFrame()
	local trackC = util.is_valid(self.m_entTrack) and self.m_entTrack:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
	if(trackC == nil) then return udm.PFMTimeFrame() end
	return trackC:GetTimeFrame()
end

function ents.PFMScene:StartPlayback(track)
	self:StopPlayback()
	
	local entTrack = ents.create("pfm_track")
	self.m_entTrack = entTrack
	entTrack:Spawn()
	entTrack:GetComponent(ents.COMPONENT_PFM_TRACK):SetTrack(track)
end

function ents.PFMScene:Start()
	local scene = self.m_scene
	if(scene == nil) then return end
	for name,node in pairs(scene:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
			if(node:GetMuted() == false and node:GetName() == "Film") then
				self:StartPlayback(node)
				break
			end
		end
	end
end

function ents.PFMScene:StopPlayback()
	if(util.is_valid(self.m_entTrack)) then self.m_entTrack:Remove() end
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene",ents.PFMScene)
