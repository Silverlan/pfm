--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/modelexplorer.lua")
include("/gui/draganddrop.lua")

util.register_class("gui.PFMModelCatalog",gui.Base)

function gui.PFMModelCatalog:__init()
	gui.Base.__init(self)
end
function gui.PFMModelCatalog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	local scrollContainer = gui.create("WIScrollContainer",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)

	local explorer = gui.create("WIModelExplorer",scrollContainer,0,0,self:GetWidth(),self:GetHeight())
	explorer:SetRootPath("models")
	explorer:SetExtensions({"wmd"})
	explorer:AddCallback("OnIconAdded",function(explorer,icon)
		if(icon:IsDirectory() == false) then
			gui.enable_drag_and_drop(icon,"ModelCatalog",function(elGhost)
				elGhost:SetAlpha(128)
				elGhost:AddCallback("OnDragTargetHoverStart",function(elGhost)
					elGhost:SetAlpha(0)
					elGhost:SetAlwaysUpdate(true)

					if(util.is_valid(entGhost)) then entGhost:Remove() end
					local path = util.Path(icon:GetAsset())
					path:PopFront()
					entGhost = ents.create("pfm_ghost")
					entGhost:Spawn()
					entGhost:SetModel(path:GetString())
				end)
				elGhost:AddCallback("OnDragTargetHoverStop",function(elGhost)
					elGhost:SetAlpha(128)
					elGhost:SetAlwaysUpdate(false)
					if(util.is_valid(entGhost)) then entGhost:Remove() end
				end)
			end)
			icon:AddCallback("OnDragDropped",function(elIcon,elDrop)
				if(util.is_valid(entGhost) == false) then return end
				local filmmaker = tool.get_filmmaker()
				local actor = filmmaker:CreateNewActor()
				if(actor == nil) then return end
				local mdlC = filmmaker:CreateNewActorComponent(actor,"PFMModel")
				if(mdlC == nil) then return end
				local path = util.Path(elIcon:GetAsset())
				path:PopFront()
				mdlC:SetModelName(path:GetString())
				local t = actor:GetTransform()
				t:SetPosition(entGhost:GetPos())
				t:SetRotation(entGhost:GetRotation())
				filmmaker:RefreshGameView() -- TODO: No need to reload the entire game view

				local entActor = actor:FindEntity()
				if(util.is_valid(entActor)) then
					local tc = entActor:AddComponent("util_transform")
					if(tc ~= nil) then
						tc:SetTranslationEnabled(false)
						tc:SetRotationAxisEnabled(math.AXIS_X,false)
						tc:SetRotationAxisEnabled(math.AXIS_Z,false)
						local trUtil = tc:GetTransformUtility(ents.UtilTransformArrowComponent.TYPE_ROTATION,math.AXIS_Y)
						local arrowC = util.is_valid(trUtil) and trUtil:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) or nil
						if(arrowC ~= nil) then
							arrowC:StartTransform()
							local cb
							cb = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
								if(mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
									if(util.is_valid(entActor)) then
										entActor:RemoveComponent("util_transform")
										t:SetPosition(entActor:GetPos())
										t:SetRotation(entActor:GetRotation())
									end
									cb:Remove()
									return util.EVENT_REPLY_HANDLED
								end
							end)
						end
					end
				end
			end)
		end
	end)
	explorer:Update()
	self.m_explorer = explorer
end
gui.register("WIPFMModelCatalog",gui.PFMModelCatalog)
