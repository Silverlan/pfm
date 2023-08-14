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
	local pm = pfm.get_project_manager()
	local session = pm:GetSession()
	local schema = session:GetSchema()
	local function iterate_actors(parent)
		for _, el in ipairs(parent:GetItems()) do
			local elUdm = udm.dereference(schema, el:GetIdentifier())
			if util.get_type_name(elUdm) == "Group" then
				iterate_actors(el)
			else
				f(el)
			end
		end
	end
	iterate_actors(self.m_tree:GetRoot())
end
function gui.PFMActorEditor:RemoveActors(ids)
	local filmClip = self:GetFilmClip()
	pfm.undoredo.push("pfm_delete_actors", pfm.create_command("delete_actors", filmClip, ids))()
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
						"pfm_rename_actor",
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
			if state ~= input.STATE_PRESS then
				local elItem = gui.get_element_under_cursor(function(el)
					return el:GetClass() == "wipfmtreeviewelement"
				end)
				if elItem ~= nil then
					local groupUuid = elItem:GetIdentifier()
					local group = self:GetCollectionUdmObject(elItem)
					local curGroup = tostring(actor:GetParent():GetUniqueId())
					if
						group ~= nil
						and util.get_type_name(group) == "Group"
						and util.is_same_object(group, actor:GetParent()) == false
					then
						time.create_simple_timer(0.0, function()
							if self:IsValid() == false then
								return
							end
							local actors = self:GetSelectedActors()
							for _, actor in ipairs(actors) do
								if self:MoveActorToCollection(actor, group) == false then
									pfm.log(
										"Failed to move actor '"
											.. tostring(actor)
											.. "' to collection '"
											.. tostring(group)
											.. "'...",
										pfm.LOG_CATEGORY_PFM,
										pfm.LOG_SEVERITY_WARNING
									)
								end
							end
						end)
					end
				end
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
	return itemActor
end

function gui.PFMActorEditor:MoveActorToCollection(actor, col)
	pfm.log("Moving actor '" .. tostring(actor) .. "' to collection '" .. tostring(col) .. "'...", pfm.LOG_CATEGORY_PFM)

	local srcGroup = actor:GetParent()
	return pfm.undoredo.push(
		"pfm_move_actor_to_collection",
		pfm.create_command("move_actor_to_collection", actor, srcGroup, col)
	)()
end
