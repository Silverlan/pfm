util.register_class("ents.PFMTrack",BaseEntityComponent)

function ents.PFMTrack:__init()
	BaseEntityComponent.__init(self)
end

function ents.PFMTrack:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)

	self.m_soundEvents = {}
	self.m_actors = {}
	self.m_cameras = {}
	self.m_bCameraEnabled = true
end

function ents.PFMTrack:SetCamPos(pos) self.m_camPos = pos end
function ents.PFMTrack:SetCamRot(rot) self.m_camRot = rot end
function ents.PFMTrack:GetSoundEvents() return self.m_soundEvents end
function ents.PFMTrack:AddSoundEvent(ev)
	for i,evOther in ipairs(self.m_soundEvents) do
		if(ev:GetStartTime() < evOther:GetStartTime()) then
			table.insert(self.m_soundEvents,i,ev)
			return
		end
	end
	table.insert(self.m_soundEvents,ev)
end
function ents.PFMTrack:AddActor(name,mdlName,origin,rot)
	local actor = ents.create("pfm_actor")
	actor:GetComponent(ents.COMPONENT_NAME):SetName(name)
	actor:GetComponent(ents.COMPONENT_MODEL):SetModel(mdlName)
	local trc = actor:GetComponent(ents.COMPONENT_TRANSFORM)
	trc:SetPos(origin)
	trc:SetRotation(rot)
	table.insert(self.m_actors,actor)
	return self.m_actors[#self.m_actors]
end
function ents.PFMTrack:GetActor(name)
	for _,actor in ipairs(self.m_actors) do
		if(actor:GetComponent(ents.COMPONENT_NAME):GetName() == name) then return actor end
	end
end
function ents.PFMTrack:AddSoundEvent(name,start,duration,volume,pitch,origin,direction)
	-- TODO
end
function ents.PFMTrack:AddCamera(name,origin,rot)
	local cam = ents.create("pfm_camera")
	cam:GetComponent(ents.COMPONENT_NAME):SetName(name)
	local trc = cam:GetComponent(ents.COMPONENT_TRANSFORM)
	trc:SetPos(origin)
	trc:SetRotation(rot)
	table.insert(self.m_cameras,cam)
	return self.m_cameras[#self.m_cameras]
end
function ents.PFMTrack:GetCamera(name)
	for _,cam in ipairs(self.m_cameras) do
		if(cam:GetName() == name) then return cam end
	end
end
function ents.PFMTrack:OnStart(t)
	print("Track " .. self:GetName() .. " has started at " .. t .. "!")
	local offset = self:GetOffset()
	for _,actor in ipairs(self.m_actors) do
		actor:Run(t -self:GetStartTime())
		actor:Spawn(offset,self.m_offsetTransform[1],self.m_offsetTransform[2])
	end
	if(self.m_bCameraEnabled == true) then
		self.m_cbCamera = game.add_callback("CalcView",function(pos,rot)
			--[[if(self.m_camPos ~= nil) then
				local newPos = self.m_camPos
				pos:Set(newPos.x,newPos.y,newPos.z)
			end]]
			--[[if(self.m_camRot ~= nil) then
				local newRot = EulerAngles(0,180,0):ToQuaternion() *self.m_camRot
				rot:Set(newRot.w,newRot.x,newRot.y,newRot.z)
			end]]
		end)
	end
end
function ents.PFMTrack:OnStop()
	print("Track " .. self:GetName() .. " has stopped!")
	if(util.is_valid(self.m_cbCamera)) then
		self.m_cbCamera:Remove()
		self.m_cbCamera = nil
	end
	for _,ev in ipairs(self.m_soundEvents) do ev:Stop() end
	for _,actor in ipairs(self.m_actors) do actor:Clear() end
end
function ents.PFMTrack:OnRun(t)
	for _,ev in ipairs(self.m_soundEvents) do ev:Run(t) end
	for _,actor in ipairs(self.m_actors) do actor:Run(t -self:GetStartTime()) end
end
function ents.PFMTrack:GetActors() return self.m_actors end
function ents.PFMTrack:SetOffsetTransform(pos,rot)
	self.m_offsetTransform = {pos,rot}
end
function ents.PFMTrack:SetCameraEnabled(b) self.m_bCameraEnabled = b end
ents.COMPONENT_PFM_TRACK = ents.register_component("pfm_track",ents.PFMTrack)
