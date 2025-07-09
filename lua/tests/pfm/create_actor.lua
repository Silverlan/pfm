-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/tests/pfm/base.lua")

tests.launch_pfm(function(pm)
	local actorEditor = pm:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		tests.complete(false, "Actor Editor is not valid!")
	else
		local modelName = "player/soldier"
		local actor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR, {
			["modelName"] = modelName,
			["pose"] = math.Transform(),
		})
		if actor == nil then
			tests.complete(false, "Failed to create actor with model '" .. modelName .. "'!")
		else
			tests.log_info("Actor has been created: {}", actor)
			local ent = actor:FindEntity()
			if util.is_valid(ent) == false then
				tests.complete(false, "Actor '" .. tostring(actor) .. "' has no entity!")
			else
				tests.log_info("Actor Entity: {}", ent)

				local vp = pm:GetViewport()
				if util.is_valid(vp) then
					vp:SetWorkCameraPose(math.Transform(Vector(0, 40, 40), EulerAngles(0, 180, 0):ToQuaternion()))
				end

				tests.complete(true, { screenshot = true })
			end
		end
	end
end)
