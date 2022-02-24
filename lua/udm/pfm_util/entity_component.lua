--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.EntityComponent:SetMemberValue(memberName,type,value)
    self:GetProperties():SetValue(memberName,type,value)
    self:CallChangeListeners(memberName,value)
end

function pfm.udm.EntityComponent:GetMemberValue(memberName)
    return self:GetProperties():Get(memberName):GetValue()
end

function pfm.udm.EntityComponent:GetActor() return self:GetParent() end
