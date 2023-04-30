--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.IkRigEditor
function Element:ReloadBoneList(feModel)
	local pathMdl = feModel:GetValue()
	if(#pathMdl == 0) then return end
	local mdl = game.load_model(pathMdl)
	if(mdl == nil) then return end
	self.m_mdl = mdl
	self.m_ikRig = ents.IkSolverComponent.RigConfig()

	self:AddBoneList()
	if(util.is_valid(self.m_mdlView)) then
		self:LinkToModelView(self.m_mdlView)
		self:InitializeModelView()
	end
	self:UpdateMode()

	self.m_modelView:SetAlwaysRender(true)
	if(util.is_valid(self.m_mdlView)) then
		local ent = self.m_mdlView:GetEntity(1)
		if(util.is_valid(ent)) then
			ent:RemoveComponent("click")
			ent:RemoveComponent("bvh")
			ent:RemoveComponent("pfm_skeleton")

			ent:AddComponent("click")
			ent:AddComponent("bvh")
			ent:AddComponent("pfm_skeleton")
		end
	end
end
function Element:UpdateBoneVisibility()
	local enabled = toboolean(self.m_elShowBones:GetOptionValue(self.m_elShowBones:GetSelectedOption()))
	if(util.is_valid(self.m_mdlView) == false) then return end
	local tEnts = {}

	local ent = self.m_mdlView:GetEntity(1)
	if(util.is_valid(ent)) then table.insert(tEnts,ent) end

	for i,ent in ipairs(tEnts) do
		if(enabled) then
			local debugC = ent:AddComponent("debug_skeleton_draw")
			if(debugC ~= nil) then
				if(i == 1) then debugC:SetColor(Color.Orange)
				else debugC:SetColor(Color.Aqua) end
			end
		else ent:RemoveComponent("debug_skeleton_draw") end
	end
	self.m_mdlView:Render()
end
function Element:AddBoneList()
	local mdl = self.m_mdl
	if(mdl == nil) then return end

	util.remove(self.m_rigControls)
	self.m_rigControls = self.m_controls:AddSubMenu()
	self.m_boneControlMenu = self.m_rigControls:AddSubMenu()
	self:InitializeBoneControls(mdl)

	gui.create("WIBase",self.m_rigControls) -- Dummy
end
function Element:SetBoneColor(actorId,boneId,col)
	if(boneId == nil) then
		if(self.m_origBoneColor == nil or self.m_origBoneColor[actorId] == nil) then return end
		for boneId,_ in pairs(self.m_origBoneColor) do
			self:SetBoneColor(actorId,boneId,col)
		end
		return
	end

	local ent = util.is_valid(self.m_mdlView) and self.m_mdlView:GetEntity(actorId) or nil
	local debugC = util.is_valid(ent) and ent:AddComponent("debug_skeleton_draw") or nil
	if(debugC == nil) then return end
	local entBone = debugC:GetBoneEntity(boneId)
	if(util.is_valid(entBone) == false) then return end
	if(col == nil) then
		if(self.m_origBoneColor == nil or self.m_origBoneColor[actorId] == nil or self.m_origBoneColor[actorId][boneId] == nil) then return end
		col = self.m_origBoneColor[actorId][boneId]
		self.m_origBoneColor[actorId][boneId] = nil
	else
		self.m_origBoneColor = self.m_origBoneColor or {}
		self.m_origBoneColor[actorId] = self.m_origBoneColor[actorId] or {}
		self.m_origBoneColor[actorId][boneId] = self.m_origBoneColor[actorId][boneId] or entBone:GetColor()
	end
	entBone:SetColor(col)
	self.m_mdlView:Render()
end
function Element:UpdateBoneColor(name)
	local item = self.m_skelTree:GetRoot():GetItemByIdentifier(name,true)
	if(util.is_valid(item) == false) then return end
	local te = item:GetTextElement()
	if(self.m_ikRig:HasBone(name) == false) then
		te:SetColor(Color(100,100,100))
		return
	end
	local bone = self.m_ikRig:FindBone(name)
	if(bone.locked) then
		te:SetColor(Color.Red)
		return
	end
	te:SetColor(Color.White)
end
local function get_bones_in_hierarchical_order(mdl)
	local bones = {}
	local function add_bones(bone,depth)
		depth = depth or 0
		table.insert(bones,{bone,depth})
		for boneId,child in pairs(bone:GetChildren()) do
			add_bones(child,depth +1)
		end
	end
	for boneId,bone in pairs(mdl:GetSkeleton():GetRootBones()) do
		add_bones(bone)
	end
	return bones
end
function Element:InitializeBoneControls(mdl)
	local options = {}
	table.insert(options,{"none","-"})
	table.insert(options,{"hinge",locale.get_text("pfm_hinge_constraint")})
	table.insert(options,{"ballsocket",locale.get_text("pfm_ball_socket_constraint")})

	util.remove(self.m_skelTreeSubMenu)
	local subMenu = self.m_boneControlMenu:AddSubMenu()
	self.m_skelTreeSubMenu = subMenu
	local tree = gui.create("WIPFMTreeView",subMenu,0,0,subMenu:GetWidth(),20)
	self.m_skelTree = tree
	tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	local bones = get_bones_in_hierarchical_order(mdl)
	for _,boneInfo in ipairs(bones) do
		local boneDst = boneInfo[1]
		local depth = boneInfo[2]
		local name = string.rep("  ",depth) .. boneDst:GetName()

		local item = tree:AddItem(name)
		item:SetIdentifier(boneDst:GetName())
		item:AddCallback("OnSelectionChanged",function(pItem,selected)
			util.remove(self.m_cbOnAnimsUpdated)
			self:ReloadIkRig()
			self:CreateTransformGizmo()
			self:UpdateDebugVisualization()
		end)
		item:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext)) then
					pContext:SetPos(input.get_cursor_pos())
					pContext:AddItem(locale.get_text("pfm_add_fixed_constraint"),function()
						self:AddFixedConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem(locale.get_text("pfm_add_hinge_constraint"),function()
						self:AddHingeConstraint(item,boneDst:GetName())
					end)
					pContext:AddItem(locale.get_text("pfm_add_ball_socket_constraint"),function()
						self:AddBallSocketConstraint(item,boneDst:GetName())
					end)
					if(self.m_ikRig:HasBone(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_remove_bone"),function()
							self:RemoveBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem(locale.get_text("pfm_add_bone"),function()
							self:AddBone(boneDst:GetName())
							self:ReloadIkRig()
						end)
					end
					if(self.m_ikRig:IsBoneLocked(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_unlock_bone"),function()
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),false)
							self:ReloadIkRig()
							self:UpdateBoneColor(boneDst:GetName())
						end)
					else
						pContext:AddItem(locale.get_text("pfm_lock_bone"),function()
							self.m_ikRig:SetBoneLocked(boneDst:GetName(),true)
							self:ReloadIkRig()
							self:UpdateBoneColor(boneDst:GetName())
						end)
					end
					if(self.m_ikRig:HasControl(boneDst:GetName())) then
						pContext:AddItem(locale.get_text("pfm_remove_control"),function()
							self.m_ikRig:RemoveControl(boneDst:GetName())
							self:ReloadIkRig()
						end)
					else
						pContext:AddItem(locale.get_text("pfm_add_drag_control"),function()
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_DRAG)
							self:ReloadIkRig()
						end)
						pContext:AddItem(locale.get_text("pfm_add_state_control"),function()
							self.m_ikRig:AddControl(boneDst:GetName(),ents.IkSolverComponent.RigConfig.Control.TYPE_STATE)
							self:ReloadIkRig()
						end)
					end
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)
		self:UpdateBoneColor(boneDst:GetName())
	end
	self.m_boneControlMenu:ResetControls()
end
