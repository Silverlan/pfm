--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/unirender/nodes/logic.lua")

unirender.Node.eye_uv = {
	IN_UV = "uv",
	IN_IRIS_DILATION = "iris_dilation",
	IN_IRIS_PROJ_U_XYZ = "iris_proj_u_xyz",
	IN_IRIS_PROJ_U_W = "iris_proj_u_w",
	IN_IRIS_PROJ_V_XYZ = "iris_proj_v_xyz",
	IN_IRIS_PROJ_V_W = "iris_proj_v_w",
	IN_IRIS_MAX_DILATION_FACTOR = "iris_max_dilation_factor",
	IN_IRIS_UV_RADIUS = "iris_uv_radius",

	OUT_UV = "uv",
}
local function dot4(v0, v1)
	return v0[1] * v1[1] + v0[2] * v1[2] + v0[3] * v1[3] + v0[4] * v1[4]
end
unirender.NODE_EYE_UV = unirender.register_node("eye_uv", function(desc)
	local inProjUXyz =
		desc:RegisterInput(unirender.Socket.TYPE_VECTOR, unirender.Node.eye_uv.IN_IRIS_PROJ_U_XYZ, Vector())
	local inProjUW = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.eye_uv.IN_IRIS_PROJ_U_W, 0.0)
	local inProjVXyz =
		desc:RegisterInput(unirender.Socket.TYPE_VECTOR, unirender.Node.eye_uv.IN_IRIS_PROJ_V_XYZ, Vector())
	local inProjVW = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.eye_uv.IN_IRIS_PROJ_V_W, 0.0)
	local inIrisDilation = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.eye_uv.IN_IRIS_DILATION, 0.5)
	local inIrisMaxDilationFactor =
		desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.eye_uv.IN_IRIS_MAX_DILATION_FACTOR, 1.0)
	local inUvRadius = desc:RegisterInput(unirender.Socket.TYPE_FLOAT, unirender.Node.eye_uv.IN_IRIS_UV_RADIUS, 0.2)

	local outUv = desc:RegisterOutput(unirender.Socket.TYPE_VECTOR, unirender.Node.eye_uv.OUT_UV)
	desc:SetPrimaryOutputSocket(outUv)

	local geo = desc:AddNode(unirender.NODE_GEOMETRY):GetOutputSocket(unirender.Node.geometry.OUT_POSITION)
		* util.metres_to_units(1.0)

	-- Convert to Cycles coordinate system
	inProjUXyz = desc:CombineRGB(inProjUXyz.x, -inProjUXyz.z, inProjUXyz.y)
	inProjVXyz = desc:CombineRGB(inProjVXyz.x, -inProjVXyz.z, inProjVXyz.y)
	--

	local nodeUvX = dot4({ geo.x, geo.y, geo.z, 1.0 }, { inProjUXyz.x, inProjUXyz.y, inProjUXyz.z, inProjUW })
	local nodeUvY = dot4({ geo.x, geo.y, geo.z, 1.0 }, { inProjVXyz.x, inProjVXyz.y, inProjVXyz.z, inProjVW })

	local pupilCenterToBorder = desc:CombineRGB(nodeUvX, nodeUvY, 0):Length() / inUvRadius
	pupilCenterToBorder = pupilCenterToBorder:Clamp(0.0, 1.0)
	local factor = desc:AddConstantNode(1.0)
		:Lerp(pupilCenterToBorder, inIrisDilation:Clamp(0.0, inIrisMaxDilationFactor) * 2.5 - 1.25)
	nodeUvX = nodeUvX * factor
	nodeUvY = nodeUvY * factor

	nodeUvX = (nodeUvX + 1.0) / 2.0
	nodeUvY = (nodeUvY + 1.0) / 2.0
	desc:Link(desc:CombineRGB(nodeUvX, nodeUvY, 0), outUv)
end)
