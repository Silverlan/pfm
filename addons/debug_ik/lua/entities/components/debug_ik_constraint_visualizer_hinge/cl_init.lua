--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.DebugIkConstraintVisualizerHinge", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self.m_enableTextElements = false
end
function Component:GetSolverJoint()
	local c = self:GetEntityComponent(ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER)
	if c == nil then
		return nil
	end
	return c, c:GetSolverJoint()
end
function Component:OnEntitySpawn()
	local c, solver, ballSocketIndex, swingLimitIndex = self:GetSolverJoint()
	if solver == nil then
		return
	end

	-- Swing limit cone
	local ballSocket = solver:GetJoint(ballSocketIndex)
	local swingLimit = solver:GetJoint(swingLimitIndex)

	local bone0 = ballSocket:GetConnectionA()
	local bone1 = ballSocket:GetConnectionB()
	local len = bone0:GetOriginalPose():GetOrigin():Distance(bone1:GetOriginalPose():GetOrigin())
	self.m_boneDistance = len

	local mdl = self:CreateHingeModel(len, swingLimit:GetMaxAngle() * 2.0)
	local ent = ents.create("prop_dynamic")
	ent:SetModel(mdl)
	ent:SetColor(Color(255, 255, 255, 20))
	ent:SyncScenes(self:GetEntity())
	ent:Spawn()
	table.insert(c.m_items, ent)
	self.m_swingSpanCone = ent

	if self.m_enableTextElements then
		self.m_entAxisA = c:CreateTextElement("axisA", Color.White)
		self.m_entAxisAInv = c:CreateTextElement("axisA", Color.White)
		self.m_entAxisB = c:CreateTextElement("axisB", Color.White)
		self.m_entAxisBInv = c:CreateTextElement("axisB", Color.White)
		self.m_angleText = c:CreateTextElement("100.00", Color.White)
		self.m_angleTextInv = c:CreateTextElement("100.00", Color.White)
	end

	self:OnTick()
end
function Component:CreateHingeModel(len, ang)
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local mesh = game.Model.Mesh.Create()
	local createInfo = game.Model.CircleCreateInfo(
		10, -- radius
		true -- Double-sided
	)
	createInfo.segmentCount = 24
	createInfo.totalAngle = math.deg(ang)

	local meshTip = game.Model.Mesh.Sub.create_circle(createInfo)

	meshTip:SetSkinTextureIndex(0)
	meshTip:Translate(Vector(0.0, 0.0, 0.0))
	meshTip:Scale(Vector(1, 1, 1))
	meshTip:Rotate(EulerAngles(0, -math.deg(ang) * 0.5, 0))
	mesh:AddSubMesh(meshTip)

	local wf = meshTip:Copy(true)
	wf:SetSkinTextureIndex(1)
	mesh:AddSubMesh(wf)

	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0, "pfm/debug_joint")
	mdl:AddMaterial(0, "wireframe")

	return mdl
end
function Component:OnTick()
	local c, solver, jointIndex, swingLimitIndex, hingeIndex = self:GetSolverJoint()
	if solver == nil then
		return
	end

	local joint = solver:GetJoint(swingLimitIndex)

	local hingeJoint = solver:GetJoint(hingeIndex)
	local bone0 = hingeJoint:GetConnectionA()
	local bone1 = hingeJoint:GetConnectionB()

	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(util.Color.Magenta)
	drawInfo:SetDuration(0.1)

	local axisA = joint:GetAxisA()
	local axisB = joint:GetAxisB()
	--axisA:Rotate(EulerAngles(-90,0,0):ToQuaternion())
	-- axisB:Rotate(EulerAngles(-90,0,0):ToQuaternion())
	-- axisA = hingeJoint:GetWorldHingeAxis()
	-- axisA = hingeJoint:GetFreeAxis()
	local freeAxis = hingeJoint:GetFreeAxis()
	local relAxis = axisA:Cross(freeAxis)
	relAxis:Normalize()
	axisB:Rotate(freeAxis, math.rad(-90))

	-- Rotate both axis around freeAxis
	--[[
        relAxis:Rotate(freeAxis, math.rad(180))
	axisB:Rotate(freeAxis, math.rad(180))
	axisA:Rotate(freeAxis, math.rad(180))
    ]]
	relAxis:Rotate(freeAxis, math.rad(-90))
	axisB:Rotate(freeAxis, math.rad(-90))
	axisA:Rotate(freeAxis, math.rad(-90))

	local anchor = bone1:GetPos()
	local poseA = math.Transform(bone0:GetPos(), bone0:GetRot())
	debug.draw_line(anchor, anchor + relAxis * self.m_boneDistance, drawInfo)

	drawInfo:SetColor(util.Color.Aqua)

	debug.draw_line(anchor, anchor + axisB * self.m_boneDistance, drawInfo)

	local dir = relAxis
	dir:Normalize()
	local right = axisA -- dir:GetPerpendicular()
	local rot = Quaternion(dir, right)

	self.m_swingSpanCone:SetPos(anchor)
	local angOffset = EulerAngles(90, 0, 0)
	--rot = rot * Quaternion(relAxis:Cross(right):GetNormal(), math.rad(90))
	rot = bone0:GetRot()
	local c = freeAxis:Cross(axisA):GetNormal()
	rot = Quaternion(freeAxis, -axisA, c)
	self.m_swingSpanCone:SetRotation(rot * angOffset:ToQuaternion())

	if not self.m_enableTextElements then
		return
	end
	local function get_text_rotation(axis)
		local u = vector.UP - vector.UP:Project(axis)

		local l = u:Length()
		if l == 0.0 then
			u = vector.RIGHT
		end
		u:Normalize()

		local r = axis:Cross(u)
		r:Normalize()

		rot = Quaternion(axis, r, u)
		rot = rot * EulerAngles(0, 90, 0):ToQuaternion()
		return rot
	end

	local textScale = 2.0
	local textOffset = textScale * 0.9
	self.m_entAxisA:SetScale(Vector(textScale, textScale, textScale))
	local pos = poseA:GetOrigin() + axisA * self.m_boneDistance * 0.5
	rot = get_text_rotation(axisA)
	local textPos0 = pos
	pos = textPos0 + rot:GetUp() * textOffset
	self.m_entAxisA:SetPos(pos)
	self.m_entAxisA:SetRotation(rot)

	self.m_entAxisAInv:SetScale(self.m_entAxisA:GetScale())
	self.m_entAxisAInv:SetPos(self.m_entAxisA:GetPos())
	self.m_entAxisAInv:SetRotation(self.m_entAxisA:GetRotation() * EulerAngles(0, 180, 0):ToQuaternion())

	self.m_entAxisB:SetScale(Vector(textScale, textScale, textScale))
	local pos = poseA:GetOrigin() + axisB * self.m_boneDistance * 0.5

	rot = get_text_rotation(axisB)

	local textPos1 = pos
	pos = textPos1 + rot:GetUp() * textOffset
	self.m_entAxisB:SetPos(pos)
	self.m_entAxisB:SetRotation(rot)

	self.m_entAxisBInv:SetScale(self.m_entAxisB:GetScale())
	self.m_entAxisBInv:SetPos(self.m_entAxisB:GetPos())
	self.m_entAxisBInv:SetRotation(self.m_entAxisB:GetRotation() * EulerAngles(0, 180, 0):ToQuaternion())

	self.m_angleText:SetScale(Vector(textScale, textScale, textScale))
	self.m_angleText:SetPos(textPos0 + (textPos1 - textPos0) * 0.5)
	local dot = axisA:DotProduct(axisB)
	local angle = math.acos(dot)
	local elText = self.m_angleText:GetComponent("gui_3d"):GetGUIElement()
	elText:SetText(util.round_string(math.deg(angle), 2))
	elText:SizeToContents()

	local p0 = axisA
	local p1 = axisB
	local p2 = axisA + axisB
	local plane = math.Plane(p0, p1, p2)

	local w = Vector(0, 0, 1)
	w = w - w:Project(plane:GetNormal())
	w:Normalize()

	local midAxis = (axisA + axisB) / 2.0
	midAxis:Normalize()
	rot = get_text_rotation(w) --plane:GetNormal())--midAxis)
	local q = plane:GetNormal():Cross(w)
	q:Normalize()
	--print(Quaternion(plane:GetNormal(),w,q):Length())
	self.m_angleText:SetRotation(rot * EulerAngles(0, 0, 0)) --rot *EulerAngles(0,-90,0))

	self.m_angleTextInv:SetScale(self.m_angleText:GetScale())
	self.m_angleTextInv:SetPos(self.m_angleText:GetPos())
	self.m_angleTextInv:SetRotation(self.m_angleText:GetRotation() * EulerAngles(0, 180, 0):ToQuaternion())
	local elTextInv = self.m_angleTextInv:GetComponent("gui_3d"):GetGUIElement()
	elTextInv:SetText(elText:GetText())
	elTextInv:SizeToContents()
end
ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER_HINGE =
	ents.register_component("debug_ik_constraint_visualizer_hinge", Component)