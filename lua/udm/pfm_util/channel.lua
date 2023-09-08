--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Channel:OnInitialize() end

function pfm.udm.Channel:GetAnimation()
	return self:GetParent()
end

function pfm.udm.Channel:GetPanimaChannel()
	return self:GetAnimation():GetAnimationClip():GetPanimaAnimation():FindChannel(self:GetTargetPath())
end

function pfm.udm.Channel:ChangeExpression(expr)
	local oldExpr = self:GetExpression()
	self:SetExpression(expr)

	local animationClip = self:GetAnimation():GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners("OnAnimationChannelMathExpressionChanged", track, animationClip, self, oldExpr, expr)
end
