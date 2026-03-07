-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
local ClipEditContext = util.register_class("pfm.ClipEditContext")

function ClipEditContext:__init(session, filmClips, timeLineTimeProp)
	self.m_filmClips = {}
	for _, filmClip in ipairs(filmClips) do
		table.insert(self.m_filmClips, {
			filmClip = filmClip,
			initialTimeFrame = filmClip:GetTimeFrame():Copy(),
			newTimeFrame = filmClip:GetTimeFrame():Copy()
		})
	end
	table.sort(self.m_filmClips, function(a, b)
		return a.initialTimeFrame:GetStart() < b.initialTimeFrame:GetStart()
	end)
	self.m_initialTimeLineTime = timeLineTimeProp:Get()
	self.m_newTimeLineTime = self.m_initialTimeLineTime
	self.m_timeLineTimeProperty = timeLineTimeProp

	self.m_session = session
	self.m_operations = {}
end
function ClipEditContext:AddOperation(opName)
	local op = pfm.ClipEditContext.Operation[opName](self)
	table.insert(self.m_operations, op)
end
function ClipEditContext:ClearOperations(opName)
	self.m_operations = {}
end
function ClipEditContext:ResetTimeFrames()
	self.m_newTimeLineTime = self.m_initialTimeLineTime
	for _, fcData in ipairs(self.m_filmClips) do
		fcData.newTimeFrame:SetStart(fcData.initialTimeFrame:GetStart())
		fcData.newTimeFrame:SetOffset(fcData.initialTimeFrame:GetOffset())
		fcData.newTimeFrame:SetDuration(fcData.initialTimeFrame:GetDuration())
	end
end
function ClipEditContext:FindIndex(filmClip)
	for i, fcData in ipairs(self.m_filmClips) do
		if(util.is_same_object(fcData.filmClip, filmClip)) then return i end
	end
end
function ClipEditContext:Update(filmClip, dt)
	self:ResetTimeFrames()
	local idx = self:FindIndex(filmClip)
	assert(idx ~= nil)
	for _,op in ipairs(self.m_operations) do
		op:Apply(idx, dt)
	end
	self:ClampTimeFrames()
	self:ApplyTimeFrames()
end
function ClipEditContext:ApplyTimeFrames()
	self.m_timeLineTimeProperty:Set(self.m_newTimeLineTime)
	for _, fcData in ipairs(self.m_filmClips) do
		local timeFrame = fcData.filmClip:GetTimeFrame()
		timeFrame:SetStart(fcData.newTimeFrame:GetStart())
		timeFrame:SetOffset(fcData.newTimeFrame:GetOffset())
		timeFrame:SetDuration(fcData.newTimeFrame:GetDuration())
	end
end
function ClipEditContext:ClampTimeFrames()
	self.m_newTimeLineTime = self.m_session:ClampTimeOffsetToFrameRate(self.m_newTimeLineTime)
	for _, fcData in ipairs(self.m_filmClips) do
		fcData.newTimeFrame:SetStart(self.m_session:ClampTimeOffsetToFrameRate(fcData.newTimeFrame:GetStart()))
		fcData.newTimeFrame:SetOffset(self.m_session:ClampTimeOffsetToFrameRate(fcData.newTimeFrame:GetOffset()))
		fcData.newTimeFrame:SetDuration(self.m_session:ClampTimeOffsetToFrameRate(fcData.newTimeFrame:GetDuration()))
	end
end
function ClipEditContext:ShiftAfter(index, delta)
	for i = index + 1, #self.m_filmClips do
		local fcData = self.m_filmClips[i]
		fcData.newTimeFrame:SetStart(fcData.newTimeFrame:GetStart() +delta)
	end
end
function ClipEditContext:ShiftBefore(index, delta)
	for i = 1, index - 1 do
		local fcData = self.m_filmClips[i]
		fcData.newTimeFrame:SetStart(fcData.newTimeFrame:GetStart() +delta)
	end
end
function ClipEditContext:PushUndoRedoCommand()
	local cmd = pfm.create_command("composition")
	local halfFrameDur = self:GetFrameDuration() /2.0
	local function wasChanged(oldVal, newVal)
		return math.abs(newVal -oldVal) > halfFrameDur
	end
	local hasChanges = false
	for _,fcData in ipairs(self.m_filmClips) do
		local oldStart = fcData.initialTimeFrame:GetStart()
		local newStart = fcData.newTimeFrame:GetStart()
		if(wasChanged(oldStart, newStart)) then
			cmd:AddSubCommand("set_clip_start", fcData.filmClip, oldStart, newStart)
			hasChanges = true
		end

		local oldDuration = fcData.initialTimeFrame:GetDuration()
		local newDuration = fcData.newTimeFrame:GetDuration()
		if(wasChanged(oldDuration, newDuration)) then
			cmd:AddSubCommand("set_clip_duration", fcData.filmClip, oldDuration, newDuration)
			hasChanges = true
		end

		local oldOffset = fcData.initialTimeFrame:GetOffset()
		local newOffset = fcData.newTimeFrame:GetOffset()
		if(wasChanged(oldOffset, newOffset)) then
			cmd:AddSubCommand("set_clip_offset", fcData.filmClip, oldOffset, newOffset)
			hasChanges = true
		end
	end

	if(hasChanges == false) then return end
	pfm.undoredo.push("update_clip", cmd)()
end
function ClipEditContext:SetTimeLineOffset(time) self.m_newTimeLineTime = time end
function ClipEditContext:GetTimeLineOffset() return self.m_newTimeLineTime end
function ClipEditContext:SetStart(index, start) self.m_filmClips[index].newTimeFrame:SetStart(start) end
function ClipEditContext:SetOffset(index, offset) self.m_filmClips[index].newTimeFrame:SetOffset(offset) end
function ClipEditContext:SetDuration(index, dur) self.m_filmClips[index].newTimeFrame:SetDuration(dur) end
function ClipEditContext:GetStart(index)
	if(self.m_filmClips[index] == nil) then return end
	return self.m_filmClips[index].newTimeFrame:GetStart()
end
function ClipEditContext:GetOffset(index)
	if(self.m_filmClips[index] == nil) then return end
	return self.m_filmClips[index].newTimeFrame:GetOffset()
end
function ClipEditContext:GetDuration(index)
	if(self.m_filmClips[index] == nil) then return end
	return self.m_filmClips[index].newTimeFrame:GetDuration()
end
function ClipEditContext:GetEnd(index)
	if(self.m_filmClips[index] == nil) then return end
	return self:GetStart(index) +self:GetDuration(index)
end
function ClipEditContext:GetFrameDuration() return self.m_session:GetFrameDuration() end

local Operation = util.register_class("pfm.ClipEditContext.Operation")
function Operation:__init(context)
	self.m_context = context
end
function Operation:GetFrameDuration() return self.m_context:GetFrameDuration() end

function Operation:SetTimeLineOffset(time) self.m_context:SetTimeLineOffset(time) end
function Operation:GetTimeLineOffset() return self.m_context:GetTimeLineOffset() end
function Operation:SetStart(index, start) self.m_context:SetStart(index, start) end
function Operation:SetOffset(index, offset) self.m_context:SetOffset(index, offset) end
function Operation:SetDuration(index, dur) self.m_context:SetDuration(index, dur) end
function Operation:GetStart(index) return self.m_context:GetStart(index) end
function Operation:GetEnd(index) return self.m_context:GetEnd(index) end
function Operation:GetOffset(index) return self.m_context:GetOffset(index) end
function Operation:GetDuration(index) return self.m_context:GetDuration(index) end

function Operation:IncOffset(index, offset) self.m_context:SetOffset(index, self.m_context:GetOffset(index) +offset) end
function Operation:IncStart(index, start) self.m_context:SetStart(index, self.m_context:GetStart(index) +start) end
function Operation:IncDuration(index, dur) self.m_context:SetDuration(index, self.m_context:GetDuration(index) +dur) end
function Operation:IncTimeLine(dur) self.m_context:SetTimeLineOffset(self.m_context:GetTimeLineOffset() +dur) end
function Operation:ShiftAfter(index, delta) self.m_context:ShiftAfter(index, delta) end
function Operation:ShiftBefore(index, delta) self.m_context:ShiftBefore(index, delta) end

function Operation:ClampDeltaLowerBound(delta, baseValue, lowerBound, frameMargin)
	if(lowerBound == nil) then return delta end
	local newVal = baseValue +delta
	if(frameMargin ~= false) then lowerBound = lowerBound +self:GetFrameDuration() end
	newVal = math.max(newVal, lowerBound)
	return newVal -baseValue
end

function Operation:ClampDeltaUpperBound(delta, baseValue, upperBound, frameMargin)
	if(upperBound == nil) then return delta end
	local newVal = baseValue +delta
	if(frameMargin ~= false) then upperBound = upperBound -self:GetFrameDuration() end
	newVal = math.min(newVal, upperBound)
	return newVal -baseValue
end

local RippleTrimIn = util.register_class("pfm.ClipEditContext.Operation.RippleTrimIn", Operation)
function RippleTrimIn:__init(context)
	Operation.__init(self, context)
end
function RippleTrimIn:Apply(curIdx, delta)
	delta = self:ClampDeltaUpperBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx))
	self:IncDuration(curIdx, -delta)
	self:IncTimeLine(-delta)
	self:ShiftAfter(curIdx, -delta)
	return delta
end

local RippleTrimOut = util.register_class("pfm.ClipEditContext.Operation.RippleTrimOut", Operation)
function RippleTrimOut:__init(context)
	Operation.__init(self, context)
end
function RippleTrimOut:Apply(curIdx, delta)
	delta = self:ClampDeltaLowerBound(delta, self:GetEnd(curIdx), self:GetStart(curIdx))
	self:IncDuration(curIdx, delta)
	self:ShiftAfter(curIdx, delta)
	return delta
end

local RippleSlipTrimIn = util.register_class("pfm.ClipEditContext.Operation.RippleSlipTrimIn", Operation)
function RippleSlipTrimIn:__init(context)
	Operation.__init(self, context)
end
function RippleSlipTrimIn:Apply(curIdx, delta)
	delta = self:ClampDeltaUpperBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx))
	
	self:IncDuration(curIdx, -delta)
	self:IncTimeLine(-delta)
	self:IncOffset(curIdx, delta)
	self:ShiftAfter(curIdx, -delta)
end

local RippleSlipTrimOut = util.register_class("pfm.ClipEditContext.Operation.RippleSlipTrimOut", Operation)
function RippleSlipTrimOut:__init(context)
	Operation.__init(self, context)
end
function RippleSlipTrimOut:Apply(curIdx, delta)
	delta = self:ClampDeltaLowerBound(delta, self:GetEnd(curIdx), self:GetStart(curIdx))
	
	self:IncDuration(curIdx, delta)
	self:IncOffset(curIdx, -delta)
	self:ShiftAfter(curIdx, delta)
end

local SlipTrimIn = util.register_class("pfm.ClipEditContext.Operation.SlipTrimIn", Operation)
function SlipTrimIn:__init(context)
	Operation.__init(self, context)
end
function SlipTrimIn:Apply(curIdx, delta)
	delta = self:ClampDeltaLowerBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx -1), false)
	delta = self:ClampDeltaUpperBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx))
	
	self:IncStart(curIdx, delta)
	self:IncDuration(curIdx, -delta)
	self:IncOffset(curIdx, delta)
end

local TrimOut = util.register_class("pfm.ClipEditContext.Operation.TrimOut", Operation)
function TrimOut:__init(context)
	Operation.__init(self, context)
end
function TrimOut:Apply(curIdx, delta)
	delta = self:ClampDeltaLowerBound(delta, self:GetEnd(curIdx), self:GetStart(curIdx))
	delta = self:ClampDeltaUpperBound(delta, self:GetEnd(curIdx), self:GetStart(curIdx +1), false)

	self:IncDuration(curIdx, delta)
end

local RippleSlide = util.register_class("pfm.ClipEditContext.Operation.RippleSlide", Operation)
function RippleSlide:__init(context)
	Operation.__init(self, context)
end
function RippleSlide:Apply(curIdx, delta)
	delta = self:ClampDeltaLowerBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx -1), false)

	self:IncStart(curIdx, delta)
	self:ShiftAfter(curIdx, delta)
end

local BackRippleSlide = util.register_class("pfm.ClipEditContext.Operation.BackRippleSlide", Operation)
function BackRippleSlide:__init(context)
	Operation.__init(self, context)
end
function BackRippleSlide:Apply(curIdx, delta)
	delta = self:ClampDeltaUpperBound(delta, self:GetEnd(curIdx), self:GetStart(curIdx +1), false)

	self:IncStart(curIdx, delta)
	self:ShiftBefore(curIdx, delta)
end

local RollSlip = util.register_class("pfm.ClipEditContext.Operation.RollSlip", Operation)
function RollSlip:__init(context)
	Operation.__init(self, context)
end
function RollSlip:Apply(curIdx, delta)
	local prevIdx = curIdx -1
	if(delta < 0) then
		-- Clamp to start of previous clip
		delta = self:ClampDeltaLowerBound(delta, self:GetEnd(prevIdx), self:GetStart(prevIdx))
	else
		-- Clamp to end of next clip
		delta = self:ClampDeltaUpperBound(delta, self:GetStart(curIdx), self:GetEnd(curIdx))
	end
	self:IncDuration(prevIdx, delta)

	self:IncStart(curIdx, delta)
	self:IncOffset(curIdx, delta)
	self:IncDuration(curIdx, -delta)
end
