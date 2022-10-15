--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("treeview.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/pfm/history.lua")

util.register_class("gui.PFMElementViewer",gui.Base)

function gui.PFMElementViewer:__init()
	gui.Base.__init(self)
end
function gui.PFMElementViewer:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.navBar = gui.create("WIHBox",self)
	self:InitializeNavigationBar()

	self.navBar:SetHeight(32)
	self.navBar:SetAnchor(0,0,1,0)

	self.m_btTools = gui.PFMButton.create(self,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("TODO")
	end)
	self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth())
	self.m_btTools:SetupContextMenu(function(pContext)
		pContext:AddItem(locale.get_text("open"),function()
			local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
				if(fileName == nil) then return end
				self:OpenUdmFile(fileName)
			end)
			pFileDialog:SetRootPath("")
			pFileDialog:Update()
		end)
	end,true)

	local btSave = gui.create("WIPFMButton",self.m_bg)
	btSave:SetHeight(32)
	self.m_contents = gui.create("WIHBox",self,
		0,self.m_btTools:GetBottom(),self:GetWidth(),self:GetHeight() -self.m_btTools:GetBottom() -btSave:GetHeight(),
		0,0,1,1
	)
	self.m_contents:SetAutoFillContents(true)

	local treeVBox = gui.create("WIVBox",self.m_contents)
	treeVBox:SetAutoFillContents(true)
	local resizer = gui.create("WIResizer",self.m_contents)
	local dataVBox = gui.create("WIVBox",self.m_contents)
	dataVBox:SetAutoFillContents(true)

	local function create_header_text(text,parent)
		local pHeader = gui.create("WIRect",parent,0,0,parent:GetWidth(),21,0,0,1,0)
		pHeader:SetColor(Color(35,35,35))
		local pHeaderText = gui.create("WIText",pHeader)
		pHeaderText:SetColor(Color(152,152,152))
		pHeaderText:SetFont("pfm_medium")
		pHeaderText:SetText(text)
		pHeaderText:SizeToContents()
		pHeader:AddCallback("SetSize",function()
			if(pHeaderText:IsValid() == false) then return end
			pHeaderText:SetPos(pHeader:GetWidth() *0.5 -pHeaderText:GetWidth() *0.5,pHeader:GetHeight() *0.5 -pHeaderText:GetHeight() *0.5)
		end)
	end
	create_header_text(locale.get_text("tree"),treeVBox)
	create_header_text(locale.get_text("data"),dataVBox)

	-- Tree
	local treeScrollContainerBg = gui.create("WIBase",treeVBox,0,0,64,128)
	local treeScrollContainer = gui.create("WIScrollContainer",treeScrollContainerBg,0,0,64,128,0,0,1,1)
	treeScrollContainerBg:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_tree)) then
			self.m_tree:SetWidth(el:GetWidth())
		end
	end)
	self.m_tree = gui.create("WIPFMTreeView",treeScrollContainer,0,0,treeScrollContainer:GetWidth(),treeScrollContainer:GetHeight())
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	-- Data
	local dataScrollContainerBg = gui.create("WIBase",dataVBox,0,0,64,128)
	local dataScrollContainer = gui.create("WIScrollContainer",dataScrollContainerBg,0,0,64,128,0,0,1,1)
	dataScrollContainerBg:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_data)) then
			self.m_data:SetWidth(el:GetWidth())
		end
	end)
	self.m_data = gui.create("WIPFMTreeView",dataScrollContainer,0,0,dataScrollContainer:GetWidth(),dataScrollContainer:GetHeight())
	self.m_data:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	self.m_treeElementToDataElement = {}
	self.m_history = pfm.History()
	self.m_history:AddCallback("OnPositionChanged",function(item,index)
		if(item ~= nil) then self:PopulateFromUDMData(item) end
		if(util.is_valid(self.m_btBack)) then self.m_btBack:SetEnabled(index > 1) end
		if(util.is_valid(self.m_btForward)) then self.m_btForward:SetEnabled(index < #self:GetHistory()) end
		if(util.is_valid(self.m_btUp)) then self.m_btUp:SetVisible(true) end -- TODO
	end)

	local inCallback = false
	treeScrollContainer:GetVerticalScrollBar():AddCallback("OnScrollOffsetChanged",function(el,offset)
		if(inCallback == true) then return end
		inCallback = true
			dataScrollContainer:GetVerticalScrollBar():SetScrollOffset(offset)
		inCallback = false
	end)
	dataScrollContainer:GetVerticalScrollBar():AddCallback("OnScrollOffsetChanged",function(el,offset)
		if(inCallback == true) then return end
		inCallback = true
			treeScrollContainer:GetVerticalScrollBar():SetScrollOffset(offset)
		inCallback = false
	end)

	-- Save
	local pBg = gui.create("WIRect",btSave,0,0,btSave:GetWidth(),btSave:GetHeight(),0,0,1,1)
	pBg:SetVisible(false)
	self.m_saveBg = pBg
	btSave:SetText(locale.get_text("save"))
	btSave:AddCallback("OnPressed",function()
		self:Save()
	end)
	btSave:SetWidth(self.m_bg:GetWidth())
	btSave:SetY(self.m_bg:GetBottom() -btSave:GetHeight())
	btSave:SetAnchor(0,1,1,1)
	self.m_btSave = btSave

	self:OpenUdmFile("models/error_test2.pmdl_b")
end
function gui.PFMElementViewer:UpdateSaveButton(saved)
	self.m_saveBg:SetVisible(true)
	if(saved) then self.m_saveBg:SetColor(Color(20,100,20))
	else self.m_saveBg:SetColor(Color(100,20,20)) end
end
function gui.PFMElementViewer:Save()
	if(self.m_udmData == nil) then return end
	local fileName = self.m_fileName
	if(fileName == nil) then return false end

	local isBinary = fileName:sub(-2):lower() == "_b"

	local flags = file.OPEN_MODE_WRITE
	if(isBinary) then flags = bit.bor(flags,file.OPEN_MODE_BINARY) end
	local f = file.open(fileName,flags)
	if(f == nil) then
		pfm.log("Unable to open UDM file '" .. fileName .. "' for writing!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local res,err
	if(isBinary) then res,err = self.m_udmData:Save(f)
	else res,err = self.m_udmData:SaveAscii(f) end
	f:Close()
	if(res == false) then
		pfm.log("Failed to UDM file as '" .. fileName .. "': " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	pfm.log("UDM file has been saved as '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)
	self:UpdateSaveButton(true)
	return true
end
function gui.PFMElementViewer:OpenUdmFile(fileName)
	self.m_fileName = nil
	self.m_tree:Clear()

	local udmData,err = udm.load(fileName)
	if(udmData == false) then
		console.print_warning("Unable to open UDM file: ",err)
		return
	end

	self.m_fileName = fileName
	local assetData = udmData:GetAssetData()
	self.m_assetData = assetData:ClaimOwnership()
	self.m_udmData = udmData
	self:Setup(assetData)

	self:MakeElementRoot(assetData:GetData())
	local elRoot = self.m_tree:GetRoot():FindItemByText("root")
	if(elRoot ~= nil) then elRoot:Expand() end
end
function gui.PFMElementViewer:UpdateDataElementPositions()
	if(util.is_valid(self.m_tree) == false) then return end
	local c = 0
	for elTree,elData in pairs(self.m_treeElementToDataElement) do
		c = c +1
		if(elTree:IsValid() and elData:IsValid()) then
			elData:SetPos(0,elTree:GetAbsolutePos().y -self.m_tree:GetAbsolutePos().y)
		else self.m_treeElementToDataElement[elTree] = nil end
	end
end
function gui.PFMElementViewer:PopulateFromUDMData(rootNode)
	if(util.is_valid(self.m_tree) == false) then return end
	self.m_tree:Clear()
	self:AddUDMNode(nil,rootNode,"root",self.m_tree,self.m_tree)
	self.m_tree:Update()
	self:UpdateDataElementPositions()
end
function gui.PFMElementViewer:Setup(rootNode)
	self.m_rootNode = rootNode
	self:GetHistory():Clear()
	self:GetHistory():Add(rootNode)
end
function gui.PFMElementViewer:GetHistory() return self.m_history end
function gui.PFMElementViewer:MakeElementRoot(element)
	self:GetHistory():Add(element)
end
function gui.PFMElementViewer:AddUDMNode(parent,node,name,elTreeParent,elTreePrevious)
	if(util.is_valid(self.m_data) == false) then return end
	local elTreeChild
	local text
	local isValue = false
	local validValue = true
	local function addContextMenuRemoveItem(pContext)
		pContext:AddItem(locale.get_text("remove"),function()
			parent:RemoveValue(name)
			util.remove({elTreeChild,self.m_treeElementToDataElement[elTreeChild]})
			elTreeParent:FullUpdate()

			self:UpdateSaveButton(false)
		end)
	end
	if(node:GetType() == udm.TYPE_ELEMENT or udm.is_array_type(node:GetType())) then
		elTreeChild = elTreeParent:AddItem(name,function(elTree)
			local elTreePrevious = elTree
			if(node:GetChildCount() > 0) then
				local children = node:GetChildren()
				local sorted = {}
				for name,child in pairs(children) do table.insert(sorted,name) end
				table.sort(sorted)

				for _,name in ipairs(sorted) do
					local child = children[name]
					elTreePrevious = self:AddUDMNode(node,child,name,elTree,elTreePrevious)
				end
			elseif(node:GetSize() < 1000) then
				local items = node:GetArrayValues()
				for i,item in ipairs(items) do
					elTreePrevious = self:AddUDMNode(node,node:Get(i -1),tostring(i),elTree,elTreePrevious)
				end
			end
			self:UpdateDataElementPositions()
		end)
		if(node:GetType() == udm.TYPE_ELEMENT) then
			elTreeChild:AddCallback("OnMouseEvent",function(elTreeChild,button,state,mods)
				if(button == input.MOUSE_BUTTON_RIGHT) then
					if(state == input.STATE_PRESS) then
						local pContext = gui.open_context_menu()
						if(util.is_valid(pContext) == false) then return end
						pContext:SetPos(input.get_cursor_pos())
						pContext:AddItem(locale.get_text("pfm_make_root"),function()
							self:MakeElementRoot(node)
						end)

						local types = {}
						for i=0,udm.TYPE_COUNT -1 do
							if(i ~= udm.TYPE_ARRAY) then
								table.insert(types,{i,udm.enum_type_to_ascii(i)})
							end
						end
						table.sort(types,function(a,b) return a[2] < b[2] end)

						local function addProperty(type,arrayValueType)
							elTreeChild:Expand()

							local tmpItem = elTreeChild:AddItem("")
							local te = gui.create("WITextEntry",tmpItem,0,0,tmpItem:GetWidth(),tmpItem:GetHeight(),0,0,1,1)
							te:RequestFocus()
							te:AddCallback("OnFocusKilled",function()
								local text = te:GetText()
								if(#text == 0) then
									te:RemoveSafely()
									tmpItem:RemoveSafely()
									elTreeChild:FullUpdate()
									return
								end
								if(type == udm.TYPE_ELEMENT) then node:Add(text)
								elseif(udm.is_array_type(type)) then node:AddArray(text,0,arrayValueType,(type == udm.TYPE_ARRAY) and udm.ARRAY_TYPE_RAW or udm.ARRAY_TYPE_COMPRESSED)
								else node:SetValue(text,type,udm.convert("",udm.TYPE_STRING,type)) end
								te:RemoveSafely()
								tmpItem:RemoveSafely()

								elTreeChild:Collapse()
								elTreeChild:Expand()

								self:UpdateSaveButton(false)
							end)
						end

						local _,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_add_property"))
						for _,typeInfo in ipairs(types) do
							local type = typeInfo[1]
							pSubMenu:AddItem(typeInfo[2],function(pItem) addProperty(type) end)
						end

						local _,pSubMenuArray = pSubMenu:AddSubMenu(locale.get_text("pfm_add_array"))
						for _,typeInfo in ipairs(types) do
							local type = typeInfo[1]
							if(udm.is_supported_array_value_type(type)) then
								pSubMenuArray:AddItem(typeInfo[2],function(pItem)
									if(util.is_valid(self) == false) then return end
									addProperty(udm.TYPE_ARRAY,type)
								end)
							end
						end

						local _,pSubMenuArray = pSubMenu:AddSubMenu(locale.get_text("pfm_add_compressed_array"))
						for _,typeInfo in ipairs(types) do
							local type = typeInfo[1]
							if(udm.is_supported_array_value_type(type)) then
								pSubMenuArray:AddItem(typeInfo[2],function(pItem)
									if(util.is_valid(self) == false) then return end
									addProperty(udm.TYPE_ARRAY_LZ4,type)
								end)
							end
						end

						pSubMenu:ScheduleUpdate()

						addContextMenuRemoveItem(pContext)

						pContext:Update()
					end
					return util.EVENT_REPLY_HANDLED
				end
			end)
		else
			elTreeChild:AddCallback("OnMouseEvent",function(elTreeChild,button,state,mods)
				if(button == input.MOUSE_BUTTON_RIGHT) then
					if(state == input.STATE_PRESS) then
						local pContext = gui.open_context_menu()
						if(util.is_valid(pContext) == false) then return end
						pContext:SetPos(input.get_cursor_pos())
						pContext:AddItem(locale.get_text("pfm_add_item"),function()
							node:Resize(node:GetSize() +1)
							elTreeChild:Collapse()
							elTreeChild:Expand()

							self:UpdateSaveButton(false)
						end)

						addContextMenuRemoveItem(pContext)

						pContext:Update()
					end
					return util.EVENT_REPLY_HANDLED
				end
			end)
		end
		text = util.get_type_name(node)
		if(text == "LinkedPropertyWrapper") then text = "Element" end
	else
		elTreeChild = elTreeParent:AddItem(name)

		elTreeChild:AddCallback("OnMouseEvent",function(elTreeChild,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT) then
				if(state == input.STATE_PRESS) then
					local pContext = gui.open_context_menu()
					if(util.is_valid(pContext) == false) then return end
					pContext:SetPos(input.get_cursor_pos())
					addContextMenuRemoveItem(pContext)

					pContext:Update()
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)

		elTreeChild:Collapse()
		text = udm.convert(node:GetValue(),node:GetType(),udm.TYPE_STRING)
		if(text == nil) then
			if(node:GetType() == udm.TYPE_NIL) then text = "nil"
			else validValue = false text = "[INVALID]" end
		end
		isValue = true
	end

	local itemParent = self.m_treeElementToDataElement[elTreePrevious]
	local insertIndex
	if(util.is_valid(itemParent)) then
		insertIndex = itemParent:GetParent():FindChildIndex(itemParent)
		if(insertIndex ~= nil) then insertIndex = insertIndex +1 end
	end

	local item = self.m_data:AddItem(text,nil,insertIndex)
	local function addTextEntry(itemParent,onComplete)
		local te = gui.create("WITextEntry",itemParent,0,0,itemParent:GetWidth(),itemParent:GetHeight(),0,0,1,1)
		te:RequestFocus()
		te:AddCallback("OnFocusKilled",function()
			te:RemoveSafely()
			onComplete(te:GetText())
		end)
		return te
	end

	if(isValue and validValue) then
		item:AddCallback("OnDoubleClick",function()
			local te = addTextEntry(item,function(text)
				local newValue = udm.convert(text,udm.TYPE_STRING,node:GetType())
				parent:SetValue(name,node:GetType(),newValue)
				item:SetText(udm.convert(node:GetValue(),node:GetType(),udm.TYPE_STRING))

				self:UpdateSaveButton(false)
			end)
			te:SetText(udm.convert(node:GetValue(),node:GetType(),udm.TYPE_STRING))
		end)
	end
	self.m_treeElementToDataElement[elTreeChild] = item
	elTreeChild:AddCallback("OnRemove",function()
		if(self.m_data:IsValid() and item:IsValid()) then
			self.m_data:GetRoot():RemoveItem(item)
		end
	end)
	--[[if(node:GetType() == fudm.ATTRIBUTE_TYPE_BOOL) then
		local el = gui.create("WICheckbox")
		pRow:InsertElement(0,el)
		el:SetChecked(node:GetValue())
	else
		pRow:SetValue(0,text)
	end]]

	--

	--[[if(node:IsAttribute()) then
		node:AddChangeListener(function(newVal)
			-- TODO
			--if(item:IsValid()) then item:SetValue(0,node:ToASCIIString()) end
		end)
	end]]
	return elTreeChild
end
function gui.PFMElementViewer:OnSizeChanged(w,h)
	if(util.is_valid(self.m_btTools)) then self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth()) end
end
function gui.PFMElementViewer:InitializeNavigationBar()
	self.m_btHome = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_home","gui/pfm/icon_nav_home_activated",function()
		if(self.m_rootNode == nil) then return end
		self:GetHistory():Clear()
		self:GetHistory():Add(self.m_rootNode)
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btUp = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_up","gui/pfm/icon_nav_up_activated",function()
		print("TODO")
	end)
	self.m_btUp:SetupContextMenu(function(pContext)
		print("TODO")
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btBack = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_back","gui/pfm/icon_nav_back_activated",function()
		self:GetHistory():GoBack()
	end)
	self.m_btBack:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		if(pos > 1) then
			for i=pos -1,1,-1 do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btForward = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_forward","gui/pfm/icon_nav_forward_activated",function()
		self:GetHistory():GoForward()
	end)
	self.m_btForward:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		local numItems = #history
		if(pos < numItems) then
			for i=pos +1,numItems do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)
end
gui.register("WIPFMElementViewer",gui.PFMElementViewer)
