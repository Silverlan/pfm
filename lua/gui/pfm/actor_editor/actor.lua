--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMActorEditor:AddSkyActor()
	self:CreateNewActorWithComponents("sky", { "pfm_actor", "pfm_sky" })
end
function gui.PFMActorEditor:CreateNewPropActor(mdlName, origin, rotation, actorName)
	local pose
	if origin ~= nil or rotation ~= nil then
		pose = math.Transform()
		if origin ~= nil then
			pose:SetOrigin(origin)
		end
		if rotation ~= nil then
			pose:SetRotation(rotation)
		end
	end
	local actor = self:CreateNewActor(actorName, pose)
	if actor == nil then
		return
	end
	local mdlC = self:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
		actor:ChangeModel(mdlName)
	end)
	self:CreateNewActorComponent(actor, "model", false)
	self:CreateNewActorComponent(actor, "render", false)
	-- self:CreateNewActorComponent(actor,"transform",false)

	self:UpdateActorComponents(actor)
	return actor
end
function gui.PFMActorEditor:CreateNewActorWithComponents(name, components)
	local actor = self:CreateNewActor(name)
	if actor == nil then
		return
	end
	for i, componentName in ipairs(components) do
		if type(componentName) == "table" then
			self:CreateNewActorComponent(actor, componentName[1], i == #components, componentName[2])
		else
			self:CreateNewActorComponent(actor, componentName, i == #components)
		end
	end
	self:UpdateActorComponents(actor)
	return actor
end
function gui.PFMActorEditor:CreateNewActor(actorName, pose, uniqueId, group, dontRefreshAnimation)
	local filmClip = self:GetFilmClip()
	if filmClip == nil then
		pfm.create_popup_message(locale.get_text("pfm_popup_create_actor_no_film_clip"))
		return
	end

	group = group or self:GetSelectedGroup()
	local actor = pfm.get_project_manager():AddActor(self:GetFilmClip(), group, dontRefreshAnimation)
	if uniqueId ~= nil then
		actor:ChangeUniqueId(uniqueId)
	end
	local actorIndex
	if actorName == nil then
		actorName = "actor"
		actorIndex = 1
	end
	while filmClip:FindActor(actorName .. (actorIndex or "")) ~= nil do
		actorIndex = (actorIndex or 1) + 1
	end
	actorName = actorName .. (actorIndex or "")
	actor:SetName(actorName)

	local pos, rot
	local scale
	if pose ~= nil then
		pos = pose:GetOrigin()
		rot = pose:GetRotation()
		if util.get_type_name(pose) == "ScaledTransform" then
			scale = pose:GetScale()
			if scale == Vector(1, 1, 1) then
				scale = nil
			end
		end
	else
		pos = Vector()
		rot = Quaternion()
		local cam = tool.get_filmmaker():GetActiveCamera()
		if util.is_valid(cam) then
			local entCam = cam:GetEntity()
			pos = entCam:GetPos() + entCam:GetForward() * 50.0
			rot = EulerAngles(0, entCam:GetAngles().y, 0):ToQuaternion()
		end
	end

	local itemGroup
	if group ~= nil then
		itemGroup = self.m_tree:GetRoot():GetItemByIdentifier(tostring(group:GetUniqueId()), true)
	end
	self:AddActor(actor, itemGroup)

	local pfmActorC = self:CreateNewActorComponent(actor, "pfm_actor", false)
	pfmActorC:SetMemberValue("position", udm.TYPE_VECTOR3, pos)
	pfmActorC:SetMemberValue("rotation", udm.TYPE_QUATERNION, rot)
	if scale ~= nil then
		pfmActorC:SetMemberValue("scale", udm.TYPE_VECTOR3, scale)
	end
	self.m_constraintItemsDirty = true
	self:SetThinkingEnabled(true)
	return actor
end
function gui.PFMActorEditor:CreateNewActorComponent(actor, componentType, updateActorAndUi, initComponent)
	self.m_skipComponentCallbacks = true
	local component = actor:AddComponentType(componentType)
	self.m_skipComponentCallbacks = nil
	if initComponent ~= nil then
		initComponent(component)
	end
	return self:InitializeNewComponent(actor, component, componentType, updateActorAndUi)
end
function gui.PFMActorEditor:UpdateActorComponents(actor)
	tool.get_filmmaker():UpdateActor(actor, self:GetFilmClip(), true)

	local itemActor
	for elTree, data in pairs(self.m_treeElementToActorData) do
		if util.is_same_object(actor, data.actor) then
			itemActor = elTree
			break
		end
	end

	if itemActor == nil then
		return
	end

	local actorData = self.m_treeElementToActorData[itemActor]
	self:UpdateActorComponentEntries(actorData)
end
function gui.PFMActorEditor:IterateActors(f)
	for item, actorData in pairs(self.m_treeElementToActorData) do
		if item:IsValid() then
			f(item)
		end
	end
end
function gui.PFMActorEditor:RemoveConstraint(actor)
	local filmClip = self:GetFilmClip()

	local cmd = pfm.create_command("composition")

	local childOfC = actor:FindComponent("constraint_child_of")
	local addSubCmd
	if childOfC ~= nil then
		-- If the constraint is a child-of constraint, we have to convert the driven object's pose from local space
		-- (relative to the driver) back to world space
		local function get_property_pose_values()
			local constraintC = actor:FindComponent("constraint")
			if constraintC == nil then
				return
			end
			local drivenObject = ents.parse_uri(constraintC:GetMemberValue("drivenObject", udm.TYPE_STRING))
			local driver = ents.parse_uri(constraintC:GetMemberValue("driver", udm.TYPE_STRING))
			if drivenObject == nil or driver == nil then
				return
			end
			local actor0 = pfm.dereference(drivenObject:GetUuid())
			local propertyPath0 = "ec/" .. drivenObject:GetComponentName() .. "/" .. drivenObject:GetMemberName()
			local actor1 = pfm.dereference(driver:GetUuid())
			local propertyPath1 = "ec/" .. driver:GetComponentName() .. "/" .. driver:GetMemberName()
			if actor0 == nil or actor1 == nil then
				return
			end

			local parentPose, childPose =
				pfm.util.get_constraint_participant_poses(actor0, propertyPath0, actor1, propertyPath1)
			if parentPose == nil then
				return
			end
			local absPose = parentPose * childPose

			local memberInfo = pfm.get_member_info(propertyPath0, actor0:FindEntity())
			if memberInfo == nil then
				return
			end
			local oldValue
			local newValue
			if memberInfo.type == udm.TYPE_VECTOR3 then
				oldValue = childPose:GetOrigin()
				newValue = absPose:GetOrigin()
			elseif memberInfo.type == udm.TYPE_QUATERNION then
				oldValue = childPose:GetRotation()
				newValue = absPose:GetRotation()
			else
				oldValue = childPose
				newValue = absPose
			end

			-- We need to move the animation channels from parent space back to world space
			local ent0 = actor0:FindEntity()
			local memberInfo0 = util.is_valid(ent0) and pfm.get_member_info(propertyPath0, ent0) or nil
			if memberInfo0 ~= nil then
				local posMemberInfo, posPropertyPath, rotMemberInfo, rotPropertyPath =
					pfm.util.get_transform_property_components(ent0, memberInfo0, propertyPath0)
				if posMemberInfo ~= nil then
					cmd:AddSubCommand(
						"transform_animation_channel",
						tostring(actor0:GetUniqueId()),
						posPropertyPath,
						parentPose
					)
				end
				if rotMemberInfo ~= nil then
					cmd:AddSubCommand(
						"transform_animation_channel",
						tostring(actor0:GetUniqueId()),
						rotPropertyPath,
						parentPose
					)
				end
			end
			return actor0, propertyPath0, memberInfo.type, oldValue, newValue
		end
		local actor, propertyPath, propertyType, oldValue, newValue = get_property_pose_values()
		if actor ~= nil then
			local pm = pfm.get_project_manager()
			if util.is_valid(pm) then
				addSubCmd = function()
					pm:ChangeActorPropertyValue(actor, propertyPath, propertyType, oldValue, newValue, nil, true, cmd)
				end
			end
		end
	end
	-- We need to reset the actor position after the constraint has been deleted, but
	-- if the delete action is undone, the position has to be reset after the constraint
	-- has been restored. To do so, we'll just add two sub-commands for resetting the position, one
	-- after and one before. This is a bit hacky, but it works.
	if addSubCmd ~= nil then
		addSubCmd()
	end
	local res, subCmd = cmd:AddSubCommand("delete_actors", filmClip, { tostring(actor:GetUniqueId()) })
	if addSubCmd ~= nil then
		addSubCmd()
	end
	pfm.undoredo.push("delete_constraint", cmd)()
end
function gui.PFMActorEditor:RemoveActors(ids)
	local filmClip = self:GetFilmClip()
	pfm.undoredo.push("delete_actors", pfm.create_command("delete_actors", filmClip, ids))()
end
function gui.PFMActorEditor:OnActorsRemoved(filmClip, uuids)
	local items = {}
	for _, uniqueId in ipairs(uuids) do
		local item = self:GetActorEntry(uniqueId)
		if util.is_valid(item) then
			table.insert(items, item:GetParentItem())
		end

		self:ClearActor(uniqueId, false)
	end

	for _, item in ipairs(items) do
		item:UpdateUi()
	end
	self:SetConstraintPropertyIconsDirty()
end
function gui.PFMActorEditor:ClearActor(uniqueId, updateUi)
	if updateUi == nil then
		updateUi = true
	end

	local itemActor, parent = self.m_tree:GetRoot():GetItemByIdentifier(uniqueId, true)
	if itemActor ~= nil then
		parent:RemoveItem(itemActor, updateUi)
	end

	local ent = ents.find_by_uuid(uniqueId)
	if ent ~= nil then
		local pm = pfm.get_project_manager()
		local vp = util.is_valid(pm) and pm:GetViewport() or nil
		local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
		if rt ~= nil then
			rt:MarkActorAsDirty(ent, true)
			rt:FlushDirtyActorChanges()
		end

		util.remove(ent)
	end
	self:TagRenderSceneAsDirty()
end
function gui.PFMActorEditor:AddActor(actor, parentItem)
	parentItem = parentItem or self.m_tree
	local itemActor = parentItem:AddItem(actor:GetName(), nil, nil, tostring(actor:GetUniqueId()))
	itemActor:SetAutoSelectChildren(false)

	local nameChangeListener = actor:AddChangeListener("name", function(c, newName)
		if itemActor:IsValid() then
			itemActor:SetText(newName)
		end
	end)

	local onMovedListener = actor:AddChangeListener("OnMoved", function(actor, oldGroup, newGroup)
		local elActor = self:GetActorItem(actor)
		local itemGroupTarget = self.m_tree:GetRoot():GetItemByIdentifier(tostring(newGroup:GetUniqueId()), true)
		if util.is_valid(elActor) == false or util.is_valid(itemGroupTarget) == false then
			return
		end

		itemGroupTarget:AttachItem(elActor)
	end)

	itemActor:AddCallback("OnRemove", function()
		util.remove({ nameChangeListener, onMovedListener })
	end)

	local uniqueId = tostring(actor:GetUniqueId())
	itemActor:AddCallback("OnSelectionChanged", function(el, selected)
		local entActor = actor:FindEntity()
		if util.is_valid(entActor) then
			local pfmActorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if pfmActorC ~= nil then
				pfmActorC:SetSelected(selected)
			end
		end
	end)
	itemActor:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())

			pfm.populate_actor_context_menu(pContext, actor, true)
			pContext:AddItem(locale.get_text("rename"), function()
				local te =
					gui.create("WITextEntry", itemActor, 0, 0, itemActor:GetWidth(), itemActor:GetHeight(), 0, 0, 1, 1)
				te:SetText(actor:GetName())
				te:RequestFocus()
				te:AddCallback("OnFocusKilled", function()
					pfm.undoredo.push(
						"rename_actor",
						pfm.create_command("rename_actor", actor, actor:GetName(), te:GetText())
					)()

					te:RemoveSafely()
				end)
			end)
			pContext:AddItem(locale.get_text("remove"), function()
				local parent = itemActor:GetParentItem()
				self:RemoveActors({ uniqueId })
				if util.is_valid(parent) then
					parent:FullUpdate()
				end
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		if button == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				self:StartConstraintDragAndDropMode(itemActor, actor)
			else
				self:EndConstraintDragAndDropMode()
			end
			return util.EVENT_REPLY_UNHANDLED
		end
	end)

	local itemComponents = itemActor -- itemActor:AddItem(locale.get_text("components"))
	self.m_treeElementToActorData[itemActor] = {
		actor = actor,
		itemActor = itemActor,
		componentsEntry = itemComponents,
		componentData = {},
		treeElementToComponentId = {},
	}
	self.m_actorUniqueIdToTreeElement[tostring(actor:GetUniqueId())] = itemActor
	self:UpdateActorComponentEntries(self.m_treeElementToActorData[itemActor])

	if parentItem:GetClass() == "wipfmtreeviewelement" then
		parentItem:FullUpdate()
		parentItem:Expand()
	end

	self.m_constraintItemsDirty = true
	self:SetThinkingEnabled(true)
	return itemActor
end

function gui.PFMActorEditor:MoveActorToCollection(actor, col)
	self:Log("Moving actor '" .. tostring(actor) .. "' to collection '" .. tostring(col) .. "'...")

	local srcGroup = actor:GetParent()
	return pfm.undoredo.push(
		"move_actor_to_collection",
		pfm.create_command("move_actor_to_collection", actor, srcGroup, col)
	)()
end
