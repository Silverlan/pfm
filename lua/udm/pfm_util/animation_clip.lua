--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.AnimationClip:OnInitialize()

end
function pfm.udm.AnimationClip:FindChannel(path)
    for _,channel in ipairs(self:GetAnimation():GetChannels()) do
        if(channel:GetTargetPath() == path) then return channel end
    end
end

function pfm.udm.AnimationClip:GetChannel(path,type,addIfNotExists)
    local channel = self:FindChannel(path)
    if(channel ~= nil) then return channel end
    if(addIfNotExists ~= true) then return end
    channel = self:AddChannel(type)
    channel:SetTargetPath(path)
    return channel
end

function pfm.udm.AnimationClip:AddChannel(type)
    local anim = self:GetAnimation()
    local channel = anim:AddChannel()
    channel:SetValuesValueType(type)
    self.m_panimaAnim = nil
    return channel
end

function pfm.udm.AnimationClip:SetPanimaAnimationDirty()
    self.m_panimaAnim = nil
end

function pfm.udm.AnimationClip:GetPanimaAnimation()
    if(self.m_panimaAnim == nil) then
        self.m_panimaAnim = panima.Animation.load(self:GetAnimation():GetUdmData())
        -- TODO: Re-create panima animation when properties have changed or new channel has been added
    end
    return self.m_panimaAnim
end
