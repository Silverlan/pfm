--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.BoneRetargeting:GetFlexControl(i) return self.m_flexControls[i] end
function gui.BoneRetargeting:UpdateFlexPose(mapping,flexCIdSrc,min)
	if(self.m_flexControls[flexCIdSrc] == nil) then return end

	self:StopFlexAnimations()

	self.m_selectedSrcFlexController = nil
	self.m_selectedDstFlexController = nil

	local t = self.m_flexControls[flexCIdSrc]
	local flexCIdDst = tonumber(mapping.menu:GetOptionValue(mapping.menu:GetSelectedOption()))
	if(flexCIdDst == nil) then return end

	local entSrc,flexCSrc,minSrc,maxSrc = self:GetFlexControllerData(1,flexCIdSrc)
	local entDst,flexCDst,minDst,maxDst = self:GetFlexControllerData(2,flexCIdDst)

	local minSrc = mapping.minSource:GetValue()
	local maxSrc = mapping.maxSource:GetValue()
	local minDst = mapping.minTarget:GetValue()
	local maxDst = mapping.maxTarget:GetValue()
	if(min ~= nil) then
		local valueSrc = min and minSrc or maxSrc
		local valueDst = min and minDst or maxDst
		flexCSrc:SetFlexController(flexCIdSrc,valueSrc)
		flexCDst:SetFlexController(flexCIdDst,valueDst,0.0,false)
	end

	if(util.is_valid(self.m_modelView)) then self.m_modelView:Render() end
end
function gui.BoneRetargeting:UpdateFlexControllerTranslations(flexCIdSrc)
	self.m_rig:ClearFlexControllerTranslation(flexCIdSrc)

	if(self.m_flexControls[flexCIdSrc] == nil) then return end
	for _,mapping in ipairs(self.m_flexControls[flexCIdSrc].mappings) do
		local flexCIdDst = tonumber(mapping.menu:GetOptionValue(mapping.menu:GetSelectedOption()))
		if(flexCIdDst ~= nil) then
			local minSrc = mapping.minSource:GetValue()
			local maxSrc = mapping.maxSource:GetValue()
			local minDst = mapping.minTarget:GetValue()
			local maxDst = mapping.maxTarget:GetValue()
			self.m_rig:SetFlexControllerTranslation(flexCIdSrc,flexCIdDst,minSrc,maxSrc,minDst,maxDst)
		end
	end
end
function gui.BoneRetargeting:MapFlexController(flexControllerSrc,flexControllerDst,minSource,maxSource,minTarget,maxTarget)
	if(type(flexControllerSrc) == "string") then flexControllerSrc = self.m_srcMdl:GetSkeleton():LookupFlexController(flexControllerSrc) end
	if(type(flexControllerDst) == "string") then flexControllerDst = self.m_dstMdl:GetSkeleton():LookupFlexController(flexControllerDst) end

	minSource = minSource or 0.0
	maxSource = maxSource or 1.0
	minTarget = minTarget or 0.0
	maxTarget = maxTarget or 1.0

	local data = self.m_flexControls[flexControllerSrc]

	self.m_skipCallbacks = true

	local item = data.treeItem
	local child = item:AddItem("")

	local menu = gui.create("WIDropDownMenu",child)
	for _,option in pairs(self.m_dstFlexControllerOptions) do menu:AddOption(option[2],option[1]) end -- TODO: Don't add option that is already taken!
	local wrapper = menu:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text("controller"))
	wrapper:SetSize(child:GetWidth(),20)
	wrapper:SetAnchor(0,0,1,0)
	wrapper:SetUseAltMode(true)

	if(flexControllerDst ~= -1) then menu:SelectOption(tostring(flexControllerDst)) end

	menu:AddCallback("OnOptionSelected",function() self:UpdateFlexControllerTranslations(flexControllerSrc) end)

	local mappings = self.m_flexControls[flexControllerSrc].mappings
	local t = {}
	for j=0,menu:GetOptionCount() -1 do
		menu:GetOptionElement(j):AddCallback("OnSelectionChanged",function(pItem,selected)
			if(selected) then
				local flexCId1 = tonumber(menu:GetOptionValue(j))
				local srcFlexController = self.m_selectedSrcFlexController
				self:ClearSelectedDstFlexController()

				self:UpdateFlexPose(t,flexControllerSrc)
				self:UpdateFlexControllerTranslations(flexControllerSrc)
				self:SetSelectedDstFlexController(flexCId1)
				if(srcFlexController ~= nil) then self:SetSelectedSrcFlexController(srcFlexController) end

				--self.m_rig:SetFlexControllerTranslation(flexControllerSrc,flexCId1)
				--if(util.is_valid(self.m_modelView)) then self.m_modelView:Render() end
				return
			end
			self.m_rig:ClearFlexControllerTranslation(flexCIdSrc,flexCIdDst)
		end)
	end

	local function add_slider(name,default,maxValue,callback)
		local el = child:AddItem("")
		local slider = gui.create("WIPFMSlider",el)
		slider:SetText(name)
		slider:SetRange(0.0,maxValue)
		slider:SetDefault(default)
		slider:SetStepSize(0.1)
		slider:SetSize(el:GetWidth(),20)
		slider:SetAnchor(0,0,1,0)
		slider:ResetToDefault()
		if(callback ~= nil) then
			slider:AddCallback("OnLeftValueChanged",function(...)
				callback(...)
				self:UpdateFlexControllerTranslations(flexControllerSrc)
				--self:OnValueChanged(identifier,slider:GetValue())
				--if(onChange ~= nil) then onChange(...) end
			end)
		end
		return slider
	end
	table.insert(mappings,t)
	t.menu = menu
	t.minSource = add_slider("min_source",minSource,math.min(minSource,0.0),function() self:UpdateFlexPose(t,flexControllerSrc,true) end)
	t.maxSource = add_slider("max_source",maxSource,math.max(maxSource,1.0),function() self:UpdateFlexPose(t,flexControllerSrc,false) end)
	t.minTarget = add_slider("min_target",minTarget,math.min(minTarget,0.0),function() self:UpdateFlexPose(t,flexControllerSrc,true) end)
	t.maxTarget = add_slider("max_target",maxTarget,math.max(maxTarget,1.0),function() self:UpdateFlexPose(t,flexControllerSrc,false) end)

	self:UpdateFlexPose(t,flexControllerSrc)
	self:UpdateFlexControllerTranslations(flexControllerSrc)
	--item:Expand()

	self.m_skipCallbacks = nil
end
function gui.BoneRetargeting:ResetFlexControllerControls()
	self.m_skipCallbacks = true
	for flexCId0,data in pairs(self.m_flexControls) do
		data.item:Clear()
		data.mappings = {}
	end
	self.m_skipCallbacks = nil
end
function gui.BoneRetargeting:InitializeFlexControls(mdlDst,mdlSrc)
	local options = {}
	for i,flexC in ipairs(mdlSrc:GetFlexControllers()) do
		table.insert(options,{tostring(i -1),flexC.name})
	end
	table.insert(options,1,{"-1","-"})
	self.m_dstFlexControllerOptions = options

	local flexControllersSrc = mdlSrc:GetFlexControllers()

	local tree = gui.create("WIPFMTreeView",self.m_rigControls,0,0,self.m_rigControls:GetWidth(),20)
	tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	local itemToFlexController = {}
	tree:AddCallback("OnItemSelectChanged",function(tree,el,selected)
		local flexCId = itemToFlexController[el]
		if(flexCId == nil) then return end
		self:SetSelectedSrcFlexController(flexCId)
		self:ClearSelectedDstFlexController()
		--elf:ScheduleUpdateSelectedEntities()
	end)

	local flexControllers = mdlDst:GetFlexControllers()
	for i,flexC in ipairs(flexControllers) do
		local item = tree:AddItem(flexC.name)
		local el = gui.create("WIRect",item)
		el:SetSize(1,item:GetHeight())
		el:SetColor(Color.Gray)
		self.m_flexControls[i -1] = {
			treeItem = item,
			mappings = {},
			valueIndicator = el
		}
		item:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext)) then
					pContext:SetPos(input.get_cursor_pos())
					pContext:AddItem(locale.get_text("add_mapping"),function()
						self:MapFlexController(i -1,-1)
					end)
					--[[for i,flexC in ipairs(flexControllersSrc) do
						pContext:AddItem(flexC.name,function()
							-- self:ShowInElementViewer(filmClip)
						end)
					end]]
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)

		
		itemToFlexController[item] = i -1

		--[[local el,wrapper = self.m_rigControls:AddDropDownMenu(flexC.name,i -1,options,0,function(el)

		end)
		el:AddCallback("OnMenuOpened",function()
			self:SetSelectedSrcFlexController(i -1)
			self:ClearSelectedDstFlexController()
		end)
		el:AddCallback("OnMenuClosed",function()
			self:ClearSelectedSrcFlexController()
			self:ClearSelectedDstFlexController()
		end)
		wrapper:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)

		end)
		wrapper:SetCenterText(false)
		for j=0,el:GetOptionCount() -1 do
			el:GetOptionElement(j):AddCallback("OnSelectionChanged",function(pItem,selected)
				if(selected) then
					local flexCId1 = tonumber(el:GetOptionValue(j))
					self:ClearSelectedDstFlexController()
					self:SetSelectedDstFlexController(flexCId1)

					--self.m_rig:SetFlexControllerTranslation(i -1,flexCId1)
					--if(util.is_valid(self.m_modelView)) then self.m_modelView:Render() end
					return
				end
			end)
		end
		wrapper:SetUseAltMode(true)
		self.m_flexControls[i -1] = el]]
	end
end
function gui.BoneRetargeting:GetFlexControllerData(entIdx,fcId)
	local ent = util.is_valid(self.m_modelView) and self.m_modelView:GetEntity(entIdx) or nil
	local mdl = util.is_valid(ent) and ent:GetModel() or nil
	local flexData = (mdl ~= nil) and mdl:GetFlexController(fcId) or nil
	local flexC = (flexData ~= nil) and ent:GetComponent(ents.COMPONENT_FLEX) or nil
	if(flexC == nil) then return end
	return ent,flexC,flexData.min,flexData.max
end
function gui.BoneRetargeting:SetSelectedDstFlexController(idx)
	self:ClearSelectedDstFlexController(idx)
	self.m_selectedDstFlexController = idx
end
function gui.BoneRetargeting:SetSelectedSrcFlexController(idx)
	self:ClearSelectedSrcFlexController(idx)
	self.m_selectedSrcFlexController = idx
end
function gui.BoneRetargeting:ClearSelectedDstFlexController()
	if(self.m_selectedDstFlexController == nil) then return end
	local fcId = self.m_selectedDstFlexController
	self.m_selectedDstFlexController = nil

	local ent,flexC,min,max = self:GetFlexControllerData(2,fcId)
	if(flexC == nil) then return end
	flexC:SetFlexController(fcId,0.0)
	self.m_modelView:Render()
end
function gui.BoneRetargeting:ClearSelectedSrcFlexController()
	if(self.m_selectedSrcFlexController == nil) then return end
	local fcId = self.m_selectedSrcFlexController
	self.m_selectedSrcFlexController = nil

	local ent,flexC,min,max = self:GetFlexControllerData(1,fcId)
	if(flexC == nil) then return end
	flexC:SetFlexController(fcId,0.0)
	self.m_modelView:Render()
end
function gui.BoneRetargeting:ApplyFlexControllerTranslation(el,flexC)

end
function gui.BoneRetargeting:StopFlexAnimations()
	if(util.is_valid(self.m_modelView) == false) then return end
	local tEnts = {self.m_modelView:GetEntity(1),self.m_modelView:GetEntity(2)}
	for _,ent in ipairs(tEnts) do
		if(util.is_valid(ent)) then
			local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
			if(flexC ~= nil) then
				for _,animId in ipairs(flexC:GetFlexAnimations()) do
					flexC:StopFlexAnimation(animId)
				end
			end
		end
	end
end
function gui.BoneRetargeting:UpdateFlexControllers()
	local ent = util.is_valid(self.m_modelView) and self.m_modelView:GetEntity(1) or nil
	if(util.is_valid(ent)) then
		local mdl = ent:GetModel()
		local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
		if(flexC ~= nil and mdl ~= nil) then
			if(flexC:GetFlexAnimationCount() > 0) then self.m_modelView:Render() end
			for i=1,mdl:GetFlexControllerCount() do
				if(self.m_flexControls[i -1] ~= nil and util.is_valid(self.m_flexControls[i -1].valueIndicator)) then
					local flexControllerData = mdl:GetFlexController(i -1)
					local val = flexC:GetFlexController(i -1)
					local el = self.m_flexControls[i -1].valueIndicator
					local parent = el:GetParent()
					local f = (val -flexControllerData.min) /(flexControllerData.max -flexControllerData.min)
					el:SetX(parent:GetWidth() *f)
				end
			end
		end
	end

	if(self.m_selectedSrcFlexController == nil and self.m_selectedDstFlexController == nil) then return end

	local t = time.real_time()
	local f = (math.sin(t *math.pi) +1.0) /2.0

	if(self.m_selectedDstFlexController ~= nil) then
		local ent,flexC,min,max = self:GetFlexControllerData(2,self.m_selectedDstFlexController)
		if(ent ~= nil) then
			local v = math.lerp(min,max,f)
			flexC:SetFlexController(self.m_selectedDstFlexController,v)
		end
	elseif(self.m_selectedSrcFlexController ~= nil and self.m_rig ~= nil) then
		local translationTable = self.m_rig:GetFlexControllerTranslationTable()
		if(translationTable[self.m_selectedSrcFlexController] ~= nil) then
			for flexCIdDst,data in pairs(translationTable[self.m_selectedSrcFlexController]) do
				local ent,flexC,min,max = self:GetFlexControllerData(2,flexCIdDst)
				if(flexC ~= nil) then
					local srcVal = math.clamp(math.lerp(data.min_source,data.max_source,f),data.min_source,data.max_source)
					local f = srcVal /(data.max_source -data.min_source)
					local dstVal = data.min_target +f *(data.max_target -data.min_target)
					flexC:SetFlexController(flexCIdDst,dstVal,0.0,false)
				end
			end
		end
	end
	if(self.m_selectedSrcFlexController ~= nil) then
		local ent,flexC,min,max = self:GetFlexControllerData(1,self.m_selectedSrcFlexController)
		if(ent ~= nil) then
			local v = math.lerp(min,max,f)
			flexC:SetFlexController(self.m_selectedSrcFlexController,v)
		end
	end

	self.m_modelView:Render()
end
