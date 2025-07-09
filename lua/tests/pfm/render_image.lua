-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/tests/pfm/base.lua")

tests.launch_pfm(function(pm)
	pm:LoadProject("projects/scenebuilds/pfm_demo_scene")
	local vp = pm:GetViewport()
	if util.is_valid(vp) then
		vp:SetWorkCameraPose(
			math.Transform(
				Vector(-105.66, 54.0945, -65.6428),
				EulerAngles(6.95692, -171.594, -0.000267118):ToQuaternion()
			)
		)

		pm:GoToWindow("render")
		local render = pm:GetWindow("render")
		if util.is_valid(render) then
			render:SetRenderer("cycles")
			render:AddCallback("OnRenderComplete", function()
				tests.complete(true, { screenshot = true })
			end)
			render:Refresh(true)
		end
	end
end)
