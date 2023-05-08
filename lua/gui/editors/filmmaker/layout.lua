--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

pfm.register_log_category("layout")

local Layout = util.register_class("gui.WIFilmmaker.Layout")
function Layout:__init()
    self.m_frameContainers = {}
end
function Layout:AddFrameContainer(identifier)
    local container = gui.WIFilmmaker.Layout.FrameContainer()
    self.m_frameContainers[identifier] = {
        container = container
    }
    return container
end
function Layout:GetFrameContainer(identifier)
    return self.m_frameContainers[identifier]
end
function Layout:GetFrameContainers() return self.m_frameContainers end

Layout.load = function(fileName)
	local udmData,err = udm.load(fileName)
    if(udmData == false) then return false,err end
    udmData = udmData:GetAssetData():GetData()
    local udmLayout = udmData:ClaimOwnership()
    udmLayout = udmLayout:Get("layout")

    local layout = gui.WIFilmmaker.Layout()
    local iContainer = 0
    local function addContainer(udmContainer,parent)
        local defaultRatio = udmContainer:GetValue("defaultFrameSizeRatio",udm.TYPE_FLOAT)
        local c = parent:AddFrameContainer(udmContainer:GetValue("name") or ("container" .. tostring(iContainer)),defaultRatio)
        iContainer = iContainer +1
        local isHorizontal = udmContainer:GetValue("horizontal",udm.TYPE_BOOLEAN)
        if(isHorizontal ~= nil) then c:SetHorizontal(isHorizontal) end

        for i,udmChild in ipairs(udmContainer:GetArrayValues("children")) do
            local type = udmChild:GetValue("type",udm.TYPE_STRING)
            if(type == "frame") then
                local udmFrame = udmChild
                local frameName = udmFrame:GetValue("name") or ("frame" .. tostring(i -1))
                local defaultRatio = udmFrame:GetValue("defaultFrameSizeRatio",udm.TYPE_FLOAT)
                local frame = c:AddFrame(frameName,defaultRatio)
                for _,catName in ipairs(udmFrame:GetArrayValues("windowCategories",udm.TYPE_STRING)) do
                    frame:AddCategory(catName)
                end
            else
                local udmContainer = udmChild
                addContainer(udmContainer,c)
            end
        end
    end
    local udmRootContainer = udmLayout:Get("rootContainer")
    if(util.is_valid(udmRootContainer)) then addContainer(udmRootContainer,layout) end
    return layout
end

local FrameContainer = util.register_class("gui.WIFilmmaker.Layout.FrameContainer")
function FrameContainer:__init()
    self.m_frames = {}
    self.m_horizontal = true
end
function FrameContainer:SetHorizontal(horizontal)
    self.m_horizontal = horizontal
end
function FrameContainer:IsHorizontal()
    return self.m_horizontal
end
function FrameContainer:SetVertical(vertical)
    self.m_horizontal = not vertical
end
function FrameContainer:IsVertical()
    return not self.m_horizontal
end
function FrameContainer:AddFrame(frameName,defaultRatio)
    local frame = gui.WIFilmmaker.Layout.Frame()
    table.insert(self.m_frames,{
        type = "frame",
        frame = frame,
        name = frameName,
        defaultRatio = defaultRatio
    })
    return frame
end
function FrameContainer:AddFrameContainer(frameName,defaultRatio)
    local frameContainer = gui.WIFilmmaker.Layout.FrameContainer()
    table.insert(self.m_frames,{
        type = "frameContainer",
        container = frameContainer,
        name = frameName,
        defaultRatio = defaultRatio
    })
    return frameContainer
end
function FrameContainer:GetFrame(frameName)
    return self.m_frames[frameName]
end
function FrameContainer:GetFrames() return self.m_frames end

local Frame = util.register_class("gui.WIFilmmaker.Layout.Frame")
function Frame:__init()
    self.m_categories = {}
end
function Frame:AddCategory(catName)
    table.insert(self.m_categories,catName)
end
function Frame:GetCategories()
    return self.m_categories
end

function Element:InitializeLayout(layoutFileName)
    layoutFileName = layoutFileName or "cfg/pfm/layouts/default.udm"
    self.m_layoutFileName = layoutFileName
    pfm.log("Loading layout configuration '" .. layoutFileName .. "'...",pfm.LOG_CATEGORY_LAYOUT,pfm.LOG_SEVERITY_INFO)
    local layout,err = gui.WIFilmmaker.Layout.load(layoutFileName)
    if(layout == false) then
        pfm.log("Unable to load layout configuration '" .. layoutFileName .. "': " .. err,pfm.LOG_CATEGORY_LAYOUT,pfm.LOG_SEVERITY_WARNING)
        layout = gui.WIFilmmaker.Layout()
        layout:AddFrameContainer("default"):AddFrame("default")
    end

    self.m_firstFrame = nil
    self.m_layout = layout
    self.m_windowToFrame = {}
    self.m_frameContainers = {}
    local function addFrameContainer(fcId,container,parent)
        local elContents
        if(container:IsHorizontal()) then
            elContents = gui.create("WIHBox",parent)
        else
            elContents = gui.create("WIVBox",parent)
        end
        local frameContainerId = "frame_container_" .. fcId
        elContents:SetName(frameContainerId)
        elContents:SetAutoFillContents(true)

        local frames = {}
        local dividers = {}
        local first = true
        local resizerRatio = 0.25
        for i,frameData in ipairs(container:GetFrames()) do
            if(first) then
                first = false
            else
                local resizer = gui.create("WIResizer",elContents)
                resizer:SetFraction(resizerRatio)
                resizer:SetName(frameContainerId .. "_divider_" .. (i -1))
                table.insert(dividers,resizer)
            end
            resizerRatio = frameData.defaultRatio or 0.5
            if(frameData.type == "frameContainer") then
                addFrameContainer(frameData.name,frameData.container,elContents)
            else
                local elFrame = self:AddFrame(elContents)
                self.m_firstFrame = elFrame
                elFrame:SetName(frameData.name)
                frames[frameData.name] = {
                    frame = elFrame
                }
                for _,catName in ipairs(frameData.frame:GetCategories()) do
                    self:RegisterFrame(catName,elFrame)
                end
            end
        end

        self.m_frameContainers[fcId] = {
            contents = elContents,
            frames = frames,
            dividers = dividers
        }
    end
    for fcId,containerInfo in pairs(layout:GetFrameContainers()) do
        addFrameContainer(fcId,containerInfo.container,self.m_contents)
    end
end
function Element:GetFrameContainerData(identifier) return self.m_frameContainers[identifier] end

function Element:LoadLayout(fileName)
    self:CallCallbacks("OnChangeLayout",fileName)
    self:InitializeProjectUI(fileName)
end

function Element:LoadWindowLayoutState(fileName)
    local udmData,err = udm.load(fileName)
    if(udmData == false) then
        pfm.log("Unable to open layout state configuration '" .. fileName .. "': " .. err,pfm.LOG_CATEGORY_LAYOUT,pfm.LOG_SEVERITY_WARNING)
        return
    end
    udmData = udmData:GetAssetData():GetData()
    udmData = udmData:ClaimOwnership()
    return udmData
end

function Element:RestoreWindowLayoutState(udmData,restoreLayout)
    if(restoreLayout == nil) then restoreLayout = true end
    if(type(udmData) == "string") then
        udmData = self:LoadWindowLayoutState(udmData)
        if(udmData == nil) then return end
    end
    local udmLayout = udmData:Get("layout_state")

    if(restoreLayout) then
        local layout = udmLayout:GetValue("layout",udm.TYPE_STRING)
        if(layout ~= nil) then
            self:LoadLayout(layout)
        end
    end

    for containerId,udmContainer in pairs(udmLayout:GetChildren("containers")) do
        local frameContainerId = "frame_container_" .. containerId
        local frameSizeRatios = udmContainer:GetArrayValues("frameSizeRatios",udm.TYPE_FLOAT)
        for iResizer,ratio in ipairs(frameSizeRatios) do
            local elResizer = gui.find_element_by_name(frameContainerId .. "_divider_" .. iResizer)
            if(util.is_valid(elResizer)) then elResizer:SetFraction(ratio) end
        end
    end

    local primMonitor = gui.get_primary_monitor()
    local primVideoMode = primMonitor:GetVideoMode()
    local detachedWindows = {}
    for name,udmWindow in pairs(udmLayout:GetChildren("windows")) do
        local udmDetachedWindow = udmWindow:Get("detachedWindow")
        if(udmDetachedWindow:IsValid()) then
            local pos = udmDetachedWindow:GetValue("pos",udm.TYPE_VECTOR2)
            local size = udmDetachedWindow:GetValue("size",udm.TYPE_VECTOR2)

            if(pos ~= nil) then pos = Vector2i(pos.x *primVideoMode.width,pos.y *primVideoMode.height) end
            if(size ~= nil) then size = Vector2i(size.x *primVideoMode.width,size.y *primVideoMode.height) end

            detachedWindows[name] = true

            local window
            if(name == "main") then window = gui.get_primary_window()
            else
                local tab,el,frame = self:OpenWindow(name)
                if(util.is_valid(frame)) then
                    window = frame:DetachTab(name,(size ~= nil) and size.x or nil,(size ~= nil) and size.y or nil)
                end
            end
            if(util.is_valid(window)) then
                if(size ~= nil) then
                    window:SetSize(size)
                end
                if(pos ~= nil) then
                    window:SetPos(pos)
                end
            end
        end
    end

	for _,windowData in ipairs(pfm.get_registered_windows()) do
        if(detachedWindows[windowData.name] ~= true and self:IsWindowOpen(windowData.name)) then
            self:AttachWindow(windowData.name)
        end
	end
end

function Element:SaveWindowLayoutState(assetData,saveLayout)
    local fileName
    if(type(assetData) == "string") then
        fileName = assetData
        assetData = nil
    end
    local udmData
    if(assetData == nil) then
        udmData = udm.create()
	    assetData = udmData:GetAssetData():GetData()
    end
	local udmLayoutState = assetData:Add("layout_state")
    local frameMap = {}
    for catName,frame in pairs(self:GetFrames()) do
        if(frame:IsValid()) then
            frameMap[frame] = true
        end
    end
    local frames = {}
    for frame,_ in pairs(frameMap) do table.insert(frames,frame) end

    local udmContainers = udmLayoutState:Add("containers")
    local function addContainer(containerId,containerInfo)
        local frameContainerId = "frame_container_" .. containerId
        local el = gui.find_element_by_name(frameContainerId)

        local resizerValues = {}
        local iResizer = 1
        local elResizer = gui.find_element_by_name(frameContainerId .. "_divider_" .. iResizer)
        while(util.is_valid(elResizer)) do
            table.insert(resizerValues,elResizer:GetFraction())
            iResizer = iResizer +1
            elResizer = gui.find_element_by_name(frameContainerId .. "_divider_" .. iResizer)
        end
        local udmContainer = udmContainers:Add(containerId)
        udmContainer:SetArrayValues("frameSizeRatios",udm.TYPE_FLOAT,resizerValues)

        local container = containerInfo.container
        for frameId,frameInfo in pairs(container:GetFrames()) do
            if(frameInfo.type == "frameContainer") then addContainer(frameInfo.name,frameInfo)
            else

            end
        end
    end
    for containerId,containerInfo in pairs(self.m_layout:GetFrameContainers()) do
        addContainer(containerId,containerInfo)
    end

    local udmWindows = udmLayoutState:Add("windows")
    local primWindow = gui.get_primary_window()

    local primMonitor = gui.get_primary_monitor()
    local primVideoMode = primMonitor:GetVideoMode()
    local function add_window(name,window)
        local udmWindow = udmWindows:Add(name)
        local udmDetachedWindow = udmWindow:Add("detachedWindow")
        local pos = window:GetPos()
        local size = window:GetSize()

        pos = Vector2(pos.x /primVideoMode.width,pos.y /primVideoMode.height)
        size = Vector2(size.x /primVideoMode.width,size.y /primVideoMode.height)
        
        udmDetachedWindow:SetValue("pos",udm.TYPE_VECTOR2,pos)
        udmDetachedWindow:SetValue("size",udm.TYPE_VECTOR2,size)
    end
    add_window("main",primWindow)

    for _,frame in ipairs(frames) do
        for _,tabData in ipairs(frame:GetTabs()) do
            if(tabData.panel:IsValid()) then
                local window = tabData.panel:GetRootWindow()
                if(window ~= primWindow) then
                    add_window(tabData.panel:GetName(),window)
                end
            end
        end
    end

    if(udmData == nil) then return end

    if(saveLayout) then
        udmLayoutState:SetValue("layout",udm.TYPE_STRING,self.m_layoutFileName)
    end

    local filePath = util.Path.CreateFilePath(fileName)
	if(file.create_path(filePath:GetPath()) == false) then return end
	local f = file.open(filePath:GetString(),file.OPEN_MODE_WRITE)
	if(f == nil) then
		pfm.log("Unable to open file '" .. filePath:GetString() .. "' for writing!",pfm.LOG_CATEGORY_LAYOUT,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local res,err = udmData:SaveAscii(f) -- ,udm.ASCII_SAVE_FLAG_BIT_INCLUDE_HEADER)
	f:Close()
	if(res == false) then
		pfm.log("Failed to save layout state as '" .. filePath:GetString() .. "': " .. err,pfm.LOG_CATEGORY_LAYOUT,pfm.LOG_SEVERITY_WARNING)
		return false
	end
    return true
end

function gui.WIFilmmaker:UpdateWindowLayoutState()
	local session = self:GetSession()
	if(session == nil) then return end
	local settings = session:GetSettings()
    local layoutState = settings:GetLayoutState()
    layoutState:ClearWindows()
    layoutState:ClearContainers()
    self:SaveWindowLayoutState(layoutState:GetUdmData())
    layoutState:ReloadUdmData(layoutState:GetUdmData())

    settings:SetLayout(self.m_layoutFileName)
end
