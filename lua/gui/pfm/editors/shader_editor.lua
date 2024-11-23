--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/shader_graph/shader_graph.lua")
include("/gui/pfm/editors/content_view.lua")

local Element = util.register_class("gui.PFMShaderEditor", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 256)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(128, 128, 128))
	self.m_bg:SetColor(Color(64, 64, 64))

	local szDrag = 100000
	local elDrag = gui.create("WITransformable", self, szDrag * -0.5, szDrag * -0.5, szDrag, szDrag)
	elDrag:SetDraggable(true)
	elDrag:GetDragArea():SetAutoAlignToParent(true)

	local elGraph = gui.create("WIShaderGraph", elDrag, 0, 0)
	self.m_elGraph = elGraph
	self:AddCallback("SetSize", function()
		elGraph:SetSize(self:GetWidth(), self:GetHeight())
	end)
	elGraph:SizeToContents()
	elGraph:SetPos(szDrag * 0.5, szDrag * 0.5)

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
					local graph, err = shader.ShaderGraph.load("object", filePath)
					if graph == nil then
						self:LogWarn("Failed to load shader graph '" .. filePath .. "': " .. err)
					else
						self:LogInfo("Loaded shader graph '" .. filePath .. "'!")
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

			pContext:ScheduleUpdate()
		end)
		:SetName("view")
end
function Element:Save(filePath)
	local graph = self.m_elGraph:GetGraph()
	local res, err = graph:Save("object", filePath)
	if res == false then
		self:LogWarn("Failed to save shader graph '" .. filePath .. "': " .. err)
	else
		self:LogInfo("Saved shader graph '" .. filePath .. "'!")
		self:UpdatePath(filePath)
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
