-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMChannelClip", BaseEntityComponent)

function ents.PFMChannelClip:Initialize()
	BaseEntityComponent.Initialize(self)
end

function ents.PFMChannelClip:OnRemove() end

function ents.PFMChannelClip:Setup(channelClipData, trackC)
	self.m_channelClipData = channelClipData
	self.m_track = trackC
	self:GetEntity():SetName(channelClipData:GetName())

	local trackGroupC = util.is_valid(trackC) and trackC:GetTrackGroup() or nil
	local filmClipC = util.is_valid(trackGroupC) and trackGroupC:GetFilmClip() or nil
	local actor = util.is_valid(filmClipC) and filmClipC:FindActorByName(self:GetEntity():GetName()) or nil
	if util.is_valid(actor) == false then
		self:LogWarn("Could not find actor for channel clip '" .. self:GetEntity():GetName() .. "'!")
		return
	end
	self.m_targetActor = actor
end

function ents.PFMChannelClip:GetChannelClipData()
	return self.m_channelClipData
end
function ents.PFMChannelClip:GetTrack()
	return self.m_track
end

function ents.PFMChannelClip:GetTimeFrame()
	local clip = self:GetChannelClipData()
	if clip == nil then
		return fudm.PFMTimeFrame()
	end
	return clip:GetTimeFrame()
end

function ents.PFMChannelClip:SetOffset(offset)
	local timeFrame = self:GetTimeFrame()
	offset = offset - timeFrame:GetStart() + timeFrame:GetOffset()

	if util.is_valid(self.m_targetActor) then
		local actorC = self.m_targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if actorC ~= nil then
			actorC:OnOffsetChanged(offset)
		end
	end

	--filmClip:GetActors():GetTable()[1]
	-- Componentsn
	--fudm.ELEMENT_TYPE_PFM_MODEL
	--local actorData = ents.find_by_class("pfm_actor")[1]
	local clip = self:GetChannelClipData()
	for _, channel in ipairs(clip:GetChannels():GetTable()) do
		local toElement = channel:GetToElement()
		--[[if(util.get_type_name(toElement) == "PFMModel") then
			print(channel:GetName())
		end]]
		if channel:GetName() == "player/hwm/pyro_rootPos channel" then
			--[[
function fudm.BaseAttribute:AddChangeListener(listener)
	local cb = util.Callback(listener)
	table.insert(self.m_listeners,cb)
	return cb
end
]]
			--[[print(util.get_type_name(toElement))
			toElement:GetPositionAttr():AddChangeListener(function(newValue)
				print("Postion value has changed: ",newValue)
			end)
			toElement:SetPosition(Vector(1,2,3))]]
		end
		--if(toElement:GetType() ~= fudm.ELEMENT_TYPE_NIL) then
		--if(channel:GetName() == "player/hwm/pyro_bonePos 1") then
		--local actorC = self.m_targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
		--[[local actorData = _actor--actorC:GetActorData()
				for _,component in ipairs(actorData:GetComponents():GetTable()) do
					if(component:GetType() == fudm.ELEMENT_TYPE_PFM_MODEL) then
						local bones = component:GetBones()
						for _,bone in ipairs(bones) do
							if(bone:GetName() == "player/hwm/pyro_bonePos 1") then
								print("Found bone " .. bone:GetName())
								local pos = bone:GetPosition()
								print("Bone Pos: ",pos)
							end
						end
					end
				end]]
		--end
		--print("Channel: ",channel:GetName())
		--print("To Element Type: ",util.get_type_name(toElement))
		--if(toElement:IsElement()) then
		--	print("To Element: ",toElement:GetName())
		--end
		--end
		--[[
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"log",fudm.PFMLog())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"toAttribute",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"toElement",fudm.Any())
]]
	end
end
ents.register_component(
	"pfm_channel_clip",
	ents.PFMChannelClip,
	"pfm",
	ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR
)
