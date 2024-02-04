--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMActorComponent", BaseEntityComponent)

-- include("channel.lua") -- TODO: This is obsolete; Remove the channels!

Component:RegisterMember("Position", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = function(self)
		self:UpdatePosition()
	end,
	typeMetaData = { ents.ComponentInfo.MemberInfo.PoseComponentTypeMetaData("pose") },
})
Component:RegisterMember("Rotation", udm.TYPE_QUATERNION, Quaternion(), {
	onChange = function(self)
		self:UpdateRotation()
	end,
	typeMetaData = { ents.ComponentInfo.MemberInfo.PoseComponentTypeMetaData("pose") },
})
Component:RegisterMember("Scale", udm.TYPE_VECTOR3, Vector(1, 1, 1), {
	onChange = function(self)
		self:UpdateScale()
	end,
	typeMetaData = { ents.ComponentInfo.MemberInfo.PoseComponentTypeMetaData("pose") },
})
Component:RegisterMember("Pose", udm.TYPE_SCALED_TRANSFORM, math.ScaledTransform(), {
	typeMetaData = { ents.ComponentInfo.MemberInfo.PoseTypeMetaData("position", "rotation", "scale") },
})
Component:RegisterMember("Visible", udm.TYPE_BOOLEAN, true, {
	onChange = function(self)
		self:UpdateVisibility()
	end,
}, bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))
Component:RegisterMember("Static", udm.TYPE_BOOLEAN, false, {
	onChange = function(self)
		self:UpdateStatic()
	end,
}, bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_NAME)
	self:AddEntityComponent("click")
	self:BindComponentInitEvent(ents.COMPONENT_RENDER, function(renderC)
		renderC:SetExemptFromOcclusionCulling(true)
	end)

	self.m_listeners = {}
	local genericC = self:GetEntity():GetGenericComponent()
	if genericC ~= nil then
		local cb = genericC:AddEventCallback(ents.BaseGenericComponent.EVENT_ON_MEMBERS_CHANGED, function(c)
			self:OnComponentMembersChanged(c)
		end)
		table.insert(self.m_listeners, cb)
	end

	self.m_boneChannels = {}
	self.m_flexControllerChannels = {}
	self.m_selected = false
end
function Component:IsInEditor()
	return self:GetEntity():HasComponent(ents.COMPONENT_PFM_EDITOR_ACTOR)
end
function Component:OnComponentMembersChanged(c)
	local pm = tool.get_filmmaker()
	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) then
		local actorData = self:GetActorData()
		if actorData ~= nil then
			actorEditor:SetActorComponentDirty(tostring(actorData:GetUniqueId()), c:GetComponentId())
		end
	end
end
function Component:IsSelected()
	return self.m_selected
end
function Component:SetSelected(selected)
	if selected == self.m_selected then
		return
	end
	self.m_selected = selected
	self:BroadcastEvent(Component.EVENT_ON_SELECTION_CHANGED, { selected })
end
function Component:SetProject(project)
	self.m_project = project
	self:UpdateStatic()
end
function Component:GetProject()
	return self.m_project
end
function Component:UpdateStatic()
	if util.is_valid(self.m_project) == false then
		return
	end
	local bvhCache = self.m_project:GetEntityComponent(ents.COMPONENT_STATIC_BVH_CACHE)
	if bvhCache == nil then
		return
	end
	if self:IsStatic() and self:IsBeingTransformed() == false then
		bvhCache:AddEntity(self:GetEntity())
	else
		bvhCache:RemoveEntity(self:GetEntity())
	end
end
function Component:UpdateVisibility()
	local visible = self:IsVisible() and self:GetActorData():IsAbsoluteVisible() or false
	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if renderC ~= nil then
		if visible == false then
			self.m_origSceneRenderPass = self.m_origSceneRenderPass or renderC:GetSceneRenderPass()
			renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE)
		elseif renderC:GetSceneRenderPass() == game.SCENE_RENDER_PASS_NONE or self.m_origSceneRenderPass ~= nil then
			renderC:SetSceneRenderPass(self.m_origSceneRenderPass or game.SCENE_RENDER_PASS_WORLD)
		end
	end

	self:BroadcastEvent(Component.EVENT_ON_VISIBILITY_CHANGED, { visible })
end
function Component:UpdatePosition()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	pose:TranslateLocal(self:GetPosition())
	self:GetEntity():SetPos(pose:GetOrigin())
end
function Component:UpdateRotation()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	pose:RotateLocal(self:GetRotation())
	self:GetEntity():SetRotation(pose:GetRotation())
end
function Component:UpdateScale()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	self:GetEntity():SetScale(pose:GetScale() * self:GetScale())
end
function Component:SetBoneChannel(boneId, attr, channel)
	if type(boneId) == "string" then
		local mdl = self:GetEntity():GetModel()
		if mdl == nil then
			return
		end
		boneId = mdl:LookupBone(boneId)
		if boneId == -1 then
			return
		end
	end
	self.m_boneChannels[boneId] = self.m_boneChannels[boneId] or {}
	self.m_boneChannels[boneId][attr] = channel
end
function Component:GetBoneChannel(boneId, attr)
	return self.m_boneChannels[boneId] and self.m_boneChannels[boneId][attr] or nil
end
function Component:SetFlexControllerChannel(flexControllerId, channel)
	self.m_flexControllerChannels[flexControllerId] = channel
end
function Component:GetFlexControllerChannel(flexControllerId)
	return self.m_flexControllerChannels[flexControllerId]
end

function Component:GetActorData()
	return self.m_actorData
end

function Component:OnRemove()
	util.remove(self.m_listeners)
end

function Component:ApplyPropertyValues()
	local actorData = self:GetActorData()
	if actorData ~= nil then
		local ent = self:GetEntity()
		ent:SetPose(actorData:GetAbsolutePose())

		self:InitializeComponentProperties()
	end
end

function Component:OnEntitySpawn() end

function Component:SetDefaultRenderMode(renderMode, useIfTurnedOff)
	self.m_defaultRenderMode = renderMode
	self.m_useDefaultRenderModeIfTurnedOff = useIfTurnedOff
end

function Component:GetDefaultRenderMode()
	return self.m_defaultRenderMode
end

function Component:ApplyComponentMemberValue(path)
	local componentName, componentPath = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	if componentName == nil then
		return
	end
	local actorData = self:GetActorData()
	local componentData = actorData:FindComponent(componentName)
	if componentData == nil then
		return
	end
	local val = componentData:GetMemberValue(componentPath:GetString())
	if val == nil then
		return
	end
	self:GetEntity():SetMemberValue(path, val)
end

function Component:InitializeComponentProperties()
	local actorData = self:GetActorData()
	pfm.log(
		"Initializing "
			.. #actorData:GetComponents()
			.. " components for actor '"
			.. self:GetEntity():GetName()
			.. "'...",
		pfm.LOG_CATEGORY_PFM_GAME
	)
	for _, value in ipairs(actorData:GetComponents()) do
		local componentData = value
		local componentName = componentData:GetType()
		local c
		if componentName ~= "pfm_actor" then
			c = self:AddEntityComponent(componentName)
			if c == nil then
				pfm.log(
					"Attempted to add unknown component '"
						.. componentName
						.. "' to actor '"
						.. self:GetEntity():GetName()
						.. "'!",
					pfm.LOG_CATEGORY_PFM_GAME,
					pfm.LOG_SEVERITY_WARNING
				)
			elseif c.Setup ~= nil then
				c:Setup(actorData, componentData)
			end
		else
			c = self
		end

		if c ~= nil then
			local isModelComponent = (componentName == "model")

			-- Initialize component member values
			local function applyProperties(el, path)
				if isModelComponent and path == nil then
					-- HACK: For the model component, the model has to be applied *before* other properties (like the skin or bodygroups).
					-- Since the UDM properties are unordered, we'll have to handle it as a special case.
					-- TODO: Find a better way to handle this (via schema properties?)
					local mdl = el:GetValue("model", udm.TYPE_STRING)
					if mdl ~= nil then
						self:GetEntity():SetModel(mdl)

						-- Since the entity hasn't been spawned yet, the above function will only preload the model
						-- but not actually initialize it. We need to initialize it immediately, which we can force by
						-- calling SetModel with the actual model object.
						mdl = game.load_model(mdl)
						if mdl ~= nil then
							self:GetEntity():SetModel(mdl)
						end
					end
				end
				path = path or ""
				for name, udmVal in pairs(el:GetChildren()) do
					if not isModelComponent or name ~= "model" then
						local childPath = path
						if #childPath > 0 then
							childPath = childPath .. "/"
						end
						childPath = childPath .. name
						local isElementProperty = false
						local idx = c:GetMemberIndex(name)
						local info = (idx ~= nil) and c:GetMemberInfo(idx) or nil
						if udmVal:GetType() == udm.TYPE_ELEMENT then
							if info ~= nil and info.type == ents.MEMBER_TYPE_ELEMENT then
								isElementProperty = true
							end
						end
						if udmVal:GetType() == udm.TYPE_ELEMENT then
							if isElementProperty then
								local udmEl = c:GetMemberValue(childPath)
								if udmEl == nil then
									pfm.log(
										"Failed to apply member value for unknown member '"
											.. childPath
											.. "' of component '"
											.. componentName
											.. "'!",
										pfm.LOG_CATEGORY_PFM_GAME,
										pfm.LOG_SEVERITY_WARNING
									)
								else
									udmEl:Clear()
									udmEl:Merge(udmVal, udm.MERGE_FLAG_BIT_DEEP_COPY)
								end
							else
								applyProperties(udmVal, childPath)
							end
						else
							local val = udmVal:GetValue()
							if val == nil then
								pfm.log(
									"Attempted to apply member value for unknown member '"
										.. childPath
										.. "' of component '"
										.. componentName
										.. "'! Ignoring...",
									pfm.LOG_CATEGORY_PFM_GAME,
									pfm.LOG_SEVERITY_WARNING
								)
							else
								if info ~= nil then
									if info.type == ents.MEMBER_TYPE_ENTITY then
										val = ents.UniversalEntityReference(util.Uuid(val))
									elseif info.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
										val = ents.UniversalMemberReference(val)
									end
								end
								if c:SetMemberValue(childPath, val) == false then
									pfm.log(
										"Failed to apply member value for unknown member '"
											.. childPath
											.. "' of component '"
											.. componentName
											.. "'!",
										pfm.LOG_CATEGORY_PFM_GAME,
										pfm.LOG_SEVERITY_WARNING
									)
								end
							end
						end
					end
				end
			end
			applyProperties(componentData:GetProperties())
		end
	end
	self:UpdateVisibility()
end

function Component:Setup(actorData)
	self.m_actorData = actorData
	self:GetEntity():SetName(actorData:GetName())
	self:GetEntity():SetUuid(actorData:GetUniqueId())
end

function Component:IsBeingTransformed()
	return self.m_transforming or false
end
function Component:OnStartTransform()
	self.m_transforming = true
	self:UpdateStatic()

	self:BroadcastEvent(Component.EVENT_ON_START_TRANSFORM)
end
function Component:OnEndTransform()
	self.m_transforming = false
	self:UpdateStatic()

	self:BroadcastEvent(Component.EVENT_ON_END_TRANSFORM)
end

ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor", Component)
Component.EVENT_ON_VISIBILITY_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR, "on_visibility_changed")
Component.EVENT_ON_SELECTION_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR, "on_selection_changed")
Component.EVENT_ON_START_TRANSFORM = ents.register_component_event(ents.COMPONENT_PFM_ACTOR, "on_start_transform")
Component.EVENT_ON_END_TRANSFORM = ents.register_component_event(ents.COMPONENT_PFM_ACTOR, "on_end_transform")
