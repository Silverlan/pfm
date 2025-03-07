--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/shader_graph/shader_graph.lua")
include("/gui/selectionrect.lua")

local Element = util.register_class("gui.PFMShaderEditor", gui.Base)

local function get_graph_identifier_from_file_path(filePath)
	local graphIdentifier = util.FilePath(filePath)
	graphIdentifier:RemoveFileExtension({
		shader.ShaderGraph.EXTENSION_ASCII,
		shader.ShaderGraph.EXTENSION_BINARY,
	})
	graphIdentifier = graphIdentifier:GetFileName()
	return graphIdentifier
end

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 256)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(128, 128, 128))
	self.m_bg:SetColor(Color(64, 64, 64))

	local szDrag = 100000
	local elDrag = gui.create("WITransformable", self, szDrag * -0.5, szDrag * -0.5, szDrag, szDrag)
	--elDrag:SetDraggable(true)
	--elDrag:GetDragArea():SetAutoAlignToParent(true)
	self.m_transformable = elDrag

	local elGraph = gui.create("WIShaderGraph", elDrag, 0, 0)
	self.m_elGraph = elGraph
	elGraph:SetShaderEditor(self)
	elGraph:AddCallback("OnNodeSocketValueChanged", function(name, id, val)
		self:SetShaderDirty()
	end)
	elGraph:AddCallback("OnLinksChanged", function()
		self:SetShaderDirty()
	end)
	self:AddCallback("SetSize", function()
		--elGraph:SetSize(self:GetWidth(), self:GetHeight())
	end)
	elGraph:SetPos(szDrag * 0.5 - elGraph:GetWidth() * 0.5, szDrag * 0.5 - elGraph:GetHeight() * 0.5)

	local menuBar = gui.create("WIMenuBar", self, 0, 0, self:GetWidth(), 20, 0, 0, 1, 0)
	menuBar
		:AddItem(locale.get_text("file"), function(pContext)
			pContext:AddItem(locale.get_text("new"), function()
				self.m_elGraph:Clear()
				self.m_filePath = nil
			end)
			pContext:AddItem(locale.get_text("open") .. "...", function()
				if self:IsValid() == false then
					return
				end
				local dialoge = gui.create_file_open_dialog(function(pDialoge, file)
					if self:IsValid() == false then
						return
					end
					local filePath = pDialoge:GetFilePath(true)
					local graphIdentifier = get_graph_identifier_from_file_path(filePath)
					local graph, err = shader.load_shader_graph(graphIdentifier)
					if graph == nil then
						self:LogWarn("Failed to load shader graph '" .. graphIdentifier .. "': " .. err)
					else
						self:LogInfo("Loaded shader graph '" .. graphIdentifier .. "'!")
						graph = graph:Copy()
						elGraph:SetGraph(graph)
						self:UpdatePath(filePath)
					end
				end)
				dialoge:SetRootPath(util.DirPath(shader.ShaderGraph.ROOT_PATH, "object"):GetString())
				dialoge:SetExtensions({ shader.ShaderGraph.EXTENSION_ASCII, shader.ShaderGraph.EXTENSION_BINARY })
				dialoge:Update()
			end)
			pContext:AddItem(locale.get_text("save"), function()
				if self:IsValid() == false then
					return
				end
				if self.m_filePath ~= nil then
					self:Save(self.m_filePath)
				else
					self:SaveAs()
				end
			end)
			pContext:AddItem(locale.get_text("save") .. "...", function()
				if self:IsValid() == false then
					return
				end
				self:SaveAs()
			end)
			pContext:AddItem("Reload Shader", function()
				if self:IsValid() == false or self.m_filePath == nil then
					return
				end
				local graphIdentifier = get_graph_identifier_from_file_path(self.m_filePath)
				shader.reload_graph_shader(graphIdentifier)
			end)
			pContext:AddItem("Debug Print", function()
				if self:IsValid() == false then
					return
				end
				self.m_elGraph:GetGraph():DebugPrint()
			end)
			pContext:AddItem("Go to shader file", function()
				if self:IsValid() == false then
					return
				end
				local graphIdentifier = get_graph_identifier_from_file_path(self.m_filePath)
				local filePath = shader.ShaderGraph.get_shader_file_path("object", graphIdentifier)
				util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
			end)
			pContext:AddItem("Go to graph file", function()
				if self:IsValid() == false then
					return
				end
				local graphIdentifier = get_graph_identifier_from_file_path(self.m_filePath)
				local filePath = shader.ShaderGraph.get_file_path("object", graphIdentifier)
				util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
			end)

			pContext:ScheduleUpdate()
		end)
		:SetName("view")
end
function Element:OnRemove()
	util.remove(self.m_cbRenderSceneDirty)
end
function Element:OnVisibilityChanged(visible)
	util.remove(self.m_cbRenderSceneDirty)
	if visible then
		self.m_cbRenderSceneDirty = game.add_callback("Think", function()
			-- Always tag the scene as dirty while the shader editor is active so that time-based
			-- shader effects are visible immediately
			pfm.tag_render_scene_as_dirty()
		end)
	end
end
function Element:GetTransformableElement()
	return self.m_transformable
end
function Element:SetShaderDirty()
	self.m_shaderReloadTime = time.cur_time() + 0.1
	self:SetThinkingEnabled(true)
end
function Element:OnThink()
	if self.m_shaderReloadTime ~= nil and time.cur_time() >= self.m_shaderReloadTime then
		self.m_shaderReloadTime = nil
		local graphIdentifier = get_graph_identifier_from_file_path(self.m_filePath)
		local shaderType = "object"
		local graph = self.m_elGraph:GetGraph()
		shader.sync_shader_graph(shaderType, graphIdentifier, graph)
		shader.reload_graph_shader(graphIdentifier)
		pfm.tag_render_scene_as_dirty()
	end
	if self.m_shaderReloadTime == nil then
		self:SetThinkingEnabled(false)
	end
end
function Element:Save(filePath)
	local graph = self.m_elGraph:GetGraph()

	-- Update node positions
	local nodeData = self.m_elGraph:GetNodeData()
	for _, data in pairs(nodeData) do
		if data.frame:IsValid() then
			local node = data.graphNode
			local pos = data.frame:GetPos()
			pos.x = pos.x - self.m_elGraph:GetHalfWidth()
			pos.y = pos.y - self.m_elGraph:GetHalfHeight()
			node:SetPos(pos)
		end
	end

	local shaderType = "object"
	local res, err = graph:Save(shaderType, filePath)
	if res == false then
		self:LogWarn("Failed to save shader graph '" .. filePath .. "': " .. err)
	else
		self:LogInfo("Saved shader graph '" .. filePath .. "'!")
		self:UpdatePath(filePath)

		local graphIdentifier = get_graph_identifier_from_file_path(filePath)
		shader.sync_shader_graph(shaderType, graphIdentifier, graph)
		self:SetShaderDirty()
	end
	return res
end
function Element:SaveAs()
	local dialoge = gui.create_file_save_dialog(function(pDialoge, file)
		if self:IsValid() == false then
			return
		end
		local filePath = pDialoge:GetFilePath(true)
		if self:Save(filePath) then
		else
			self:LogWarn("Failed to save shader graph '" .. filePath .. "'!")
		end
	end)
	dialoge:SetRootPath(util.DirPath(shader.ShaderGraph.ROOT_PATH, "object"):GetString())
	dialoge:SetExtensions({ shader.ShaderGraph.EXTENSION_ASCII })
	dialoge:Update()
end
function Element:UpdatePath(path)
	path = util.FilePath(path):GetString()
	self.m_filePath = path
end
gui.register("WIPFMShaderEditor", Element)
