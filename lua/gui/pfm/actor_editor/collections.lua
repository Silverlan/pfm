--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

gui.PFMActorEditor.COLLECTION_SCENEBUILD = "scenebuild"
gui.PFMActorEditor.COLLECTION_ACTORS = "actors"
gui.PFMActorEditor.COLLECTION_CAMERAS = "cameras"
gui.PFMActorEditor.COLLECTION_EFFECTS = "effects"
gui.PFMActorEditor.COLLECTION_LIGHTS = "lighting"
gui.PFMActorEditor.COLLECTION_ENVIRONMENT = "environment"
gui.PFMActorEditor.COLLECTION_BAKING = "baking"
gui.PFMActorEditor.COLLECTION_MISC = "misc"
gui.PFMActorEditor.COLLECTION_VR = "vr"
gui.PFMActorEditor.COLLECTION_CONSTRAINTS = "constraints"

gui.PFMActorEditor.COLLECTION_TYPES = {
	gui.PFMActorEditor.COLLECTION_SCENEBUILD,
	gui.PFMActorEditor.COLLECTION_ACTORS,
	gui.PFMActorEditor.COLLECTION_CAMERAS,
	gui.PFMActorEditor.COLLECTION_EFFECTS,
	gui.PFMActorEditor.COLLECTION_LIGHTS,
	gui.PFMActorEditor.COLLECTION_ENVIRONMENT,
	gui.PFMActorEditor.COLLECTION_BAKING,
	gui.PFMActorEditor.COLLECTION_MISC,
	gui.PFMActorEditor.COLLECTION_VR,
	gui.PFMActorEditor.COLLECTION_CONSTRAINTS,
}

function gui.PFMActorEditor:AddCollectionItem(parentItem, parent, isRoot)
	local itemGroup = parentItem:AddItem(parent:GetName(), nil, nil, tostring(parent:GetUniqueId()))

	local nameChangeListener = parent:AddChangeListener("name", function(c, newName)
		if itemGroup:IsValid() then
			itemGroup:SetText(newName)
		end
	end)
	itemGroup:AddCallback("OnRemove", function()
		util.remove(nameChangeListener)
	end)

	itemGroup:SetName(parent:GetName())
	itemGroup:SetAutoSelectChildren(false)
	itemGroup:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT then
			if state == input.STATE_PRESS then
				local pContext = gui.open_context_menu()
				if util.is_valid(pContext) == false then
					return util.EVENT_REPLY_HANDLED
				end
				pContext:SetPos(input.get_cursor_pos())

				pContext:AddItem(locale.get_text("pfm_add_collection"), function()
					itemGroup:Expand()
					local child = itemGroup:AddItem("")
					local initialText = ""
					local te = gui.create("WITextEntry", child, 0, 0, child:GetWidth(), child:GetHeight(), 0, 0, 1, 1)
					te:SetText(initialText)
					te:RequestFocus()
					te:AddCallback("OnFocusKilled", function()
						local itemText = te:GetText()
						if child:IsValid() then
							child:RemoveSafely()
						end
						te:RemoveSafely()
						if itemGroup:IsValid() then
							itemGroup:Update()
						end

						if itemText ~= initialText then
							child = self:AddCollection(itemText, parent)
						end
					end)
				end)
				pContext:AddItem(locale.get_text("pfm_expand_all"), function()
					itemGroup:ExpandAll()
				end)
				pContext:AddItem(locale.get_text("pfm_collapse_all"), function()
					itemGroup:CollapseAll()
				end)
				if isRoot ~= true then
					pContext:AddItem(locale.get_text("pfm_remove_collection"), function()
						pfm.undoredo.push(
							"pfm_delete_collection",
							pfm.create_command("delete_collection", self:GetFilmClip(), parent)
						)()
					end)
					pContext:AddItem(locale.get_text("rename"), function()
						local te = gui.create(
							"WITextEntry",
							itemGroup,
							0,
							0,
							itemGroup:GetWidth(),
							itemGroup:GetHeight(),
							0,
							0,
							1,
							1
						)
						te:SetText(parent:GetName())
						te:RequestFocus()
						te:AddCallback("OnFocusKilled", function()
							pfm.undoredo.push(
								"pfm_rename_collection",
								pfm.create_command("rename_collection", parent, parent:GetName(), te:GetText())
							)()

							te:RemoveSafely()
						end)
					end)
				end
				if tool.get_filmmaker():IsDeveloperModeEnabled() then
					pContext:AddItem(locale.get_text("pfm_copy_id"), function()
						util.set_clipboard_string(tostring(parent:GetUniqueId()))
					end)
				end
				pContext:Update()
			end
			return util.EVENT_REPLY_HANDLED
		end

		if root ~= true then
			--[[if(button == input.MOUSE_BUTTON_LEFT) then
				if(state ~= input.STATE_PRESS) then
					print("Moving collections is not yet implemented!")
					local elItem = gui.get_element_under_cursor(function(el)
						return el:GetClass() == "wipfmtreeviewelement"
					end)
					if(elItem ~= nil) then
						local groupUuid = elItem:GetIdentifier()
						local group = self:GetCollectionUdmObject(elItem)
						local curGroup = tostring(actor:GetParent():GetUniqueId())
						if(group ~= nil and util.get_type_name(group) == "Group" and util.is_same_object(group,actor:GetParent()) == false) then
							time.create_simple_timer(0.0,function()
								if(self:IsValid() == false) then return end
								local actors = self:GetSelectedActors()
								local uniqueIds = {}
								for _,actor in ipairs(actors) do table.insert(uniqueIds,tostring(actor:GetUniqueId())) end

								self:CopyToClipboard(actors)
								self:RemoveActors(uniqueIds)

								local pm = pfm.get_project_manager()
								local session = pm:GetSession()
								self.m_lastSelectedGroup = udm.dereference(session:GetSchema(),groupUuid)
								self:PasteFromClipboard(true)
							end)
						end
					end
				end
			end
			return util.EVENT_REPLY_HANDLED]]
		end
	end)
	itemGroup:AddCallback("OnSelectionChanged", function(el, selected)
		if selected then
			self.m_lastSelectedGroup = self:GetCollectionUdmObject(itemGroup)
		end
	end)
	return itemGroup
end
function gui.PFMActorEditor:GetCollectionUdmObject(elCollection)
	local pm = pfm.get_project_manager()
	local session = pm:GetSession()
	local schema = session:GetSchema()
	return udm.dereference(schema, elCollection:GetIdentifier())
end
function gui.PFMActorEditor:GetCollectionTreeItem(uuid)
	return self.m_tree:GetRoot():GetItemByIdentifier(uuid, true)
end
function gui.PFMActorEditor:OnCollectionRemoved(groupUuid)
	local itemGroup = self:GetCollectionTreeItem(groupUuid)
	if util.is_valid(itemGroup) == false then
		return
	end
	local itemParent = itemGroup:GetParentItem()
	if util.is_valid(itemParent) == false then
		return
	end
	itemGroup:RemoveSafely()
	itemParent:FullUpdate()
end
function gui.PFMActorEditor:OnCollectionAdded(group)
	local parentGroup = group:GetParent()
	if parentGroup == nil then
		return
	end
	local parentItem = self:GetCollectionTreeItem(tostring(parentGroup:GetUniqueId()))
	if util.is_valid(parentItem) == false then
		return
	end
	local item = self:AddCollectionItem(parentItem, group)
	return group, item
end
function gui.PFMActorEditor:AddCollection(name, parentGroup)
	pfm.log("Adding collection '" .. name .. "'...", pfm.LOG_CATEGORY_PFM)

	if parentGroup == nil then
		local filmClip = self:GetFilmClip()
		parentGroup = filmClip:GetScene()
	end
	local childGroup =
		pfm.undoredo.push("pfm_add_collection", pfm.create_command("add_collection", parentGroup, name))()
	if childGroup == nil then
		return
	end
	return childGroup, self:GetCollectionTreeItem(tostring(childGroup:GetUniqueId()))
end
function gui.PFMActorEditor:FindCollection(name, createIfNotExists, parentGroup)
	local root
	if parentGroup ~= nil then
		root = self:GetCollectionTreeItem(tostring(parentGroup:GetUniqueId()))
	else
		root = self.m_tree:GetRoot():GetItems()[1]
	end
	if type(name) == "table" then
		local collections = name
		if #collections == 0 then
			return root
		end
		local item = root
		for _, colName in ipairs(collections) do
			local parentGroup = pfm.dereference(item:GetIdentifier())
			if parentGroup == nil then
				break
			end
			item = self:FindCollection(colName, createIfNotExists, parentGroup)
			if util.is_valid(item) == false then
				break
			end
		end
		return item or root
	end
	if util.is_valid(root) == false then
		return
	end
	for _, item in ipairs(root:GetItems()) do
		if item:IsValid() and item:GetName() == name then
			local elUdm = self:GetCollectionUdmObject(item)
			if elUdm ~= nil then
				return elUdm, item
			end
		end
	end
	if createIfNotExists == false then
		return
	end
	return self:AddCollection(name, parentGroup)
end
