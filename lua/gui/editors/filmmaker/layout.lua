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
        frame = frameContainer,
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
        elContents:SetAutoFillContents(true)

        local frames = {}
        local dividers = {}
        local first = true
        local resizerRatio = 0.25
        for _,frameData in ipairs(container:GetFrames()) do
            if(first) then
                first = false
            else
                local resizer = gui.create("WIResizer",elContents)
                resizer:SetFraction(resizerRatio)
                table.insert(dividers,resizer)
            end
            resizerRatio = frameData.defaultRatio or 0.5
            if(frameData.type == "frameContainer") then
                addFrameContainer(frameData.name,frameData.frame,elContents)
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
    self:InitializeProjectUI(fileName)
end
