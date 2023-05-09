--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
	selectionManager:ClearSelections()
	self:IterateActors(function(el)
		if el:IsSelected() then
			local actorData = self.m_treeElementToActorData[el]
			if actorData ~= nil then
				local ent = actorData.actor:FindEntity()
				if ent ~= nil then
					selectionManager:Select(ent)
				end
			end
		end
	end)
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
							while p ~= nil do
								p:Expand()
								p:Select(false)
								p = p:GetParentItem()
								if p == parent then
									break
								end
							end
							child:Expand()
							child:Select(true)

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
