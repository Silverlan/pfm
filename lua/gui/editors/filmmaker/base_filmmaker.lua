--[[
    Copyright (C) 2020  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../base_editor.lua")
include("/pfm/project_manager.lua")

util.register_class("gui.WIBaseFilmmaker",gui.WIBaseEditor,pfm.ProjectManager)
function gui.WIBaseFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
	pfm.ProjectManager.__init(self)

	pfm.set_project_manager(self)
end
function gui.WIBaseFilmmaker:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
	pfm.ProjectManager.OnRemove(self)
end
function gui.WIBaseFilmmaker:OnInitialize() gui.WIBaseEditor.OnInitialize(self) end
function gui.WIBaseFilmmaker:OpenBoneRetargetWindow(mdlSrc,mdlDst)
	local mdlSrcPath = (type(mdlSrc) == "string") and mdlSrc or mdlSrc:GetName()
	mdlSrc = (type(mdlSrc) == "string") and game.load_model(mdlSrc) or mdlSrc
	mdlDst = (type(mdlDst) == "string") and game.load_model(mdlDst) or mdlDst
	if(mdlSrc == nil or mdlDst == nil) then return end
	local rig = ents.RetargetRig.Rig.load(mdlSrc,mdlDst)
	if(rig == false) then
		rig = ents.RetargetRig.Rig(mdlSrc,mdlDst)

		-- local boneRemapper = ents.RetargetRig.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		-- local translationTable = boneRemapper:AutoRemap()
		-- rig:SetTranslationTable(translationTable)
		rig:SetDstToSrcTranslationTable({})
	end
	local tab,el = self:OpenWindow("bone_retargeting",true)
	if(util.is_valid(el)) then
		el:SetModelTargets(mdlSrc,mdlDst)
		util.remove(self.m_cbRigSaved)
		self.m_cbRigSaved = el:AddCallback("OnRigSaved",function(el,rig)
			-- TODO: Only update retarget rigs with matching models
			for ent,c in ents.citerator(ents.COMPONENT_IMPOSTOR) do
				c:OnAnimationReset()
			end
			pfm.tag_render_scene_as_dirty()
		end)
	end

	self:OpenModelView(mdlSrcPath)
	if(util.is_valid(self.m_mdlView)) then
		el:LinkToModelView(self.m_mdlView)
		el:InitializeModelView()
		local entSrc = self.m_mdlView:GetEntity(1)
		local entDst = self.m_mdlView:GetEntity(2)
		if(util.is_valid(entSrc) and util.is_valid(entDst)) then
			local retargetC = entDst:AddComponent("retarget_rig")
			local animSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
			if(retargetC ~= nil and animSrc ~= nil) then retargetC:SetRig(rig,animSrc) end

			local retargetMorphC = entDst:AddComponent("retarget_morph")
			local flexC = entSrc:GetComponent(ents.COMPONENT_FLEX)
			if(retargetMorphC ~= nil and flexC ~= nil) then retargetMorphC:SetRig(rig,flexC) end
		end
	end
	if(util.is_valid(el)) then
		el:SetModelTargets(mdlSrc,mdlDst)
	end
end
function gui.WIBaseFilmmaker:GetAvailableRetargetImpostorModels(actor)
	local targetActor = actor
	local imposterC = actor:GetComponent("impostor")
	if(imposterC ~= nil) then
		local impersonatee = imposterC:GetImpersonatee()
		if(util.is_valid(impersonatee)) then targetActor = impersonatee:GetEntity() end
	end
	if(util.is_valid(targetActor) == false) then return end
	return ents.RetargetRig.Rig.find_available_retarget_impostor_models(targetActor:GetModel())
end
function gui.WIBaseFilmmaker:GetImpersonatee(actor)
	local targetActor = actor
	local imposterC = actor:GetComponent("impostor")
	if(imposterC ~= nil) then
		local impersonatee = imposterC:GetImpersonatee()
		if(util.is_valid(impersonatee)) then targetActor = impersonatee:GetEntity() end
	end
	return targetActor
end
function gui.WIBaseFilmmaker:ChangeActorModel(actorC,mdlName)
	console.run("asset_clear_unused") -- Clear all unused assets, so we don't run into memory issues
	actorC:SetDefaultRenderMode(game.SCENE_RENDER_PASS_WORLD)

	local impersonateeC = actorC:GetEntity():AddComponent("impersonatee")
	if(impersonateeC == nil) then return end
	impersonateeC:SetImpostorModel(mdlName)

	local impostorC = impersonateeC:GetImpostor()
	if(util.is_valid(impostorC) == false) then return end
	local entImpostor = impostorC:GetEntity()

	local impersonated = impersonateeC:IsImpersonated()
	actorC:SetDefaultRenderMode(impersonated and game.SCENE_RENDER_PASS_NONE or game.SCENE_RENDER_PASS_WORLD)

	local entActor = actorC:GetEntity()
	if(entActor:HasComponent("click")) then entImpostor:AddComponent("click") end

	-- TODO: We shouldn't need this!
	local renderC = entImpostor:GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:SetExemptFromOcclusionCulling(true) end

	self:OnActorModelChanged(entActor,entImpostor)

	if(impersonated == false) then actorC:GetEntity():SetPose(actorC:GetEntity():GetPose()) end -- We have to reset the actor's pose, I'm not sure why

	local vpFlexControllers = self:GetWindow("flex_controllers")
	if(util.is_valid(vpFlexControllers)) then vpFlexControllers:ReloadSettings() end
	return entImpostor
end
function gui.WIBaseFilmmaker:OnActorModelChanged(entActor,entImpostor) end
function gui.WIBaseFilmmaker:RetargetActor(targetActor,mdlName)
	targetActor = self:GetImpersonatee(targetActor)
	if(util.is_valid(targetActor) == false) then return end
	local srcModelName = targetActor:GetModelName()

	local skeleton = true
	local flexController = true
	local headControllerC = targetActor:GetComponent(ents.COMPONENT_HEAD_CONTROLLER)
	local headTarget = (headControllerC ~= nil) and headControllerC:GetHeadTarget() or nil
	if(util.is_valid(headTarget)) then
		local headModel = headTarget:GetModelName()
		if(#headModel > 0) then
			-- Flex retargeting uses a different head model, so we'll try to retarget that first.
			-- We don't care about the result. If it fails, flexes will not work unless retargeted manually.
			if(file.exists(ents.RetargetRig.Rig.get_rig_file_path(headModel,mdlName):GetString()) == false) then
				ents.RetargetRig.Rig.find_and_import_viable_retarget_rig(headModel,mdlName,false,true)
			end
			flexController = false
		end
	end
	local res = file.exists(ents.RetargetRig.Rig.get_rig_file_path(srcModelName,mdlName):GetString())
	if(res == false) then
		res = ents.RetargetRig.Rig.find_and_import_viable_retarget_rig(srcModelName,mdlName,skeleton,flexController)
	end
	if(res) then
		local actorC = targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if(actorC ~= nil) then self:ChangeActorModel(actorC,mdlName) end
		return
	end
	self:OpenBoneRetargetWindow(srcModelName,mdlName)
	if(util.is_valid(self.m_mdlView)) then
		local ent = self.m_mdlView:GetEntity(1)
		if(util.is_valid(ent)) then
			ent:PlayAnimation(targetActor:GetAnimation())
		end
	end
end
