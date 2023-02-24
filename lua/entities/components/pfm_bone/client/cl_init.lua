--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMBone",BaseEntityComponent)

Component:RegisterMember("BoneId",udm.TYPE_INT32,-1)
Component:RegisterMember("Selected",udm.TYPE_BOOLEAN,false,{
	onChange = function(self)
		self:UpdateSelection()
	end
},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))
Component:RegisterMember("Persistent",udm.TYPE_BOOLEAN,false,{
	onChange = function(self)
		self:UpdateSelection()
	end
},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnEntitySpawn()
	self:UpdateSelection()
end

function Component:UpdateSelection()
	local selected = self:IsSelected()
	if(selected) then
		if(self.m_unselectedColor == nil) then
			self.m_unselectedColor = self:GetEntity():GetColor()
		end
		self:GetEntity():SetColor(self:IsPersistent() and Color.Lime or Color.White)

		local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
		if(renderC ~= nil) then renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_WORLD) end
	else
		if(self.m_unselectedColor ~= nil) then
			self:GetEntity():SetColor(self.m_unselectedColor)
			self.m_unselectedColor = nil
		end

		local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
		if(renderC ~= nil) then renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE) end
	end
end
ents.COMPONENT_PFM_BONE = ents.register_component("pfm_bone",Component)
