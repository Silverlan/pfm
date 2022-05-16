--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.EntityComponent:SetMemberValue(memberName,type,value)
	local path = util.Path.CreateFilePath(memberName)
	local props = self:GetProperties()
	if(path:GetComponentCount() > 1) then
		memberName = path:GetBack()
		path:PopBack()
		props = props:GetFromPath(path:GetString():sub(0,-2))
	end
	props:SetValue(memberName,type,value)
	self:CallChangeListeners(memberName,value)
end

function pfm.udm.EntityComponent:GetMemberValue(memberName)
	local val = self:GetProperties():GetFromPath(memberName):GetValue()
	if(val ~= nil) then return val end
	-- TODO: Copy this value if it is a non-trivial type (e.g. vec3, mat4, etc.)
	return self.m_defaultMemberValues[memberName]
end

function pfm.udm.EntityComponent:OnTypeChanged()
	self.m_defaultMemberValues = {}
	local type = self:GetType()
	local id = ents.get_component_id(type)
	if(id ~= nil) then
		local componentInfo = ents.get_component_info(id)
		if(componentInfo ~= nil) then
			local numMembers = componentInfo:GetMemberCount()
			for i=1,numMembers do
				local memberInfo = componentInfo:GetMemberInfo(i -1)
				assert(memberInfo ~= nil)
				self.m_defaultMemberValues[memberInfo.name] = memberInfo.default
			end
		end
	end

	self:GetParent():OnComponentTypeChanged(self,type)
end

function pfm.udm.EntityComponent:OnInitialize()
	udm.BaseSchemaType.OnInitialize(self)
	self.m_defaultMemberValues = {}
	self:AddChangeListener("type",function(c,type)
		self:OnTypeChanged()
	end)
	if(#self:GetType() > 0) then self:OnTypeChanged() end
end

function pfm.udm.EntityComponent:GetActor() return self:GetParent() end
