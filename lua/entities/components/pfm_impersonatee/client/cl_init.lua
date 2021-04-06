--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMImpersonatee",BaseEntityComponent)

function ents.PFMImpersonatee:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_listeners = {}
end
function ents.PFMImpersonatee:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
	self:GetEntity():RemoveComponent("impersonatee")
end
function ents.PFMImpersonatee:ChangeModel(mdlName)
	local ent = self:GetEntity()
	if(#mdlName == 0) then
		self:GetEntity():RemoveComponent("impersonatee")
		return
	end
	local impersonateeC = self:GetEntity():AddComponent("impersonatee")
	if(impersonateeC == nil) then return end
	impersonateeC:SetImpostorModel(mdlName)
	local actorC = ent:GetComponent("pfm_actor")
	if(actorC ~= nil) then
		actorC:SetDefaultRenderMode((#mdlName > 0) and ents.RenderComponent.RENDERMODE_NONE or ents.RenderComponent.RENDERMODE_WORLD)
		local impostorC = impersonateeC:GetImpostor()
		if(util.is_valid(impostorC)) then
			local renderC = impostorC:GetEntity():GetComponent(ents.COMPONENT_RENDER)
			if(renderC ~= nil) then renderC:SetExemptFromOcclusionCulling(true) end -- TODO: This shouldn't be necessary
		end
	end
end
function ents.PFMImpersonatee:Setup(actorData,cData)
	local ent = self:GetEntity()
	table.insert(self.m_listeners,cData:GetModelNameAttr():AddChangeListener(function(newModel)
		self:ChangeModel(newModel)
	end))
	self:ChangeModel(cData:GetModelName())
end
ents.COMPONENT_PFM_IMPERSONATEE = ents.register_component("pfm_impersonatee",ents.PFMImpersonatee)
