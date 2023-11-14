--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/element_selection.lua")

function gui.PFMActorEditor:StartConstraintDragAndDropMode(elItem, actor, propertyPath)
	propertyPath = propertyPath or "ec/pfm_actor/pose"
	self:EndConstraintDragAndDropMode()
	self.m_constraintDragAndDropItems = {}

	if propertyPath == nil then
		return
	end

	local ent = actor:FindEntity()
	local memberInfo = util.is_valid(ent) and pfm.get_member_info(propertyPath, ent) or nil
	if
		memberInfo == nil
		or (
			pfm.util.is_pose_property_type(memberInfo.type) == false
			and pfm.util.is_property_type_positional(memberInfo.type) == false
			and pfm.util.is_property_type_rotational(memberInfo.type) == false
		)
	then
		return
	end

	local elItemHeader = elItem:GetHeader()

	local p = gui.create("WIDragGhost")
	p:SetTargetElement(elItemHeader, elItemHeader:GetCursorPos(), "Constraint")
	table.insert(self.m_constraintDragAndDropItems, p)

	local callbacks = self.m_constraintDragAndDropItems
	local function initialize_drag()
		local elOutline = gui.create("WIElementSelectionOutline", self)
		table.insert(self.m_constraintDragAndDropItems, elOutline)
		elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MAJOR)
		elOutline:SetTargetElement({ elItemHeader })
		elOutline:Update()

		local tItems = {}
		local dropped = false
		table.insert(
			callbacks,
			p:AddEventListener("OnHoverElement", function(p, el)
				if tItems[el] ~= nil then
					return true
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragTargetHoverStart", function(p, el)
				local elOutline = tItems[el]
				elOutline = (elOutline ~= nil) and elOutline.outline or nil
				if util.is_valid(elOutline) then
					elOutline:SetFilledIn(Color(255, 255, 255, 60))
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragTargetHoverStop", function(p, el)
				if dropped then
					return
				end
				local elOutline = tItems[el]
				elOutline = (elOutline ~= nil) and elOutline.outline or nil
				if util.is_valid(elOutline) then
					elOutline:SetFilledIn(false)
				end
			end)
		)
		table.insert(
			callbacks,
			p:AddEventListener("OnDragDropped", function(p, el)
				local elData = tItems[el]
				if elData == nil then
					return
				end
				local pContext = gui.open_context_menu()
				if util.is_valid(pContext) == false then
					return
				end
				local droppedActorUuid = elData.actorUuid
				pContext:SetPos(input.get_cursor_pos())

				local constraintTypes = elData.constraintTypes

				-- Make sure the child-of constraint is the first in the list
				-- (Since it's the most commonly used one)
				for i, type in ipairs(constraintTypes) do
					if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
						table.remove(constraintTypes, i)
						table.insert(constraintTypes, 1, type)
						break
					end
				end

				for _, type in ipairs(constraintTypes) do
					local constraintName = gui.PFMActorEditor.constraint_type_to_name(type)
					local name = constraintName
					name = locale.get_text("c_constraint_" .. name)
					name = locale.get_text("pfm_add_constraint_type", { name })
					local tooltip = locale.get_text("pfm_create_" .. constraintName .. "_constraint_desc")

					if type == gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF then
						-- The child-of constraint can be either added to affect either the position or rotation, or both.
						-- To make it affect both, we'll add a separate option.
						local actor1 = (droppedActorUuid ~= nil) and pfm.dereference(droppedActorUuid) or nil
						local ent1 = (actor1 ~= nil) and actor1:FindEntity() or nil
						if util.is_valid(ent1) then
							local poseMetaInfo0, poseComponent0, posePropertyName0 =
								pfm.util.find_property_pose_meta_info(ent, propertyPath)
							local poseMetaInfo1, poseComponent1, posePropertyName1 =
								pfm.util.find_property_pose_meta_info(ent1, elData.propertyPath)
							if poseMetaInfo0 ~= nil and poseMetaInfo1 ~= nil then
								local posePropertyPath0 = "ec/" .. poseComponent0 .. "/" .. posePropertyName0
								local posePropertyPath1 = "ec/" .. poseComponent1 .. "/" .. posePropertyName1
								local item = pContext:AddItem(name, function()
									if self:IsValid() then
										local actor1 = (droppedActorUuid ~= nil) and pfm.dereference(droppedActorUuid)
											or nil
										if actor1 ~= nil then
											self:AddConstraint(
												type,
												actor,
												posePropertyPath0,
												actor1,
												posePropertyPath1
											)
										end
									end
								end)
								item:SetName("child_of")
								item:SetTooltip(tooltip)

								local memberInfo1 = pfm.get_member_info(elData.propertyPath, ent1)
								if memberInfo1 ~= nil then
									if
										not pfm.util.is_property_type_rotational(memberInfo1.type)
										and (
											pfm.util.is_property_type_positional(memberInfo.type)
											or pfm.util.is_pose_property_type(memberInfo.type)
										)
									then
										local propertyPath = "ec/" .. poseComponent0 .. "/" .. poseMetaInfo0.posProperty

										local item = pContext:AddItem(
											name
												.. " ("
												.. locale.get_text("pfm_create_child_of_constraint_type_positional")
												.. ")",
											function()
												if self:IsValid() then
													local actor1 = (droppedActorUuid ~= nil)
															and pfm.dereference(droppedActorUuid)
														or nil
													self:AddConstraint(
														type,
														actor,
														propertyPath,
														actor1,
														posePropertyPath1
													)
												end
											end
										)
										item:SetName("child_of_positional")
										item:SetTooltip(
											locale.get_text("pfm_create_child_of_constraint_type_positional_desc")
										)

										local translationalPropertyPath
										if pfm.util.is_pose_property_type(memberInfo1.type) then
											translationalPropertyPath = "ec/"
												.. poseComponent1
												.. "/"
												.. poseMetaInfo1.posProperty
										else
											translationalPropertyPath = elData.propertyPath
										end
										local memberInfo1 = pfm.get_member_info(translationalPropertyPath, ent1)
										if memberInfo1 ~= nil then
											if pfm.util.is_property_type_positional(memberInfo1.type) then
												local item = pContext:AddItem(
													name
														.. " ("
														.. locale.get_text(
															"pfm_create_child_of_constraint_type_translational"
														)
														.. ")",
													function()
														if self:IsValid() then
															local actor1 = (droppedActorUuid ~= nil)
																	and pfm.dereference(droppedActorUuid)
																or nil
															self:AddConstraint(
																type,
																actor,
																propertyPath,
																actor1,
																translationalPropertyPath
															)
														end
													end
												)
												item:SetName("child_of_translational")
												item:SetTooltip(
													locale.get_text(
														"pfm_create_child_of_constraint_type_translational_desc"
													)
												)
											end
										end
									end
									if
										not pfm.util.is_property_type_positional(memberInfo1.type)
										and (
											pfm.util.is_property_type_rotational(memberInfo.type)
											or pfm.util.is_pose_property_type(memberInfo.type)
										)
									then
										local propertyPath = "ec/" .. poseComponent0 .. "/" .. poseMetaInfo0.rotProperty
										local item = pContext:AddItem(
											name
												.. " ("
												.. locale.get_text("pfm_create_child_of_constraint_type_rotational")
												.. ")",
											function()
												if self:IsValid() then
													local actor1 = (droppedActorUuid ~= nil)
															and pfm.dereference(droppedActorUuid)
														or nil
													self:AddConstraint(
														type,
														actor,
														propertyPath,
														actor1,
														elData.propertyPath
													)
												end
											end
										)
										item:SetName("child_of_rotational")
										item:SetTooltip(
											locale.get_text("pfm_create_child_of_constraint_type_rotational_desc")
										)
									end
								end
							end
						end
					else
						local item = pContext:AddItem(name, function()
							if self:IsValid() then
								local actor1 = (droppedActorUuid ~= nil) and pfm.dereference(droppedActorUuid) or nil
								self:AddConstraint(type, actor, propertyPath, actor1, elData.propertyPath)
							end
						end)
						item:SetName(constraintName)
						item:SetTooltip(tooltip)
					end
				end
				pContext:Update()
				dropped = true
				for elHeader, elDataItem in pairs(tItems) do
					if elDataItem ~= elData then
						util.remove(elDataItem.outline)
					end
				end
				elData.outline:SetFilledIn(Color(255, 255, 255, 60))
				pContext:AddEventListener("OnRemove", function()
					if self:IsValid() then
						self:EndConstraintDragAndDropMode()
					end
				end)
				return util.EVENT_REPLY_HANDLED
			end)
		)
		table.insert(
			callbacks,
			elItemHeader:AddEventListener("OnDragStopped", function()
				if self:IsValid() then
					if dropped == false then
						self:EndConstraintDragAndDropMode()
					end
				end
			end)
		)

		local function add_target(uuid, propertyPath, header)
			local actor = pfm.dereference(uuid)
			if actor == nil then
				return
			end
			local t = pfm.util.find_applicable_constraint_types(memberInfo, actor, propertyPath)
			if #t > 0 then
				local elOutline = gui.create("WIElementSelectionOutline", self)
				table.insert(self.m_constraintDragAndDropItems, elOutline)
				elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MEDIUM)
				elOutline:SetTargetElement({ header })
				elOutline:Update()
				tItems[header] = {
					outline = elOutline,
					constraintTypes = t,
					actorUuid = uuid,
					propertyPath = propertyPath,
				}
			end
		end
		local uuid = tostring(actor:GetUniqueId())
		for _, item in ipairs(self:GetActorItems()) do
			if item:IsValid() and item:IsHidden() == false then
				local uuidItem = item:GetName()
				local actor = pfm.dereference(uuidItem)
				if actor ~= nil then
					if uuidItem ~= uuid then
						add_target(uuidItem, "ec/pfm_actor/pose", item:GetHeader())
					end
					local componentItems = self:GetActorComponentItems(actor)
					for _, cItem in ipairs(componentItems) do
						if cItem:IsValid() and cItem:IsHidden() == false then
							local componentType = cItem:GetName()
							local propertyItems = self:GetPropertyEntries(uuidItem, componentType)
							for _, propItem in ipairs(propertyItems) do
								if propItem:IsValid() and propItem:IsHidden() == false then
									local header = propItem:GetHeader()
									if util.is_valid(header) and propItem ~= elItem then
										local itemPropertyPath = propItem:GetIdentifier()
										add_target(uuidItem, itemPropertyPath, header)
									end
								end
							end
						end
					end
				end
			end
		end
	end
	table.insert(
		callbacks,
		p:AddEventListener("OnDragStarted", function()
			if self:IsValid() then
				initialize_drag()
			end
		end)
	)
end

function gui.PFMActorEditor:EndConstraintDragAndDropMode()
	util.remove(self.m_constraintDragAndDropItems or {})
	self.m_constraintDragAndDropItems = nil
end
