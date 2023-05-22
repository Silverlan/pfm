--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:UpdateKeyframe(actor, targetPath, panimaChannel, keyIdx, time, value, baseIndex)
	local animManager = self:GetAnimationManager()
	animManager:UpdateKeyframe(actor, targetPath, panimaChannel, keyIdx, time, value, baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:UpdateActorProperty(actor, targetPath)
	end
end
function Element:SetActorAnimationComponentProperty(actor, targetPath, time, value, valueType, baseIndex)
	local animManager = self:GetAnimationManager()
	animManager:SetChannelValue(actor, targetPath, time, value, valueType, nil, baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) then
		actorEditor:UpdateActorProperty(actor, targetPath)
	end
end

function Element:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) -- For internal use only
	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return true
	end
	return actorEditor:UpdateAnimationChannelValue(actorData, targetPath, value)
end
function Element:SetActorGenericProperty(actor, targetPath, value, udmType)
	local actorData = actor:GetActorData()
	if actorData == nil then
		return
	end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if util.is_valid(rt) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local function applyControllerTarget() -- TODO: Obsolete?
		local memberInfo = pfm.get_member_info(targetPath, actor:GetEntity())
		if memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_CONTROLLER_BIT) and memberInfo.metaData ~= nil then
			local meta = memberInfo.metaData
			local controllerTarget = meta:GetValue("controllerTarget")
			local applyResult = false
			if controllerTarget ~= nil then
				local memberInfoTarget = pfm.get_member_info(controllerTarget, actor:GetEntity())
				if memberInfoTarget ~= nil then
					local targetValue = actor:GetEntity():GetMemberValue(controllerTarget)
					if targetValue ~= nil then
						applyResult =
							self:SetActorGenericProperty(actor, controllerTarget, targetValue, memberInfoTarget.type)
					end
				end
			end
			return true, applyResult
		end
		return false
	end

	if self:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) == false then
		return
	end

	self:GetAnimationManager():SetAnimationDirty(actorData)
	local res
	if udmType ~= udm.TYPE_ELEMENT then
		res = actor:GetEntity():SetMemberValue(targetPath, value)
	else
		res = true
	end
	local hasControlTarget, ctResult = applyControllerTarget()
	if udmType ~= nil then
		local componentName, memberName =
			ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
		if componentName ~= nil then
			local c = actorData:AddComponentType(componentName)
			c:SetMemberValue(memberName:GetString(), udmType, value)
		end
	end
	self:GetActorEditor():UpdateActorProperty(actorData, targetPath)
	self:TagRenderSceneAsDirty()
	if hasControlTarget then
		return ctResult
	end
	return res
end
function Element:SetActorTransformProperty(actor, propType, value, applyUdmValue)
	local actorData = actor:GetActorData()
	if actorData == nil then
		return
	end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if util.is_valid(rt) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local actorEditor = self:GetActorEditor()
	local targetPath = "ec/pfm_actor/" .. propType

	if self:UpdateActorAnimatedPropertyValue(actorData, targetPath, value) == false then
		return
	end

	local transform = actorData:GetTransform()
	if propType == "position" then
		transform:SetOrigin(value)
	elseif propType == "rotation" then
		transform:SetRotation(value)
	elseif propType == "scale" then
		transform:SetScale(value)
	end
	actorData:SetTransform(transform)
	self:TagRenderSceneAsDirty()

	self:GetAnimationManager():SetAnimationDirty(actorData)
	actor:GetEntity():SetMemberValue(targetPath, value)
	self:GetActorEditor():UpdateActorProperty(actorData, targetPath)
end
function Element:SetActorBoneTransformProperty(actor, propType, value, udmType) -- TODO: Obsolete?
	self:SetActorGenericProperty(actor, "ec/animated/bone/" .. propType, value, udmType)
end
