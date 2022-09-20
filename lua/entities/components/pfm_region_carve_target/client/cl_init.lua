--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMRegionCarveTarget",BaseEntityComponent)
Component:RegisterMember("CarvedModel",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:ApplyModel()
	end,
	metaData = {
		rootPath = "models/",
		extensions = asset.get_supported_extensions(asset.TYPE_MODEL),
		stripExtension = true
	}
})
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:ApplyModel()
	local actorC = self:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actor = (actorC ~= nil) and actorC:GetActorData() or nil
	local origMdlName
	if(actor ~= nil) then origMdlName = actor:GetModel() end

	local ent = self:GetEntity()

	local bodygroups = {}
	local skin = ent:GetSkin()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC ~= nil) then bodygroups = mdlC:GetBodyGroups() end

	ent:ClearModel()
	local mdlName = self:GetCarvedModel()
	if(#mdlName == 0 and origMdlName ~= nil) then mdlName = origMdlName end
	ent:SetModel(mdlName)
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC ~= nil) then mdlC:SetModelName(origMdlName) end

	ent:SetSkin(skin)
	if(util.is_valid(mdlC)) then for k,v in pairs(bodygroups) do mdlC:SetBodyGroup(k,v) end end
end
ents.COMPONENT_PFM_REGION_CARVE_TARGET = ents.register_component("pfm_region_carve_target",Component)
