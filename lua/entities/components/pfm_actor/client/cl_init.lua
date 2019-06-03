util.register_class("ents.PFMActorComponent",BaseEntityComponent)

function ents.PFMActorComponent:__init()
	BaseEntityComponent.__init(self)
end

function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	
	self.m_boneTransforms = {}
	self.m_flexTransforms = {}
end

function ents.PFMActorComponent:GetModelName() return self.m_modelName end
function ents.PFMActorComponent:GetBoneTransforms() return self.m_boneTransforms end
function ents.PFMActorComponent:GetFlexTransforms() return self.m_flexTransforms end

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
