--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.AnimationRecorder")
function pfm.AnimationRecorder:__init(actor,filmClip)
	self.m_actor = actor
	self.m_filmClip = filmClip
end

function pfm.AnimationRecorder:Clear()
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove() end
end

function pfm.AnimationRecorder:GetActor() return self.m_actor end
function pfm.AnimationRecorder:GetFilmClip() return self.m_filmClip end
function pfm.AnimationRecorder:GetFilmmaker() return tool.get_filmmaker() end

function pfm.AnimationRecorder:OnComplete(anim)
	self:ExportAnimation()
	self:Clear()
end

function pfm.AnimationRecorder:ExportAnimation()
	local actor = self:GetActor()
	local mdl = self.m_model
	local animName = "pfm_export"
	mdl:AddAnimation(animName,self.m_anim)

	local exportInfo = game.Model.ExportInfo()
	exportInfo.verbose = false
	exportInfo.generateAo = false
	exportInfo.exportAnimations = true
	exportInfo.exportSkinnedMeshData = true
	exportInfo.exportImages = true
	exportInfo.exportMorphTargets = true
	exportInfo.enableExtendedDDS = false
	exportInfo.saveAsBinary = false
	exportInfo.verbose = true
	exportInfo.imageFormat = game.Model.ExportInfo.IMAGE_FORMAT_PNG
	exportInfo.embedAnimations = true
	exportInfo.fullExport = false
	exportInfo.scale = 1.0
	exportInfo:SetAnimationList({animName})

	local result,err = mdl:Export(exportInfo)--mdl:ExportAnimation(animName,exportInfo)
	if(result) then exportSuccessful = true
	else console.print_warning("Unable to export animation: ",err) end

	local path = mdl:GetName()
	util.open_path_in_explorer("export/" .. file.remove_file_extension(path))
end

function pfm.AnimationRecorder:RecordFrame()
	local filmClip = self:GetFilmClip()
	local filmmaker = self:GetFilmmaker()
	local actor = self:GetActor()

	local timeFrame = filmClip:GetTimeFrame()
	if(filmmaker:GetTimeOffset() >= timeFrame:GetEnd()) then
		self:OnComplete(self.m_anim)
		return
	end

	if(util.is_valid(actor) == false) then return end
	local animC = actor:GetComponent(ents.COMPONENT_ANIMATED)
	local flexC = actor:GetComponent(ents.COMPONENT_FLEX)

	local frame = game.Model.Animation.Frame.Create(self.m_numBones)
	if(util.is_valid(flexC)) then
		local flexControllerWeights = {}
		for i=0,self.m_model:GetFlexControllerCount() -1 do
			flexControllerWeights[i] = flexC:GetFlexController(i)
		end
		frame:SetFlexControllerWeights(flexControllerWeights)
	end

	for i=0,self.m_numBones -1 do
		local pose = animC:GetBonePose(i)
		if(i == 0) then
			pose:SetOrigin(Vector()) -- TODO
		end
		frame:SetBoneTransform(i,pose:GetOrigin(),pose:GetRotation())
	end
	self.m_anim:AddFrame(frame)
end

function pfm.AnimationRecorder:StartRecording()
	local filmmaker = self:GetFilmmaker()
	local actor = self:GetActor()
	local filmClip = self:GetFilmClip()
	local renderC = actor:GetComponent(ents.COMPONENT_RENDER)
	local animC = actor:GetComponent(ents.COMPONENT_ANIMATED)
	local mdl = actor:GetModel()
	if(renderC == nil or animC == nil or mdl == nil) then return false end

	local skeleton = mdl:GetSkeleton()
	local numBones = skeleton:GetBoneCount()

	--[[for k,v in pairs(skeleton:GetRootBones()) do
		local pose = animC:GetBonePose(v:GetID())
		print(pose)
	end]]

	self.m_anim = game.Model.Animation.Create()
	self.m_model = mdl

	local boneList = {}
	for i=0,numBones -1 do
		table.insert(boneList,i)
	end
	self.m_numBones = numBones
	self.m_anim:SetBoneList(boneList)
	self.m_anim:SetFPS(filmmaker:GetFrameRate())

	local timeFrame = filmClip:GetTimeFrame()
	filmmaker:SetTimeOffset(timeFrame:GetStart())

	local tDelta = 1 /30.0
	self.m_tNextFrame = time.real_time() +tDelta
	self.m_cbThink = game.add_callback("Think",function()
		local t = time.real_time()
		if(t < self.m_tNextFrame) then return end
		self:RecordFrame()
		filmmaker:GoToNextFrame()

		self.m_tNextFrame = t +tDelta
	end)
end
