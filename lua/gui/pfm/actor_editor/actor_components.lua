--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMActorEditor:GetComponentEntry(uuid, componentType)
	if type(componentType) ~= "number" then
		componentType = ents.find_component_id(componentType)
	end
	local actorData = self:GetActorData(uuid)
	if actorData == nil then
		return
	end
	local componentData = actorData.componentData[componentType]
	if componentData == nil then
		return
	end
	return actorData.componentData[componentType].itemComponent, componentData, actorData
end
function gui.PFMActorEditor:GetActorComponentItem(actor, componentName)
	local item = self:GetActorItem(actor)
	if item == nil then
		return
	end
	if self.m_treeElementToActorData == nil or self.m_treeElementToActorData[item] == nil then
		return
	end
	local item = self.m_treeElementToActorData[item].componentsEntry
	if util.is_valid(item) == false then
		return
	end
	return item:GetItemByIdentifier(componentName)
end
function gui.PFMActorEditor:UpdateActorComponentEntries(actorData)
	self:SetActorDirty(tostring(actorData.actor:GetUniqueId()))
	local entActor = actorData.actor:FindEntity()
	if entActor ~= nil then
		self:InitializeDirtyActorComponents(tostring(actorData.actor:GetUniqueId()), entActor)
	end
end

function gui.PFMActorEditor:OnActorComponentAdded(filmClip, actor, componentType)
	self:InitializeNewComponent(actor, actor:FindComponent(componentType), componentType)
end
function gui.PFMActorEditor:OnActorComponentRemoved(filmClip, actor, componentType)
	local uniqueId = tostring(actor:GetUniqueId())
	local itemComponent, componentData, actorData = self:GetComponentEntry(uniqueId, componentType)
	if util.is_valid(itemComponent) then
		local itemParent = itemComponent:GetParentItem()
		if util.is_valid(itemParent) then
			itemParent:RemoveItem(itemComponent)
			itemParent:FullUpdate()
		end
	end
	self:UpdateActorComponentEntries(actorData)
	local entActor = ents.find_by_uuid(uniqueId)
	if util.is_valid(entActor) then
		entActor:RemoveComponent(componentType)
		self:OnActorPropertyChanged(entActor)
	end
	self:TagRenderSceneAsDirty()
end
function gui.PFMActorEditor:InitializeNewComponent(actor, component, componentType, updateActorAndUi)
	if updateActorAndUi == nil then
		updateActorAndUi = true
	end
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

	local componentId = ents.find_component_id(componentType)
	if componentId == nil then
		include_component(componentType)
	end
	componentId = ents.find_component_id(componentType)
	if componentId == nil then
		pfm.log(
			"Attempted to add unknown entity component '" .. componentType .. "' to actor '" .. tostring(actor) .. "'!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	if updateActorAndUi == true then
		self:UpdateActorComponents(actor)
	end

	return component
end
function gui.PFMActorEditor:RemoveActorComponentEntry(uniqueId, componentId)
	if type(uniqueId) ~= "string" then
		uniqueId = tostring(uniqueId)
	end
	local itemActor = self.m_actorUniqueIdToTreeElement[uniqueId]
	if util.is_valid(itemActor) == false then
		return
	end
	local actorData = self.m_treeElementToActorData[itemActor]
	if actorData.componentData[componentId] == nil then
		return
	end
	for idx, els in pairs(actorData.componentData[componentId].items) do
		util.remove(els.control)
	end
	util.remove(actorData.componentData[componentId].callbacks)
	util.remove(actorData.componentData[componentId].actionItems)
	util.remove(actorData.componentData[componentId].itemComponent)
	actorData.componentData[componentId] = nil
end
function gui.PFMActorEditor:InitializeDirtyActorComponents(uniqueId, entActor)
	if type(uniqueId) ~= "string" then
		uniqueId = tostring(uniqueId)
	end
	if self.m_dirtyActorEntries == nil or self.m_dirtyActorEntries[uniqueId] == nil then
		return
	end
	entActor = entActor or ents.find_by_uuid(uniqueId)
	if util.is_valid(entActor) == false then
		return
	end
	self.m_dirtyActorEntries[uniqueId] = nil

	local itemActor = self.m_actorUniqueIdToTreeElement[uniqueId]
	if util.is_valid(itemActor) == false then
		return
	end
	local actorData = self.m_treeElementToActorData[itemActor]
	for _, component in ipairs(actorData.actor:GetComponents()) do
		local componentName = component:GetType()
		local componentId = ents.find_component_id(componentName)
		if componentId == nil then
			include_component(componentName)
			componentId = ents.find_component_id(componentName)
		end
		if componentId ~= nil then
			if
				actorData.componentData[componentId] == nil
				or util.is_valid(actorData.componentData[componentId].itemComponent) == false
			then
				self:AddActorComponent(entActor, actorData.itemActor, actorData, component)
			end
		else
			pfm.log("Unknown component " .. componentName, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		end
	end
	actorData.componentsEntry:Update()

	self.m_updatePropertyIcons = true
	self:EnableThinking()
end

local componentIcons = { -- TODO: Add a way for adding custom icons
	["camera"] = "gui/pfm/icon_camera_item",
	["particle_system"] = "gui/pfm/icon_particle_item",
	["light"] = "gui/pfm/icon_light_item",
	["light_spot"] = "gui/pfm/icon_light_item",
	["light_point"] = "gui/pfm/icon_light_item",
	["light_directional"] = "gui/pfm/icon_light",
	["model"] = "gui/pfm/icon_model_item",
}
function gui.PFMActorEditor:AddActorComponent(entActor, itemActor, actorData, component)
	local componentType = component:GetType()
	local componentId = ents.find_component_id(componentType)
	if componentId == nil then
		return
	end

	actorData.componentData[componentId] = actorData.componentData[componentId]
		or {
			items = {},
			actionItems = {},
			actionData = {},
			treeElementToControlData = {},
			callbacks = {},
		}
	if componentType == "constraint" or componentType == "animation_driver" then
		local cb = component:AddChangeListener("drivenObject", function()
			self.m_updatePropertyIcons = true
			self:EnableThinking()
		end)
		table.insert(actorData.componentData[componentId].callbacks, cb)
	end

	local displayName = componentType
	local locId = "c_" .. componentType
	local res, text = locale.get_text(locId, true)
	if res == true then
		displayName = text
	end

	local description
	local res, textDesc = locale.get_text(locId .. "_desc", true)
	if res == true then
		description = textDesc
	end

	local componentData = actorData.componentData[componentId]
	local itemComponent = actorData.componentsEntry:AddItem(displayName, nil, nil, componentType)
	if description ~= nil then
		itemComponent:SetTooltip(description)
	end
	if componentIcons[componentType] ~= nil then
		itemComponent:AddIcon(componentIcons[componentType])
		itemActor:AddUniqueIcon(componentIcons[componentType])
	end
	actorData.treeElementToComponentId[itemComponent] = componentId
	actorData.componentData[componentId].itemComponent = itemComponent
	local uniqueId = entActor:GetUuid()
	itemComponent:AddCallback("OnMouseEvent", function(tex, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())

			pContext:AddItem(locale.get_text("remove"), function()
				pfm.undoredo.push(
					"delete_component",
					pfm.create_command("delete_component", actorData.actor, componentType)
				)()
			end)
			if tool.get_filmmaker():IsDeveloperModeEnabled() then
				pContext:AddItem("Assign component to x", function()
					local entActor = ents.find_by_uuid(uniqueId)
					local c = (entActor ~= nil) and entActor:GetComponent(componentId) or nil
					if c == nil then
						return
					end
					x = c
				end)
				pContext:AddItem("Assign component to y", function()
					local entActor = ents.find_by_uuid(uniqueId)
					local c = (entActor ~= nil) and entActor:GetComponent(componentId) or nil
					if c == nil then
						return
					end
					y = c
				end)
			end
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end)
	itemComponent:AddCallback("OnSelectionChanged", function(el, selected)
		if selected then
			local actions = pfm.get_component_actions(componentType)
			if actions ~= nil then
				for _, action in ipairs(actions) do
					actorData.componentData[componentId].actionData[action.identifier] = {}
					local entActor = ents.find_by_uuid(uniqueId)
					if util.is_valid(entActor) then
						local el = action.initialize(
							self.m_animSetControls,
							actorData.actor,
							entActor,
							actorData.componentData[componentId].actionData[action.identifier]
						)
						if util.is_valid(el) then
							table.insert(actorData.componentData[componentId].actionItems, el)
						end
					end
				end
			end
		else
			util.remove(actorData.componentData[componentId].actionItems)
		end
	end)

	if util.is_valid(componentData.itemBaseProps) == false then
		componentData.itemBaseProps = itemComponent:AddItem(locale.get_text("pfm_base_properties"))
		componentData.itemBaseProps:SetName("base_properties")
		componentData.itemBaseProps:SetTooltip("pfm_base_properties_desc")
		componentData.itemBaseProps:SetIdentifier("base_properties")
	end
	local componentInfo = (componentId ~= nil) and ents.get_component_info(componentId) or nil
	if componentInfo ~= nil then
		local uniqueId = entActor:GetUuid()
		local c = entActor:GetComponent(componentId)
		local function initializeProperty(info, controlData)
			controlData.integer = udm.is_integral_type(info.type)
			if info:IsEnum() then
				controlData.enum = true
				controlData.enumValues = {}
				for _, v in ipairs(info:GetEnumValues()) do
					local name = info:ValueToEnumName(v)
					if name ~= "Count" then
						table.insert(controlData.enumValues, { v, name })
					end
				end
			end
			local val = component:GetMemberValue(info.name)
			if val ~= nil and info:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_CONTROLLER_BIT) == false then
				if info.type == ents.MEMBER_TYPE_ENTITY then
					val = ents.UniversalEntityReference(util.Uuid(val))
				elseif info.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
					val = ents.UniversalMemberReference(val)
				elseif info.type == ents.MEMBER_TYPE_ELEMENT then
					local udmVal = c:GetMemberValue(info.name)
					if udmVal == nil then
						return false
					end
					udmVal:Clear()
					udmVal:Merge(val, udm.MERGE_FLAG_BIT_DEEP_COPY)
					return true
				end
				c:SetMemberValue(info.name, val)
				return true
			end
			local valid = true
			if info.type == udm.TYPE_STRING then
			elseif info.type == udm.TYPE_UINT8 then
				controlData.integer = true
			elseif info.type == udm.TYPE_INT32 then
				controlData.integer = true
			elseif info.type == udm.TYPE_UINT32 then
				controlData.integer = true
			elseif info.type == udm.TYPE_UINT64 then
				controlData.integer = true
			elseif info.type == udm.TYPE_FLOAT then
			elseif info.type == udm.TYPE_BOOLEAN then
				controlData.boolean = true
			elseif info.type == udm.TYPE_VECTOR2 then
				valid = false
			elseif info.type == udm.TYPE_VECTOR3 then
				if info.specializationType ~= ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR then
					-- valid = false
				end
			elseif info.type == udm.TYPE_VECTOR4 then
				valid = false
			elseif info.type == udm.TYPE_QUATERNION then
				-- valid = false
			elseif info.type == udm.TYPE_EULER_ANGLES then
			--elseif(info.type == udm.TYPE_INT8) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_INT16) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_UINT16) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_INT64) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_DOUBLE) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_VECTOR2I) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_VECTOR3I) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_VECTOR4I) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_SRGBA) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_HDR_COLOR) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_TRANSFORM) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_SCALED_TRANSFORM) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_MAT4) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_MAT3X4) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_BLOB) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_BLOB_LZ4) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_ELEMENT) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_ARRAY) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_ARRAY_LZ4) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_REFERENCE) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_STRUCT) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_HALF) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_UTF8_STRING) then props:SetProperty(info.name,udm.(info.default))
			--elseif(info.type == udm.TYPE_NIL) then props:SetProperty(info.name,udm.(info.default))
			elseif info.type == ents.MEMBER_TYPE_ENTITY then
			elseif info.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
			elseif info.type == ents.MEMBER_TYPE_ELEMENT then
			else
				pfm.log(
					"Unsupported component member type " .. info.type .. "!",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_WARNING
				)
				valid = false
			end
			return valid
		end

		local function getMemberInfo(c, name)
			local idx = c:GetMemberIndex(name)
			if idx == nil then
				return
			end
			return c:GetMemberInfo(idx)
		end

		local function initializeMembers(memberIndices)
			for _, memberIdx in ipairs(memberIndices) do
				local memberInfo = c:GetMemberInfo(memberIdx)
				assert(memberInfo ~= nil)
				if memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_HIDE_IN_INTERFACE_BIT) == false then
					local controlData = {}
					local info = memberInfo
					local memberName = info.name
					local path = "ec/" .. componentInfo.name .. "/" .. info.name
					local valid = initializeProperty(info, controlData)
					if valid then
						controlData.name = info.name
						controlData.default = info.default
						controlData.path = path
						controlData.type = info.type
						controlData.componentId = componentId
						controlData.getValue = function()
							if util.is_valid(c) == false then
								if util.is_valid(entActor) == false then
									entActor = ents.find_by_uuid(uniqueId)
								end
								if util.is_valid(entActor) == false then
									console.print_warning("No actor with UUID '" .. uniqueId .. "' found!")
									return
								end
								c = entActor:GetComponent(componentId)
								if util.is_valid(c) == false then
									console.print_warning(
										"No component "
											.. componentId
											.. " found in actor with UUID '"
											.. uniqueId
											.. "'!"
									)
									return
								end
							end
							-- For displaying the value in the actor editor, we want the raw
							-- value, without any influences like math expressions.
							local panimaC = entActor:GetComponent(ents.COMPONENT_PANIMA)
							if panimaC ~= nil and ents.is_member_type_udm_type(controlData.type) then
								local manager = panimaC:GetAnimationManager("pfm")
								if manager ~= nil then
									local val = panimaC:GetRawPropertyValue(manager, path, controlData.type)
									if val ~= nil then
										return val
									end
								end
							end
							-- Property isn't animated? Just retrieve it's current value.
							return c:GetMemberValue(memberName)
						end
						controlData.getMemberInfo = function()
							if util.is_valid(c) == false then
								if util.is_valid(entActor) == false then
									entActor = ents.find_by_uuid(uniqueId)
								end
								if util.is_valid(entActor) == false then
									console.print_warning("No actor with UUID '" .. uniqueId .. "' found!")
									return
								end
								c = entActor:GetComponent(componentId)
								if util.is_valid(c) == false then
									console.print_warning(
										"No component "
											.. componentId
											.. " found in actor with UUID '"
											.. uniqueId
											.. "'!"
									)
									return
								end
							end
							local idx = c:GetMemberIndex(memberName)
							if idx == nil then
								return
							end
							return c:GetMemberInfo(idx)
						end
						local value = controlData.getValue()
						if udm.is_numeric_type(info.type) and info.type ~= udm.TYPE_BOOLEAN then
							local min = info.min or 0
							local max = info.max or 100
							min = math.min(min, controlData.default or min, value or min)
							max = math.max(max, controlData.default or max, value or max)
							if min == max then
								max = max + 100
							end
							controlData.min = min
							controlData.max = max
						end
						-- pfm.log("Adding control for member '" .. controlData.path .. "' with type = " .. memberInfo.type .. ", min = " .. (tostring(controlData.min) or "nil") .. ", max = " .. (tostring(controlData.max) or "nil") .. ", default = " .. (tostring(controlData.default) or "nil") .. ", value = " .. (tostring(value) or "nil") .. "...",pfm.LOG_CATEGORY_PFM)
						local memberType = memberInfo.type
						controlData.getActor = function()
							local entActor = ents.find_by_uuid(uniqueId)
							local c = (entActor ~= nil) and entActor:GetComponent(componentId) or nil
							local memberIdx = (c ~= nil) and c:GetMemberIndex(controlData.name) or nil
							local info = (memberIdx ~= nil) and c:GetMemberInfo(memberIdx) or nil
							if info == nil then
								return
							end
							return entActor, c, memberIdx, info
						end
						controlData.set = function(
							component,
							value,
							dontTranslateValue,
							updateAnimationValue,
							final,
							oldValue
						)
							if updateAnimationValue == nil then
								updateAnimationValue = true
							end
							local entActor, c, memberIdx, info = controlData.getActor()
							if info == nil then
								return
							end
							if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
								pfm.log(
									"Setting value for property '"
										.. controlData.path
										.. "' of component '"
										.. tostring(component)
										.. "' to value '"
										.. tostring(value)
										.. "'...",
									pfm.LOG_CATEGORY_PFM,
									pfm.LOG_SEVERITY_DEBUG
								)
							end
							if dontTranslateValue ~= true then
								value = controlData.translateFromInterface(value)
							end
							local memberValue = value
							if util.get_type_name(memberValue) == "Color" then
								memberValue = memberValue:ToVector()
							end

							local udmValue = memberValue
							local udmType = info.type
							if memberType == ents.MEMBER_TYPE_ENTITY then
								local uuid = udmValue:GetUuid()
								if uuid:IsValid() then
									udmValue = tostring(uuid)
								else
									udmValue = ""
								end
								udmType = udm.TYPE_STRING
							elseif memberType == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
								udmValue = udmValue:GetPath() or ""
								udmType = udm.TYPE_STRING
							end

							if final then
								oldValue = oldValue or component:GetMemberValue(memberName)
								if oldValue ~= nil then
									if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
										pfm.log(
											"Adding undo/redo for value change...",
											pfm.LOG_CATEGORY_PFM,
											pfm.LOG_SEVERITY_DEBUG
										)
									end
									pfm.undoredo.push("pfm_undoredo_property", function()
										local entActor = ents.find_by_uuid(uniqueId)
										if entActor == nil then
											return
										end
										tool.get_filmmaker():SetActorGenericProperty(
											entActor:GetComponent(ents.COMPONENT_PFM_ACTOR),
											controlData.path,
											memberValue,
											memberType
										)
									end, function()
										local entActor = ents.find_by_uuid(uniqueId)
										if entActor == nil then
											return
										end
										tool.get_filmmaker():SetActorGenericProperty(
											entActor:GetComponent(ents.COMPONENT_PFM_ACTOR),
											controlData.path,
											oldValue,
											memberType
										)
									end)
								else
									if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
										pfm.log(
											"Could not retrieve current value for property '"
												.. controlData.path
												.. "'. No undo/redo will be added.",
											pfm.LOG_CATEGORY_PFM,
											pfm.LOG_SEVERITY_DEBUG
										)
									end
								end
							end
							if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
								pfm.log(
									"Applying value " .. tostring(udmValue) .. " as type " .. udmType .. ".",
									pfm.LOG_CATEGORY_PFM,
									pfm.LOG_SEVERITY_DEBUG
								)
							end
							component:SetMemberValue(memberName, udmType, udmValue)
							if memberType ~= ents.MEMBER_TYPE_ELEMENT then
								local entActor = actorData.actor:FindEntity()
								if entActor ~= nil then
									local c = entActor:GetComponent(componentId)
									if c ~= nil then
										if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
											pfm.log(
												"Applying value "
													.. tostring(memberValue)
													.. " to entity component "
													.. tostring(c)
													.. ".",
												pfm.LOG_CATEGORY_PFM,
												pfm.LOG_SEVERITY_DEBUG
											)
										end

										local isAnimated = false
										local panimaC = entActor:GetComponent(ents.COMPONENT_PANIMA)
										if panimaC ~= nil then
											local manager = panimaC:GetAnimationManager("pfm")
											if manager ~= nil then
												isAnimated = panimaC:IsPropertyAnimated(manager, path)
											end
										end
										-- If the property is animated, the current value will already be updated
										-- through the animation the next time it is updated
										if not isAnimated then
											c:SetMemberValue(memberName, memberValue)
										end
										self:OnActorPropertyChanged(entActor)
									end
								end
								if updateAnimationValue then
									if log.is_log_level_enabled(log.SEVERITY_DEBUG) then
										pfm.log(
											"Updating animation value for property '"
												.. controlData.path
												.. "' with value "
												.. tostring(memberValue)
												.. ".",
											pfm.LOG_CATEGORY_PFM,
											pfm.LOG_SEVERITY_DEBUG
										)
									end

									self:ApplyComponentChannelValue(
										self,
										component,
										controlData,
										oldValue,
										memberValue,
										final
									)
								end
							else
								c:InvokeElementMemberChangeCallback(memberIdx)
							end
							self:TagRenderSceneAsDirty()
						end
						controlData.set(component, value, true, false)
						local ctrl, elChild = self:AddControl(
							entActor,
							c,
							actorData,
							componentData,
							component,
							itemComponent,
							controlData,
							path
						)
						if elChild ~= nil then
							actorData.componentData[componentId].treeElementToControlData[elChild] = controlData
						end
						controlData.treeElement = elChild
						actorData.componentData[componentId].items[controlData.path] = {
							control = ctrl,
							treeElement = elChild,
							controlData = controlData,
						}
						self:DoUpdatePropertyIcons(actorData, controlData)
					else
						pfm.log(
							"Unable to add control for member '" .. path .. "'!",
							pfm.LOG_CATEGORY_PFM,
							pfm.LOG_SEVERITY_WARNING
						)
					end
				end
			end
		end
		-- Static members have to be initialized first, because dynamic members may be dependent on static members
		local staticMemberIndices = {}
		if c ~= nil then
			for i = 0, c:GetStaticMemberCount() - 1 do
				table.insert(staticMemberIndices, i)
			end
		else
			pfm.log(
				"Missing component '"
					.. componentType
					.. "' ("
					.. componentId
					.. ")"
					.. " in actor '"
					.. tostring(entActor)
					.. "'!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_ERROR
			)
		end
		initializeMembers(staticMemberIndices)

		if c ~= nil then
			-- Initialize dynamic members next. Dynamic members must not have any dependencies to other dynamic members
			initializeMembers(c:GetDynamicMemberIndices())
		end
	end

	if util.is_valid(componentData.itemBaseProps) then
		componentData.itemBaseProps:SetVisible(componentData.itemBaseProps:GetItemCount() > 0)
	end
end
