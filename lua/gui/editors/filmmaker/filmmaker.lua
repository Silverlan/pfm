include("/dmx_scene/dmx_scene_loader.lua")

include("../base_editor.lua")

util.register_class("gui.WIFilmmaker",gui.WIBaseEditor)

include("/gui/witabbedpanel.lua")
include("/gui/editors/wieditorwindow.lua")

locale.load("filmmaker.txt")

function gui.WIFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
end
function gui.WIFilmmaker:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
end
function gui.WIFilmmaker:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)
	
	self:SetSize(1280,1024)
	local pMenuBar = self:GetMenuBar()
	pMenuBar:AddItem(locale.get_text("file"),function(pContext)
		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			print("Loading... test22")
			local scene = import.import_dmx_scene("lua/demo/scenes/sfm/mtt_engineer.dmx",-Vector(2830.19,513.205,4.41247) +Vector(1682,-180,-161))
			if(scene == nil) then print("Unable to load scene...") return end
		end)
		pContext:AddItem(locale.get_text("import") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			
		end)
		pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			
		end)
		pContext:AddItem(locale.get_text("exit"),function(pItem)
			if(util.is_valid(self) == false) then return end
			tool.close_filmmaker()
		end)
		pContext:Update()
	end)
	pMenuBar:AddItem(locale.get_text("edit"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("windows"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("view"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("help"),function(pContext)

	end)
	
	local pMainGridPanel = gui.create("WIGridPanel",self)
	pMainGridPanel:SetY(pMenuBar:GetBottom())
	pMainGridPanel:SetSize(self:GetWidth(),self:GetHeight() -pMenuBar:GetBottom())
	pMainGridPanel:SetAnchor(0,0,1,1)
	
	local pWindow = self:CreateWindow()
	pMainGridPanel:AddItem(pWindow:GetFrame(),1,0)
	pWindow:SetSize(128,512)
	pWindow:GetFrame():SetTitle("!!!")
	pWindow:GetFrame():SetSize(128,512)
	pWindow:GetFrame():SetDraggable(false)
	
	local pTab = pWindow:AddTab("HELLO")
	local pTab2 = pWindow:AddTab("BYE")
	pWindow:Update()
	
	--[[local pViewport = gui.create("WIViewport",pWindow)
	pViewport:SetColor(Color.Aqua)
	pViewport:SetSize(128,128)
	pMainGridPanel:AddItem(pViewport,2,0)]]
	
	
	--EDITOR WINDOW:
	--WIFRAME +TABBED VIEW
end
gui.register("WIFilmmaker",gui.WIFilmmaker)
