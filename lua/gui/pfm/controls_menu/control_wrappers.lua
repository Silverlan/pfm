--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Wrapper = util.register_class("pfm.util.ControlWrapper")
function Wrapper:__init(elControls, identifier)
	self.m_elControls = elControls
	self.m_identifier = identifier
end
function Wrapper:SetLocalizedText(text)
	self.m_localizedText = text
end
function Wrapper:SetDefaultValue(val)
	self.m_defaultValue = val
end
function Wrapper:ToInterfaceValue(val)
	if self.m_translateToInterface ~= nil then
		val = self.m_translateToInterface(val)
	end
	return val
end
function Wrapper:FromInterfaceValue(val)
	if self.m_translateFromInterface ~= nil then
		val = self.m_translateFromInterface(val)
	end
	return val
end
function Wrapper:SetControlElementValue(val)
	self.m_wrapper:SetValue(val)
end
function Wrapper:GetControlElementValue()
	return self.m_wrapper:GetValue()
end
function Wrapper:SetValue(val)
	val = self:ToInterfaceValue(val)
	self:SetControlElementValue(val)
end
function Wrapper:GetValue()
	local val = self:GetControlElementValue()
	val = self:FromInterfaceValue(val)
	return val
end
function Wrapper:SetValueTranslationFunctions(toInterface, fromInterface)
	self.m_translateToInterface = toInterface
	self.m_translateFromInterface = fromInterface
end
function Wrapper:SetOnChangeValueHandler(handler)
	self.m_valueHandler = handler
end
function Wrapper:OnControlValueChanged(val, isFinal, initialValue)
	if self.m_valueHandler == nil then
		return
	end
	val = self:FromInterfaceValue(val)
	self.m_valueHandler(val, isFinal, initialValue)
end
function Wrapper:GetWrapperElement()
	return self.m_wrapper
end
function Wrapper:GetControlElement()
	return self.m_controlElement
end
function Wrapper:SetContainerElement(container)
	self.m_container = container
end
function Wrapper:GetContainerElement()
	return self.m_container
end

include("control_wrappers")

-----------

function gui.PFMControlsMenu:AddPropertyControl(propType, identifier, localizedText, propInfo)
	if propType == udm.TYPE_HALF then
		return
	end -- Not yet supported
	local animSetControls = self
	local wrapper
	if propType == udm.TYPE_BOOLEAN then
		wrapper = pfm.util.ControlWrapper.Boolean(animSetControls, identifier)
	elseif
		propInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE
		or propInfo.specializationType == "file"
	then
		if propInfo.assetType == "model" then
			wrapper = pfm.util.ControlWrapper.ModelFile(animSetControls, identifier)
		else
			wrapper = pfm.util.ControlWrapper.File(animSetControls, identifier)
		end
		wrapper:SetBasePath(propInfo.basePath)
		wrapper:SetRootPath(propInfo.rootPath)
		wrapper:SetExtensions(propInfo.extensions)
		wrapper:SetStripExtension(propInfo.stripExtension)
	elseif
		propInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR
		or propInfo.specializationType == "color"
	then
		wrapper = pfm.util.ControlWrapper.Color(animSetControls, identifier)
	elseif propType == udm.TYPE_STRING then
		wrapper = pfm.util.ControlWrapper.String(animSetControls, identifier)
	elseif propType == udm.TYPE_EULER_ANGLES then
		wrapper = pfm.util.ControlWrapper.EulerAngles(animSetControls, identifier)
	elseif propType == udm.TYPE_QUATERNION then
		wrapper = pfm.util.ControlWrapper.Quaternion(animSetControls, identifier)
	elseif propType == udm.TYPE_BOOLEAN then
		wrapper = pfm.util.ControlWrapper.Boolean(animSetControls, identifier)
	elseif propInfo.enumValues ~= nil then
		wrapper = pfm.util.ControlWrapper.Enum(animSetControls, identifier)
		wrapper:SetEnumValues(propInfo.enumValues)
	elseif udm.is_numeric_type(propType) then
		wrapper = pfm.util.ControlWrapper.Float(animSetControls, identifier)
		wrapper:SetMin(propInfo.minValue)
		wrapper:SetMax(propInfo.maxValue)
		wrapper:SetInteger(udm.is_integral_type(propType))
		if propInfo.unit ~= nil then
			wrapper:SetUnit(propInfo.unit)
		end
	elseif propType == ents.MEMBER_TYPE_ENTITY then
		wrapper = pfm.util.ControlWrapper.Entity(animSetControls, identifier)
	elseif propType == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
		wrapper = pfm.util.ControlWrapper.ComponentProperty(animSetControls, identifier)
	elseif udm.is_vector_type(propType) then
		wrapper = pfm.util.ControlWrapper.VectorProperty(animSetControls, identifier)
		wrapper:SetUdmType(propType)
	elseif udm.is_matrix_type(propType) then
		wrapper = pfm.util.ControlWrapper.MatrixProperty(animSetControls, identifier)
		wrapper:SetUdmType(propType)
	end
	if wrapper == nil then
		return
	end
	wrapper:SetLocalizedText(localizedText)
	wrapper:SetDefaultValue(propInfo.defaultValue)
	wrapper:InitializeElement()

	self:CallCallbacks("OnPropertyControlAdded", wrapper)
	return wrapper
end
