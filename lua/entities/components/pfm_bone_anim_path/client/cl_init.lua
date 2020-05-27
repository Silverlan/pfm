--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_lines.lua")
include("/shaders/pfm/pfm_sprite.lua")

util.register_class("ents.PFMBoneAnimPath",BaseEntityComponent)

function ents.PFMBoneAnimPath:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local colorC = self:AddEntityComponent(ents.COMPONENT_COLOR)
	if(colorC ~= nil) then colorC:SetColor(Color.White) end

	self.m_shaderLines = shader.get("pfm_lines")
	self.m_shaderSprite = shader.get("pfm_sprite")
end

function ents.PFMBoneAnimPath:OnRemove()
	if(util.is_valid(self.m_cbRender)) then self.m_cbRender:Remove() end
	if(util.is_valid(self.m_cbPlayOffset)) then self.m_cbPlayOffset:Remove() end
end

function ents.PFMBoneAnimPath:Setup(boneName,session,filmClip)
	if(util.is_valid(self.m_cbRender)) then self.m_cbRender:Remove() end
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	local mdl = (mdlC ~= nil) and mdlC:GetModel() or nil
	local animChannelTrack = filmClip:FindAnimationChannelTrack()

	local actorC = ent:GetComponent("pfm_actor")
	local actorData = (actorC ~= nil) and actorC:GetActorData() or nil
	local mdlCData = (actorData ~= nil) and actorData:FindComponent("pfm_model") or nil

	if(mdl == nil or animChannelTrack == nil or mdlCData == nil) then return end
	local skeleton = mdl:GetSkeleton()
	local boneId = (type(boneName) == "string") and mdl:LookupBone(boneName) or boneName
	if(boneId == -1) then return end
	local timeFrame = filmClip:GetTimeFrame()
	--local startTime = timeFrame:GetOffset() +timeFrame:GetStart() -2.6692 -- Channel clip timeframe!
	--local endTime = startTime +timeFrame:GetDuration()

	local startTime = timeFrame:GetOffset() +timeFrame:GetStart()
	local endTime = startTime +timeFrame:GetDuration()

	local startFrame = math.round(session:TimeOffsetToFrameOffset(startTime))
	local endFrame = math.round(session:TimeOffsetToFrameOffset(endTime))

	local points = {}
	self.m_maxTime = 0.0
	self.m_session = session
	self.m_filmClip = filmClip
	for frame=startFrame,endFrame do
		local t = session:FrameOffsetToTimeOffset(frame)
		local pose = phys.ScaledTransform()
		local bone = skeleton:GetBone(boneId)
		while(bone ~= nil) do
			local bonePose = mdlCData:CalcBonePose(animChannelTrack,bone:GetName(),t)
			pose = bonePose *pose

			bone = bone:GetParent()
		end
		table.insert(points,{pose:GetOrigin(),t,frame})

		if(frame == endFrame) then self.m_maxTime = t end
	end
	-- TODO: Clamp max time to maximum time in channel clips
	self.m_linePoints = points

	local dsPoints = util.DataStream(util.SIZEOF_VECTOR3 *#points)
	for _,p in ipairs(points) do
		dsPoints:WriteVector(p[1])
	end
	self.m_bufPoints = prosper.util.allocate_temporary_buffer(dsPoints)

	self.m_cbRender = game.add_callback("Render",function()
		self:Render()
	end)

	self.m_cbPlayOffset = session:GetSettings():GetPlayheadOffsetAttr():AddChangeListener(function(newOffset)
		self:SetActiveTimeOffset(newOffset)
	end)
	self:SetActiveTimeOffset(session:GetSettings():GetPlayheadOffset())
end

function ents.PFMBoneAnimPath:SetActiveTimeOffset(offset)
	if(self.m_session == nil or self.m_filmClip == nil) then return end
	offset = self.m_filmClip:LocalizeTimeOffset(offset)
	self.m_activeFrame = math.round(self.m_session:TimeOffsetToFrameOffset(offset))
end

function ents.PFMBoneAnimPath:Render()
	if(self.m_shaderLines == nil or self.m_shaderSprite == nil or self.m_bufPoints == nil or self.m_linePoints == nil) then return end
	local drawCmd = game.get_draw_command_buffer()
	local cam = game.get_render_scene_camera()
	local M = math.Mat4()
	local V = cam:GetViewMatrix()
	local P = cam:GetProjectionMatrix()
	local mvp = P *V *M
	-- Draw lines
	self.m_shaderLines:Draw(drawCmd,self.m_bufPoints,#self.m_linePoints,mvp)

	-- Draw sprites
	local res = engine.get_render_resolution()
	local dt = time.real_time()
	dt = dt %self.m_maxTime
	for i,p in ipairs(self.m_linePoints) do
		local t = p[2]
		local frame = p[3]

		local defaultSpriteSize = 7.5
		local enlargedSpriteSize = 10.0

		local defaultSpriteAlpha = 0.75 *255.0
		local enlargedSpriteAlpha = 1 *255.0

		local spriteEnlargedDuration = 0.25

		local scale = defaultSpriteSize
		local color = Color.Lime:Copy()

		local a = defaultSpriteAlpha
		if(self.m_activeFrame == frame) then
			color = Color.DodgerBlue:Copy()
			scale = scale +(enlargedSpriteSize -defaultSpriteSize)
			a = a +(enlargedSpriteAlpha -defaultSpriteAlpha)
		elseif(dt >= t) then
			local interp = 1.0 -math.clamp((dt -t) /spriteEnlargedDuration,0.0,1.0)
			scale = scale +math.lerp(0.0,enlargedSpriteSize -defaultSpriteSize,interp)
			color = color:Lerp(Color.Red,interp)
			a = a +math.lerp(0.0,enlargedSpriteAlpha -defaultSpriteAlpha,interp)
		end
		color.a = a
		self.m_shaderSprite:Draw(drawCmd,p[1],Vector2(scale /res.x,scale /res.y),color,mvp)
	end
end
ents.COMPONENT_PFM_BONE_ANIM_PATH = ents.register_component("pfm_bone_anim_path",ents.PFMBoneAnimPath)
