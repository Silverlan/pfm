--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Track:FindActorAnimationClip(actor,addIfNotExists)
    if(type(actor) ~= "string") then actor = tostring(actor:GetUniqueId()) end
    for _,channelClip in ipairs(self:GetAnimationClips()) do
        if(tostring(channelClip:GetActorId()) == actor) then return channelClip,false end
    end
    if(addIfNotExists ~= true) then return end
    actor = udm.dereference(self:GetSchema(),actor)
    if(actor == nil) then return end
    channelClip = self:AddAnimationClip()
    channelClip:SetName(actor:GetName())
    channelClip:SetActor(actor:GetUniqueId())
    return channelClip,true
end
