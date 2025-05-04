include("../base_editor.lua")
include("/pfm/project_manager.lua")
include("/util/retarget.lua")

local Element = util.register_class("gui.WIBaseFilmmaker", gui.WIBaseEditor, pfm.ProjectManager)

include("global_state_data.lua")
include("layout.lua")
include("misc.lua")
include("io.lua")
include("restore.lua")
include("/gui/pfm/theme_toggle.lua")

function Element:__init()
	gui.WIBaseEditor.__init(self)
	pfm.ProjectManager.__init(self)

	pfm.set_project_manager(self)
end
function Element:ShowLoadingScreen(enabled, loadText)
	return pfm.show_loading_screen(enabled, loadText)
end
function Element:GetRightMenuBarContents()
	return self.m_menuBarRightContents
end
function Element:AddVersionInfo(identifier, version, gitInfoPath)
	local pMenuBarContents = self:GetMenuBarContainer()

	local elRightContents = gui.create("WIHBox", pMenuBarContents)
	self.m_menuBarRightContents = elRightContents
	local function update_size()
		elRightContents:SetX(pMenuBarContents:GetWidth() - elRightContents:GetWidth())
	end
	pMenuBarContents:AddCallback("SetSize", update_size)
	elRightContents:AddCallback("SetSize", update_size)

	-- Version Info
	local engineInfo = engine.get_info()
	local versionString = "v" .. version
	local sha = pfm.get_git_sha(gitInfoPath)
	if sha ~= nil then
		versionString = versionString .. ", " .. sha
	end
	versionString = versionString .. " [P " .. engineInfo.prettyVersion
	local gitInfo = engine.get_git_info()
	if gitInfo ~= nil then
		-- Pragma SHA
		versionString = versionString .. ", " .. gitInfo.commitSha:sub(0, 7)
	end
	versionString = versionString .. "]"
	local elVersion = gui.create("WIText", elRightContents)
	elVersion:SetColor(Color.White)
	elVersion:SetText(versionString)
	elVersion:SetFont("pfm_medium")
	elVersion:SizeToContents()
	elVersion:SetCursor(gui.CURSOR_SHAPE_HAND)
	elVersion:SetMouseInputEnabled(true)
	elVersion:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			util.set_clipboard_string(elVersion:GetText())
			pfm.create_popup_message(locale.get_text("pfm_version_copied_to_clipboard"), 3)
			return util.EVENT_REPLY_HANDLED
		end
	end)
	elVersion:AddCallback("OnCursorEntered", function()
		elVersion:AddStyleClass("text_highlight")
		elVersion:RefreshSkin()
	end)
	elVersion:AddCallback("OnCursorExited", function()
		elVersion:RemoveStyleClass("text_highlight")
		elVersion:RefreshSkin()
	end)

	elVersion:SetY(3)
	log.info(identifier .. " Version: " .. versionString)

	local elGap = gui.create("WIBase", elRightContents)
	elGap:SetSize(5, 1)

	local elBeta = gui.create("WIText")
	elBeta:SetParent(elRightContents, 0)
	elBeta:AddStyleClass("beta_info")
	elBeta:SetText("BETA | ")
	elBeta:SetFont("pfm_medium")
	elBeta:SetY(3)
	elBeta:SizeToContents()

	local el = gui.create("WIBase", elRightContents)
	el:SetSize(32, pMenuBarContents:GetHeight())
	el:SetParent(elRightContents, 0)

	local elToggle = gui.create("WIPFMThemeToggle", el)
	elToggle:CenterToParent()
end
function Element:GetWorldAxesGizmo()
	return self.m_worldAxesGizmo
end
function Element:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
	pfm.ProjectManager.OnRemove(self)
	if self.m_playbackState ~= nil then
		self.m_playbackState:Reset()
	end
	self.m_selectionManager:Remove()
	util.remove(self.m_worldAxesGizmo)
	util.remove(self.m_cbOnRenderTargetResized)
end
function Element:GetViewport() end
function Element:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)
	self:LoadGlobalStateData()

	self.m_worldAxesGizmo = ents.create("pfm_world_axes_gizmo")
	self.m_worldAxesGizmo:Spawn()

	self:InitializeBindingLayers()

	self.m_cbOnRenderTargetResized = game.add_callback("OnRenderTargetResized", function()
		local vp = self:GetViewport()
		if util.is_valid(vp) then
			vp:UpdateAspectRatio()
		end
	end)
end
function Element:IsEditor()
	return false
end
function Element:InitializeSelectionManager()
	self.m_selectionManager = pfm.ActorSelectionManager()
	self.m_selectionManager:AddChangeListener(function(ent, selected)
		self:OnActorSelectionChanged(ent, selected)
	end)
end
function Element:GetSelectionManager()
	return self.m_selectionManager
end
function Element:SetOverlaySceneEnabled(enabled) end
function Element:GetPlaybackState()
	return self.m_playbackState
end
function Element:GetTimeProperty()
	return self.m_timeOffset
end
function Element:InitializePlaybackState()
	self.m_timeOffset = util.FloatProperty(0.0)
	self.m_timeOffset:AddCallback(function(oldOffset, offset)
		if self.m_updatingProjectTimeOffset ~= true then
			self:SetTimeOffset(offset)
		end
	end)

	if self.m_playbackState ~= nil then
		self.m_playbackState:Reset()
	end
	self.m_playbackState = pfm.util.PlaybackState()
	self.m_playbackState:AddCallback("OnTimeAdvance", function(dt)
		self:SetTimeOffset(self:GetTimeOffset() + dt)
	end)
	self.m_playbackState:AddCallback("OnStateChanged", function(oldState, state)
		ents.PFMSoundSource.set_audio_enabled(state == pfm.util.PlaybackState.STATE_PLAYING)
		if state == pfm.util.PlaybackState.STATE_PAUSED then
			-- On pause, move to the closest whole frame
			self:ClampTimeOffsetToFrame()
		end
	end)
end
function Element:OpenBoneRetargetWindow(mdlSrc, mdlDst)
	local mdlSrcPath = (type(mdlSrc) == "string") and mdlSrc or mdlSrc:GetName()
	if type(mdlSrc) == "string" then
		mdlSrc = game.load_model(mdlSrc)
		if mdlSrc == nil then
			return
		end
	end
	if type(mdlDst) == "string" then
		mdlDst = game.load_model(mdlDst)
		if mdlDst == nil then
			return
		end
	end
	if mdlSrc == nil or mdlDst == nil then
		return
	end
	local rig = ents.RetargetRig.Rig.load(mdlSrc, mdlDst)
	if rig == false then
		rig = ents.RetargetRig.Rig(mdlSrc, mdlDst)

		-- local boneRemapper = ents.RetargetRig.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		-- local translationTable = boneRemapper:AutoRemap()
		-- rig:SetTranslationTable(translationTable)
		rig:SetDstToSrcTranslationTable({})
	end
	local tab, el = self:OpenWindow("bone_retargeting", true)
	if util.is_valid(el) then
		el:SetModelTargets(mdlSrc, mdlDst)
		util.remove(self.m_cbRigSaved)
		self.m_cbRigSaved = el:AddCallback("OnRigSaved", function(el, rig)
			-- TODO: Only update retarget rigs with matching models
			for ent, c in ents.citerator(ents.COMPONENT_IMPOSTOR) do
				c:OnAnimationReset()
			end
			pfm.tag_render_scene_as_dirty()
		end)
	end

	self:OpenModelView(mdlSrcPath)
	if util.is_valid(self.m_mdlView) then
		el:LinkToModelView(self.m_mdlView)
		el:InitializeModelView()
		local entSrc = self.m_mdlView:GetEntity(1)
		local entDst = self.m_mdlView:GetEntity(2)
		if util.is_valid(entSrc) and util.is_valid(entDst) then
			local retargetC = entDst:AddComponent("retarget_rig")
			local animSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
			if retargetC ~= nil and animSrc ~= nil then
				retargetC:SetRig(rig, animSrc)
			end

			local retargetMorphC = entDst:AddComponent("retarget_morph")
			local flexC = entSrc:GetComponent(ents.COMPONENT_FLEX)
			if retargetMorphC ~= nil and flexC ~= nil then
				retargetMorphC:SetRig(rig, flexC)
			end
		end
	end
	if util.is_valid(el) then
		el:SetModelTargets(mdlSrc, mdlDst)
	end
end
function Element:GetAvailableRetargetImpostorModels(actor)
	local targetActor = actor
	local imposterC = actor:GetComponent("impostor")
	if imposterC ~= nil then
		local impersonatee = imposterC:GetImpersonatee()
		if util.is_valid(impersonatee) then
			targetActor = impersonatee:GetEntity()
		end
	end
	if util.is_valid(targetActor) == false then
		return
	end
	return ents.RetargetRig.Rig.find_available_retarget_impostor_models(targetActor:GetModel())
end
function Element:RetargetActor(targetActor, mdlName)
	if targetActor:GetComponent(ents.COMPONENT_PANIMA) == nil then
		pfm.create_popup_message(locale.get_text("pfm_retarget_failed_not_animated"), 4, gui.InfoBox.TYPE_WARNING)
		return
	end
	local res, targetActor, srcModelName = util.retarget.retarget_actor(targetActor, mdlName)
	if res == true or targetActor == nil then
		return
	end
	self:OpenBoneRetargetWindow(srcModelName, mdlName)
	if util.is_valid(self.m_mdlView) then
		local ent = self.m_mdlView:GetEntity(1)
		if util.is_valid(ent) then
			local entActor = targetActor
			local entTarget = ent

			local animCActor = entActor:GetComponent(ents.COMPONENT_PANIMA)
			local animCTarget = entTarget:AddComponent(ents.COMPONENT_PANIMA)

			local animManagerActor = animCActor:GetAnimationManager("pfm")
			local anim = animManagerActor:GetCurrentAnimation()

			local animManagerTarget = animCTarget:AddAnimationManager("pfm")
			animCTarget:PlayAnimation(animManagerTarget, anim)
			animManagerTarget:GetPlayer():SetLooping(true)
		end
	end
end
function Element:ShowMatureContentPrompt(onYes, onNo)
	if console.get_convar_bool("pfm_web_browser_enable_mature_content") then
		onYes()
		return
	end
	local ctrl, wrapper
	local msg = pfm.open_message_prompt(
		locale.get_text("pfm_content_warning"),
		locale.get_text("pfm_content_warning_website"),
		bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO),
		function(bt)
			if bt == gui.PfmPrompt.BUTTON_YES then
				if ctrl:IsChecked() then
					console.run("pfm_web_browser_enable_mature_content", "1")
				end
				onYes()
			elseif bt == gui.PfmPrompt.BUTTON_NO then
				if onNo ~= nil then
					onNo()
				end
			end
		end
	)
	local userContents = msg:GetUserContents()

	local p = gui.create("WIPFMControlsMenu", userContents)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)

	ctrl, wrapper = p:AddToggleControl(pfm.LocStr("pfm_remember_my_choice"), "remember_my_choice", false)
	p:SetWidth(200)
	p:Update()
	p:SizeToContents()
	p:ResetControls()

	gui.create("WIBase", userContents, 0, 0, 1, 12) -- Gap
end
function Element:AddProgressStatusBar(identifier, text)
	local infoBar = self:GetInfoBar()

	local statusBar = gui.create("WIProgressStatusInfo")
	statusBar:SetName("status_info_" .. identifier)
	statusBar:SetText(text)
	statusBar:SetProgress(0.0)
	statusBar:SetHeight(infoBar:GetHeight())
	statusBar:AddCallback("OnRemove", function()
		if infoBar:IsValid() then
			infoBar:ScheduleUpdate()
		end
	end)
	infoBar:AddRightElement(statusBar, 0)

	infoBar:Update()
	return statusBar
end
