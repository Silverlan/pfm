-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.impl = pfm.impl or {}

local RendererInfo = util.register_class("pfm.RendererInfo")
function RendererInfo:__init(identifier, udmData)
	self.m_identifier = identifier
	self.m_name = udmData:GetValue("name", udm.TYPE_STRING)

	self.m_capabilities = {}
	local udmCapabilities = udmData:Get("capabilities")
	for name, udmChild in pairs(udmCapabilities:GetChildren()) do
		self:SetCapability(name, udmCapabilities:GetValue(name, udm.TYPE_BOOLEAN))
	end
end
function RendererInfo:SetCapability(name, enabled)
	self.m_capabilities[name] = enabled
end
function RendererInfo:HasCapability(name)
	return self.m_capabilities[name] or false
end
function RendererInfo:GetIdentifier()
	return self.m_identifier
end
function RendererInfo:GetName()
	return self.m_name
end
function RendererInfo:GetRendererName()
	return self.m_rendererName
end
function RendererInfo:InitializeUIRenderSettingControls(elSettings, renderSettings) end
function RendererInfo:ApplyUIRenderSettingsPreset(elSettings, renderSettings, preset) end
function RendererInfo:ApplyUIRenderSettings(elSettings, renderSettings, preset) end

local function load_renderers()
	local renderers = {}
	local path = "cfg/pfm/renderers/"
	local tFiles = file.find(path .. "*.udm")
	for _, f in ipairs(tFiles) do
		local udmData, err = udm.load(path .. f)
		if udmData ~= false then
			local assetData = udmData:GetAssetData():GetData()
			local udmRenderer = assetData:Get("renderer")
			local identifier = file.remove_file_extension(file.get_file_name(f), { "udm" }):lower()

			local script = udmRenderer:GetValue("script", udm.TYPE_STRING)
			if script ~= nil then
				-- The script path should always be absolute, so
				-- we'll ensure the script path starts with a leading slash
				if script:sub(1, 1) ~= "/" then
					script = "/" .. script
				end
				include(script)
			end

			local className = udmRenderer:GetValue("class", udm.TYPE_STRING)
			if pfm[className] ~= nil then
				table.insert(renderers, pfm[className](identifier, udmRenderer))
			end
		end
	end
	return renderers
end

local function load()
	if pfm.impl.renderers ~= nil then
		return
	end
	pfm.impl.renderers = load_renderers()
	local identifierToRendererIdx = {}
	for i, rendererInfo in ipairs(pfm.impl.renderers) do
		identifierToRendererIdx[rendererInfo:GetIdentifier()] = i
	end
	pfm.impl.identifierToRendererIdx = identifierToRendererIdx
end

pfm.get_renderer_info = function(identifier)
	load()
	local idx = pfm.impl.identifierToRendererIdx[identifier]
	if idx == nil then
		return
	end
	return pfm.impl.renderers[idx]
end

pfm.get_renderers = function()
	load()
	return pfm.impl.renderers
end
