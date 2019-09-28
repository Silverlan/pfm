util.register_class("ents.PFMActorComponent",BaseEntityComponent)

util.register_class("ents.PFMActorComponent.Channel")
function ents.PFMActorComponent.Channel:__init()
	self.m_transforms = {}
end
function ents.PFMActorComponent.Channel:AddTransform(controllerId,time,value)
	self.m_transforms[controllerId] = self.m_transforms[controllerId] or {}
	table.insert(self.m_transforms[controllerId],{time,value})
end
function ents.PFMActorComponent.Channel:GetTransforms() return self.m_transforms end
function ents.PFMActorComponent.Channel:GetInterpolatedValue(value0,value1,interpAm)
	return value0 -- To be implemented by derived classes
end
function ents.PFMActorComponent.Channel:ApplyValue(ent,controllerId,value)
	-- To be implemented by derived classes
	return false
end
function ents.PFMActorComponent.Channel:Apply(ent,offset)
	for controllerId,transforms in pairs(self.m_transforms) do
		-- TODO: Remember index of last iteration and use that as starting pivot to drastically decrease number of iterations required
		if(controllerId ~= 0) then -- TODO
			for i,t in ipairs(transforms) do
				if(offset < t[1]) then
					local tPrev = transforms[i -1] or t
					local dt = t[1] -tPrev[1]
					local relOffset = offset -tPrev[1]
					local interpFactor = (dt > 0.0) and math.clamp(relOffset /dt,0.0,1.0) or 0.0

					local value = self:GetInterpolatedValue(tPrev[2],t[2],interpFactor)
					self:ApplyValue(ent,controllerId,value)
					break
				end
			end
		end
	end
end

------------------

util.register_class("ents.PFMActorComponent.TranslationChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.TranslationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.TranslationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Lerp(value1,interpAm) -- TODO: Use slerp?
end
function ents.PFMActorComponent.TranslationChannel:ApplyValue(ent,controllerId,value)
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return false end
	animC:SetBonePos(controllerId,value)
	return true
end

------------------

util.register_class("ents.PFMActorComponent.RotationChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.RotationChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.RotationChannel:GetInterpolatedValue(value0,value1,interpAm)
	return value0:Copy()--value0:Slerp(value1,interpAm)
end
function ents.PFMActorComponent.RotationChannel:ApplyValue(ent,controllerId,value)
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return false end
	animC:SetBoneRot(controllerId,value)
	return true
end

------------------

local function translate_flex_controller_value(fc,val)
	return val *(fc.max -fc.min) +fc.min
end
util.register_class("ents.PFMActorComponent.FlexControllerChannel",ents.PFMActorComponent.Channel)
function ents.PFMActorComponent.FlexControllerChannel:__init()
	ents.PFMActorComponent.Channel.__init(self)
end
function ents.PFMActorComponent.FlexControllerChannel:GetInterpolatedValue(value0,value1,interpAm)
	return math.lerp(value0,value1,interpAm)
end
function ents.PFMActorComponent.FlexControllerChannel:ApplyValue(ent,controllerId,value)
	local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
	local mdl = ent:GetModel()
	local fc = (mdl ~= nil) and mdl:GetFlexController(controllerId) or nil -- TODO: Cache this
	if(flexC == nil or fc == nil) then return false end
	flexC:SetFlexController(controllerId,translate_flex_controller_value(fc,value))
	return true
end

------------------

ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS = 1
ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS = 2
ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS = 3

ents.PFMActorComponent.CHANNEL_COUNT = 3
function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local animC = self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	
	-- TODO: Only add these if this is an articulated actor
	self:AddEntityComponent(ents.COMPONENT_FLEX)
	self:AddEntityComponent(ents.COMPONENT_VERTEX_ANIMATED)
	
	self.m_channels = {}
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS] = ents.PFMActorComponent.TranslationChannel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS] = ents.PFMActorComponent.RotationChannel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS] = ents.PFMActorComponent.FlexControllerChannel()

	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	self.m_lastBoneControlTimeIndices = {}
	
	if(animC ~= nil) then
		self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
			self:ApplySkeletonTransforms()
		end)
	end
end

function ents.PFMActorComponent:OnRemove()
	if(util.is_valid(self.m_cbUpdateSkeleton)) then self.m_cbUpdateSkeleton:Remove() end
end

function ents.PFMActorComponent:OnEntitySpawn()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:PlayAnimation("reference") -- Play reference animation to make sure animation callbacks are being called
	end
end

function ents.PFMActorComponent:ApplyChannelTransform(offset,channel,timeIndex,fApply,fInterpolate)
	local log = channel:GetLog()
	local logLayer = log:GetLayers():GetValue()[1]
	if(logLayer ~= nil) then
		local times = logLayer:GetTimes():GetValue()
		local iTime = timeIndex or 1
		if(#times > 0) then
			local t = times[iTime]:GetValue()
			local values = logLayer:GetValues():GetValue()
			
			-- To avoid having to iterate all values, we'll start at the timestamp for the last offset and assume
			-- that the new offset is close to it. Then we iterate forwards or backwards depending on whether the
			-- new offset is in the future or the past.
			local iStart = iTime
			local iEnd
			local iStep
			if(offset < t) then
				iEnd = 1
				iStep = -1
			else
				iEnd = #times
				iStep = 1
			end
			
			local iNextValue
			for i=iStart,iEnd,iStep do
				local t = times[i]:GetValue()
				local tNext = times[i +1] and times[i +1]:GetValue() or nil
				if(offset >= t and (tNext == nil or offset < tNext)) then
					iNextValue = i
					break
				end
			end
			
			timeIndex = iNextValue or timeIndex
			iNextValue = iNextValue or 1
			local iPrevValue = math.max(iNextValue -1,1)
			
			-- Interpolate linearly between previous value and next value
			local prevValue = values[iPrevValue]
			local prevTime = times[iPrevValue]
			local nextValue = iNextValue and values[iNextValue] or prevValue
			local nextTime = iNextValue and times[iNextValue] or prevTime
			local dt = nextTime:GetValue() -prevTime:GetValue()
			local fraction = math.clamp((dt > 0.0) and ((offset -prevTime:GetValue()) /dt) or 0.0,0.0,1.0)
			local value = fInterpolate(prevValue:GetValue(),nextValue:GetValue(),fraction)
			fApply(value)
		end
	end
	return timeIndex
end

function ents.PFMActorComponent:ApplySkeletonTransforms()
	self.m_oldOffset = self.m_oldOffset or self.m_clipComponent:GetOffset()
	local newOffset = self.m_clipComponent:GetOffset()
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset
	
	local ent = self:GetEntity()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	local mdl = mdlC:GetModel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS]:Apply(ent,newOffset)
	--[[local boneTransforms = self:GetBoneTransforms()
	for boneName,transforms in pairs(boneTransforms) do
		local boneId = self:LookupBone(boneName)
		print(boneId)
	end]]

	--[[local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local flexTransforms = self:GetFlexTransforms()
	local actorFlexTransforms = {}
	for name,transforms in pairs(flexTransforms) do
		local flexId = mdl:LookupFlexController(name)
		if(flexId ~= -1) then
			local fc = mdl:GetFlexController(flexId)
			local translatedTransforms = {}
			for _,t in ipairs(transforms) do
				table.insert(translatedTransforms,{
					time = t.time,
					value = t.value *(fc.max -fc.min) +fc.min
				})
			end
			actorFlexTransforms[flexId] = {
				transformId = 1,
				transforms = translatedTransforms,
				name = name
			}
		end
	end
	-- TODO: Re-enable this
	local flexComponent = ent:GetComponent(ents.COMPONENT_FLEX)
	if(flexComponent ~= nil) then
		for flexControllerId,data in pairs(actorFlexTransforms) do
			local t = data.transforms[data.transformId]
			while(data.transforms[data.transformId +1] ~= nil and tDelta >= data.transforms[data.transformId +1].time) do
				data.transformId = data.transformId +1
				t = data.transforms[data.transformId]
			end
			local time = t.time
			local v = t.value
			local tNext = data.transforms[data.transformId +1]
			if(tNext ~= nil) then
				local tDiff = tNext.time -time
				local interp = (tDiff > 0.0) and ((tDelta -time) /tDiff) or 0.0
				v = math.lerp(v,tNext.value,interp)
			end
			flexComponent:SetFlexController(flexControllerId,v)
		end
	end
	
	if(util.is_valid(self.m_clipComponent) == false or #self.m_boneIds == 0) then return end
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return end
	
	local offset = self.m_clipComponent:GetOffset()
	local boneControls = self.m_animationSet:GetBoneControls():GetValue()
	for iBoneControl,ctrl in ipairs(boneControls) do
		local boneId = self.m_boneIds[iBoneControl]
		-- TODO: Interpolate!
		-- TODO: separate m_lastBoneControlTimeIndices into position and rotation
		self.m_lastBoneControlTimeIndices[iBoneControl] = self:ApplyChannelTransform(offset,ctrl:GetPositionChannel(),self.m_lastBoneControlTimeIndices[iBoneControl],function(value)
			animC:SetBonePos(boneId,value)
		end,function(prevPos,newPos,fraction)
			return prevPos:Lerp(newPos,fraction)
		end)
		self.m_lastBoneControlTimeIndices[iBoneControl] = self:ApplyChannelTransform(offset,ctrl:GetRotationChannel(),self.m_lastBoneControlTimeIndices[iBoneControl],function(value)
			animC:SetBoneRot(boneId,value)
		end,function(prevRot,newRot,fraction)
			return prevRot:Slerp(newRot,fraction)
		end)
	end
	
	-- Flex
	-- TODO: Re-enable this
	local mdl = self:GetEntity():GetModel()
	local flexC = self:GetEntity():GetComponent(ents.COMPONENT_FLEX)
	if(mdl == nil or flexC == nil) then return end
	local flexControls = self.m_animationSet:GetFlexControls():GetValue()
	for iFlexControl,ctrl in ipairs(flexControls) do
		local tFlexControllerIds = self.m_flexControllerIds[iFlexControl] -- base, left, right
		local fcId = tFlexControllerIds[1]
		if(fcId ~= -1) then
			local fc = mdl:GetFlexController(fcId)
			self:ApplyChannelTransform(offset,ctrl:GetChannel(),1,function(value)
				flexC:SetFlexController(fcId,translate_flex_controller_value(fc,value))
			end,math.lerp)
		end
		
		fcId = tFlexControllerIds[2]
		if(fcId ~= -1) then
			local fc = mdl:GetFlexController(fcId)
			self:ApplyChannelTransform(offset,ctrl:GetLeftValueChannel(),1,function(value)
				flexC:SetFlexController(fcId,translate_flex_controller_value(fc,value))
			end,math.lerp)
		end
		
		fcId = tFlexControllerIds[3]
		if(fcId ~= -1) then
			local fc = mdl:GetFlexController(fcId)
			self:ApplyChannelTransform(offset,ctrl:GetRightValueChannel(),1,function(value)
				flexC:SetFlexController(fcId,translate_flex_controller_value(fc,value))
			end,math.lerp)
		end
	end]]
end

function ents.PFMActorComponent:Setup(clipC,animSet)
	self.m_animationSet = animSet
	self.m_clipComponent = clipC
	
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	local mdlInfo = animSet:GetModel()
	mdlC:SetModel(mdlInfo:GetModelName())
	mdlC:SetSkin(mdlInfo:GetSkin())
	local transform = mdlInfo:GetTransform()
	ent:SetPos(transform:GetPosition())
	ent:SetRotation(transform:GetRotation())
	
	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	
	-- Initialize bone ids
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local boneControls = animSet:GetBoneControls():GetValue()
	for _,ctrl in ipairs(boneControls) do
		local boneName = ctrl:GetName()
		local boneId = mdl:LookupBone(boneName)
		table.insert(self.m_boneIds,boneId)
		if(boneId == -1) then console.print_warning("Unknown bone '" .. boneName .. "'!") end
	end
	
	-- Initialize flex controller ids
	local flexControls = animSet:GetFlexControls():GetValue()
	for _,ctrl in ipairs(flexControls) do
		local flexControllerName = ctrl:GetName()
		local ids = {
			mdl:LookupFlexController(flexControllerName),
			mdl:LookupFlexController("left_" .. flexControllerName),
			mdl:LookupFlexController("right_" .. flexControllerName)
		}
		table.insert(self.m_flexControllerIds,ids)
		if(ids[1] == -1) then console.print_warning("Unknown flex controller '" .. flexControllerName .. "'!") end
		if(ids[2] == -1) then console.print_warning("Unknown flex controller 'left_" .. flexControllerName .. "'!") end
		if(ids[3] == -1) then console.print_warning("Unknown flex controller 'right_" .. flexControllerName .. "'!") end
	end
	
	print("Applying flex transforms to actor...")
	local flexControls = animSet:GetFlexControls():GetValue()
	for iCtrl,ctrl in ipairs(flexControls) do
		local flexControllerName = ctrl:GetName()
		
		local channel = ctrl:GetChannel()
		local log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][1]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
		
		channel = ctrl:GetLeftValueChannel()
		log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][2]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
		
		channel = ctrl:GetRightValueChannel()
		log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][3]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end

	print("Applying bone transforms to actor...")
	local boneControls = animSet:GetBoneControls():GetValue()
	for iCtrl,ctrl in ipairs(boneControls) do
		local boneControllerName = ctrl:GetName()
		local boneId = self.m_boneIds[iCtrl]
		if(boneControllerName ~= "rootTransform" and boneId ~= -1) then -- TODO
			local posChannel = ctrl:GetPositionChannel()
			local log = posChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
				end
			end

			local rotChannel = ctrl:GetRotationChannel()
			log = rotChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local tPrev = 0.0
				for _,t in ipairs(times) do
					tPrev = t:GetValue()
				end
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end
	print("Done!")
end























function ents.PFMActorComponent:SetTimeSpan(ts) end -- TODO

function ents.PFMActorComponent:GetBoneTransforms() return self.m_boneTransforms end
function ents.PFMActorComponent:GetFlexTransforms() return self.m_flexTransforms end

function ents.PFMActorComponent:AddChannelTransform(channel,controllerName,time,value)
	if(self.m_channels[channel] == nil) then return end
	self.m_channels[channel]:AddTransform(controllerName,time,value)
end
function ents.PFMActorComponent:AddBoneTransform(name,time,pos,rot)
	self.m_boneTransforms[name] = self.m_boneTransforms[name] or {}
	local idx = -1
	local transforms = self.m_boneTransforms[name]
	for i,t in ipairs(transforms) do
		if(math.abs(time -t.time) < 0.01) then
			t.pos = pos or t.pos
			t.rot = rot or t.rot
			return
		end
		if(time < t.time and (idx == -1 or t.time >= transforms[idx].time)) then
			idx = i
		end
	end
	if(idx == -1) then idx = #transforms +1 end
	table.insert(transforms,idx,{
		time = time,
		pos = pos,
		rot = rot
	})
end
function ents.PFMActorComponent:AddFlexTransform(name,time,value)
	self.m_flexTransforms[name] = self.m_flexTransforms[name] or {}
	local transforms = self.m_flexTransforms[name]
	table.insert(transforms,{
		time = time,
		value = value
	})
end
function ents.PFMActorComponent:Spawn(tOffset,posOffset,rotOffset)
	local ent = self.m_entity
	if(util.is_valid(ent) == false) then
		ent = ents.create("prop_dynamic")
		if(ent == nil) then return end
		local pos = self.m_origin
		local rot = self.m_rotation
		if(posOffset ~= nil) then pos = pos +posOffset end
		if(rotOffset ~= nil) then rot = rotOffset *rot end
		local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
		if(mdlComponent ~= nil) then mdlComponent:SetModel(self.m_modelName) end
		local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
		if(trComponent ~= nil) then
			trComponent:SetPos(pos)
			trComponent:SetRotation(rot)
		end
		ent:AddComponent(ents.COMPONENT_FLEX)
		ent:AddComponent(ents.COMPONENT_VERTEX_ANIMATED)
		ent:Spawn()
		local animComponent = ent:AddComponent(ents.COMPONENT_ANIMATED)
		if(animComponent ~= nil) then animComponent:PlayAnimation("reference") end
		self.m_entity = ent
	end
	--if(true) then return end--self:GetModelName() == "props_doors/door01_dynamic.wmd") then return end -- TODO
	local boneTransforms = self:GetBoneTransforms()
	local actorTransforms = {}
	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlComponent == nil) then return end
	for name,transforms in pairs(boneTransforms) do
		local boneId = mdlComponent:LookupBone(name)
		--if(name == "bip_collar_R") then print(boneId) end
		local bRoot = name == "rootTransform"
		--if((boneId ~= -1 and (boneId ~= 0 or self:GetModelName() ~= "player\\hwm\\engineer.wmd")) or bRoot == true) then-- and boneId ~= 0) then -- Bone 0 = root bone?
		if(boneId ~= -1 or bRoot == true) then-- and boneId ~= 0) then -- Bone 0 = root bone?
			actorTransforms[boneId] = {
				transformId = 1,
				transforms = transforms,
				root = bRoot
			}
		end
	end
	local mdl = mdlComponent:GetModel()
	local flexTransforms = self:GetFlexTransforms()
	local actorFlexTransforms = {}
	for name,transforms in pairs(flexTransforms) do
		local flexId = mdl:LookupFlexController(name)
		if(flexId ~= -1) then
			local fc = mdl:GetFlexController(flexId)
			local translatedTransforms = {}
			for _,t in ipairs(transforms) do
				table.insert(translatedTransforms,{
					time = t.time,
					value = t.value *(fc.max -fc.min) +fc.min
				})
			end
			actorFlexTransforms[flexId] = {
				transformId = 1,
				transforms = translatedTransforms,
				name = name
			}
		end
	end
	local t = time.cur_time()
	local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animComponent ~= nil) then
		self.m_cbUpdateSkeleton = animComponent:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
			if(util.is_valid(ent) == false) then return end
			local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
			local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
			if(mdlComponent == nil or animComponent == nil) then return end
			local tCur = time.cur_time()
			--print(self.m_time +(tCur -self.m_lastUpdate))
			local tDelta = self.m_time +(tCur -self.m_lastUpdate)-- -8.2 ---tStart
			--print(tDelta)
			tDelta = tDelta +(tOffset -self:GetStartTime())
			
			-- Update bones
			for boneId,data in pairs(actorTransforms) do
				local t = data.transforms[data.transformId]
				--if(boneId == 14) then print(tDelta,data.transforms[data.transformId +1].time) end
				while(data.transforms[data.transformId +1] ~= nil and tDelta >= data.transforms[data.transformId +1].time) do
					data.transformId = data.transformId +1
					t = data.transforms[data.transformId]
				end
				local time = t.time
				--print(pos,",",rot)
				--print(t.pos,",",t.rot)
				--print(pos,",",t.pos)
				
				local pos = t.pos or data.prevPos
				local rot = t.rot or data.prevRot
				if(pos == nil or rot == nil) then
					local basePos,baseRot = animComponent:GetBoneTransform(boneId)
					pos = pos or basePos
					rot = rot or baseRot
				end
				data.prevPos = pos
				data.prevRot = rot
				local tNext = data.transforms[data.transformId +1]
				if(tNext ~= nil) then
					local tDiff = tNext.time -time
					local interp = (tDiff > 0.0) and math.clamp((tDelta -time) /tDiff,0.0,1.0) or 0.0
					if(tNext.pos ~= nil) then pos = pos:Lerp(tNext.pos,interp) end
					if(tNext.rot ~= nil) then rot = rot:Slerp(tNext.rot,interp) end
				end
				if(data.root) then
					local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
					if(trComponent ~= nil) then
						if(pos ~= nil) then
							trComponent:SetPos(pos)
						end
						if(rot ~= nil) then
							trComponent:SetRotation(rot *EulerAngles(180,180,0):ToQuaternion())
						end
					end
				--[[elseif(boneId == 0) then
					--if(self:GetName() == "guitar1") then print(pos) end
					--ent:SetPos(self.m_origin +pos)
					--ent:SetRotation(self.m_rotation *rot)
					print(self:GetName(),pos)
						ent:SetPos(pos)
						ent:SetRotation(rot *EulerAngles(0,0,90):ToQuaternion())]]
				else
					--[[if(self:GetModelName() == "props_facemovie\\beer_bottle.wmd") then
						print(boneId,pos)
						if(boneId == 0) then
							pos.y = 50.0
							pos.z = 0.0
						end
					end]]
					animComponent:SetBoneTransform(boneId,pos,rot)
				end
			end
				
			-- Update flexes
			local flexComponent = ent:GetComponent(ents.COMPONENT_FLEX)
			if(flexComponent ~= nil) then
				for flexControllerId,data in pairs(actorFlexTransforms) do
					local t = data.transforms[data.transformId]
					while(data.transforms[data.transformId +1] ~= nil and tDelta >= data.transforms[data.transformId +1].time) do
						data.transformId = data.transformId +1
						t = data.transforms[data.transformId]
					end
					local time = t.time
					local v = t.value
					local tNext = data.transforms[data.transformId +1]
					if(tNext ~= nil) then
						local tDiff = tNext.time -time
						local interp = (tDiff > 0.0) and ((tDelta -time) /tDiff) or 0.0
						v = math.lerp(v,tNext.value,interp)
					end
					flexComponent:SetFlexController(flexControllerId,v)
				end
			end
		end)
	end
end
function ents.PFMActorComponent:Clear()
	--[[if(util.is_valid(self.m_entity)) then
		self.m_entity:Remove()
		self.m_entity = nil
	end]]
	if(util.is_valid(self.m_cbUpdateSkeleton)) then
		self.m_cbUpdateSkeleton:Remove()
		self.m_cbUpdateSkeleton = nil
	end
end
function ents.PFMActorComponent:Run(t)
	self.m_time = t
	self.m_lastUpdate = time.cur_time()
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)
