--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("retarget_rig")

util.register_class("ents.RetargetMorph",BaseEntityComponent)
local Component = ents.RetargetMorph

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.FlexComponent.EVENT_ON_FLEX_CONTROLLERS_UPDATED,"ApplyFlexControllers")
end

function Component:SetRig(rig,flexC)
	self.m_rig = rig
	self.m_flexC = flexC
end

function Component:GetRig() return self.m_rig end

function Component:RigToActor(actor,mdlSrc,mdlDst)
	mdlDst = mdlDst or self:GetEntity():GetModel()
	mdlSrc = mdlSrc or actor:GetModel()
	local flexC = actor:GetComponent(ents.COMPONENT_FLEX)
	if(flexC == nil) then
		console.print_warning("Unable to apply retarget morph: Actor " .. tostring(actor) .. " has no flex component!")
		return
	end
	if(mdlSrc == nil or mdlDst == nil or flexC == nil) then return end
	local rig = ents.RetargetRig.Rig.load(mdlSrc,mdlDst)
	if(rig == nil) then
		console.print_warning("Unable to apply retarget morph: No rig found!")
		return
	end
	self:SetRig(rig,flexC)
end

function Component:ApplyFlexControllers()
	local flexCDst = self:GetEntity():GetComponent(ents.COMPONENT_FLEX)
	local flexCSrc = self.m_flexC
	if(util.is_valid(flexCSrc) == false or flexCDst == nil) then return end
	local rig = self:GetRig()
	local translationTable = rig:GetFlexControllerTranslationTable()
	local accTable = {}
	for flexCIdSrc,mappings in pairs(translationTable) do
		local val = flexCSrc:GetFlexController(flexCIdSrc)
		for flexCIdDst,data in pairs(mappings) do
			local srcVal = math.clamp(val,data.min_source,data.max_source)
			local f = srcVal /(data.max_source -data.min_source)
			local dstVal = data.min_target +f *(data.max_target -data.min_target)
			dstVal = dstVal +(accTable[flexCIdDst] or 0.0)
			flexCDst:SetFlexController(flexCIdDst,dstVal,0.0,false)
			accTable[flexCIdDst] = dstVal
		end
	end
end
ents.COMPONENT_RETARGET_MORPH = ents.register_component("retarget_morph",Component)
