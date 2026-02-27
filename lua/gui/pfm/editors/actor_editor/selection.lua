-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function gui.PFMActorEditor:GetSelectedGroup()
	return self.m_lastSelectedGroup
end
function gui.PFMActorEditor:GetSelectedActors()
	local actors = {}
	self:IterateActors(function(el)
		if el:IsSelected() then
			local actorData = self.m_treeElementToActorData[el]
			if actorData ~= nil then
				table.insert(actors, actorData.actor)
			end
		end
	end)
	return actors
end
function gui.PFMActorEditor:GetSelectedPoseProperties()
	local props = self:GetSelectedProperties()
	local poseProps = {}
	for _, propData in ipairs(props) do
		if
			propData.controlData.type == udm.TYPE_VECTOR3
			or propData.controlData.type == udm.TYPE_QUATERNION
			or propData.controlData.type == udm.TYPE_EULER_ANGLES
			or propData.controlData.type == udm.TYPE_TRANSFORM
			or propData.controlData.type == udm.TYPE_SCALED_TRANSFORM
		then
			table.insert(poseProps, propData)
		end
	end
	return poseProps
end
function gui.PFMActorEditor:GetSelectedProperties()
	local props = {}
	local function add_property(actorElement, actorData, componentElement, componentData, elParent)
		for _, elProp in ipairs(elParent:GetItems()) do
			if elProp:IsValid() then
				local ctrlData = componentData.treeElementToControlData[elProp]
				if elProp:IsSelected() and ctrlData ~= nil then
					table.insert(props, {
						actorElement = el,
						componentElement = elComponent,
						propertyElement = elProp,

						actorData = actorData,
						componentData = componentData,
						controlData = ctrlData,
					})
				end
				add_property(actorElement, actorData, componentElement, componentData, elProp)
			end
		end
	end
	self:IterateActors(function(el)
		local actorData = self.m_treeElementToActorData[el]
		if actorData ~= nil then
			for _, elComponent in ipairs(actorData.componentsEntry:GetItems()) do
				if elComponent:IsValid() and actorData.treeElementToComponentId[elComponent] ~= nil then
					add_property(
						actorElement,
						actorData,
						componentElement,
						actorData.componentData[actorData.treeElementToComponentId[elComponent]],
						elComponent
					)
				end
			end
		end
	end)
	return props
end
function gui.PFMActorEditor:UpdateSelectedEntities()
	self.m_updateSelectedEntities = nil
	if util.is_valid(self.m_tree) == false then
		return
	end
	local selectionManager = tool.get_filmmaker():GetSelectionManager()
	local tSelected = {}
	self:IterateActors(function(el)
		if el:IsSelected() then
			local actorData = self.m_treeElementToActorData[el]
			if actorData ~= nil then
				local ent = actorData.actor:FindEntity()
				if ent ~= nil then
					table.insert(tSelected, ent)
				end
			end
		end
	end)
	selectionManager:SetSelectedObjects(tSelected)
end
function gui.PFMActorEditor:SelectActor(actor, deselectCurrent, property)
	if deselectCurrent == nil then
		deselectCurrent = true
	end
	if deselectCurrent and util.is_valid(self.m_tree) then
		self.m_tree:DeselectAll(nil, function(el)
			return self.m_treeElementToActorData[el] == nil
				or util.is_same_object(self.m_treeElementToActorData[el].actor, actor) == false
		end)
	end
	for itemActor, actorData in pairs(self.m_treeElementToActorData) do
		if util.is_same_object(actor, actorData.actor) then
			if itemActor:IsValid() then
				if itemActor:IsSelected() == false then
					itemActor:Select(false)
					itemActor:Expand()

					local parent = itemActor:GetParentItem()
					while util.is_valid(parent) do
						parent:Expand()
						parent = parent:GetParentItem()
					end
				end
				if property ~= nil then
					itemActor:Expand()
					actorData.componentsEntry:Expand()

					local componentName, memberName =
						ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(property))

					local itemComponent = (componentName ~= nil)
							and actorData.componentsEntry:GetItemByIdentifier(componentName)
						or nil
					if itemComponent ~= nil then
						itemComponent:Expand()

						local parent = itemComponent
						local child =
							parent:GetItemByIdentifier("ec/" .. componentName .. "/" .. memberName:GetString(), true)
						if child ~= nil then
							local p = child:GetParentItem()
							local parentItems = {}
							while p ~= nil do
								table.insert(parentItems, p)
								p = p:GetParentItem()
								if p == parent then
									break
								end
							end
							for i = #parentItems, 1, -1 do -- Need to expand parents in reverse order
								local p = parentItems[i]
								p:Expand()
								p:Select(false)
								p:Update()
							end
							child:Expand()
							child:Select(true)
							child:Update()

							-- Expanding elements in the tree is not immediate. If we want to scroll to a specific item, we
							-- have to delay it slightly to make sure the tree was updated.
							time.create_simple_timer(0.05, function()
								if self:IsValid() and self.m_treeScrollContainer:IsValid() and child:IsValid() then
									self.m_treeScrollContainer:ScrollToElementY(child)
								end
							end)
						end
					end
				end
			end
			break
		end
	end
end
function gui.PFMActorEditor:DeselectAllActors()
	self.m_tree:DeselectAll()
end
function gui.PFMActorEditor:IsActorSelected(actor)
	for el, _ in pairs(self.m_tree:GetSelectedElements()) do
		if el:IsValid() then
			local actorData = self.m_treeElementToActorData[el]
			if actorData ~= nil and util.is_same_object(actor, actorData.actor) then
				return true
			end
		end
	end
	return false
end
function gui.PFMActorEditor:DeselectActor(actor)
	local elTgt = self.m_actorUniqueIdToTreeElement[tostring(actor:GetUniqueId())]
	for el, _ in pairs(self.m_tree:GetSelectedElements()) do
		if el:IsValid() then
			local actorData = self.m_treeElementToActorData[el]
			if actorData ~= nil and util.is_same_object(actor, actorData.actor) then
				self.m_tree:DeselectAll(el)
				break
			end
		end
	end
	self:ScheduleUpdateSelectedEntities()
end
