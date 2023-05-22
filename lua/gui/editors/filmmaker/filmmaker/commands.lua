--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

console.register_command("pfm_action", function(pl, ...)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end

	local args = { ... }
	if args[1] == "toggle_play" then
		local vp = pm:GetViewport()
		if util.is_valid(vp) then
			vp:GetPlayButton():TogglePlay()
		end
	elseif args[1] == "previous_frame" then
		pm:GoToPreviousFrame()
	elseif args[1] == "next_frame" then
		pm:GoToNextFrame()
	elseif args[1] == "previous_bookmark" then
		pm:GoToPreviousBookmark()
	elseif args[1] == "next_bookmark" then
		pm:GoToNextBookmark()
	elseif args[1] == "create_bookmark" then
		pm:AddBookmark()
	elseif args[1] == "select_editor" then
		local timeline = pm:GetTimeline()
		if args[2] == "clip" then
			timeline:SetEditor(gui.PFMTimeline.EDITOR_CLIP)
		elseif args[2] == "motion" then
			timeline:SetEditor(gui.PFMTimeline.EDITOR_MOTION)
		elseif args[2] == "graph" then
			timeline:SetEditor(gui.PFMTimeline.EDITOR_GRAPH)
		end
	elseif args[1] == "zoom" then
		local cam = pm:GetGameplayCamera()
		if util.is_valid(cam) then
			if args[2] == "in" then
				cam:SetFOV(cam:GetFOV() + 1.0)
			elseif args[2] == "out" then
				cam:SetFOV(cam:GetFOV() - 1.0)
			end
		end

		local vp = pm:GetGameplayViewport()
		if vp ~= nil and vp:IsSceneCamera() then
			local cam = vp:GetSceneCamera()
			local pfmActorC = cam:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
			if pfmActorC ~= nil then
				pm:SetActorGenericProperty(pfmActorC, "ec/camera/fov", cam:GetFOV(), udm.TYPE_FLOAT)
			end
		end
	elseif args[1] == "transform" then
		if args[2] == "move" then
			local shift = input.is_shift_key_down()
			if args[3] == "x" then
				if shift then
					pm:SetQuickAxisTransformMode({ math.AXIS_Y, math.AXIS_Z })
				else
					pm:SetQuickAxisTransformMode({ math.AXIS_X })
				end
			elseif args[3] == "y" then
				if shift then
					pm:SetQuickAxisTransformMode({ math.AXIS_X, math.AXIS_Z })
				else
					pm:SetQuickAxisTransformMode({ math.AXIS_Y })
				end
			elseif args[3] == "z" then
				if shift then
					pm:SetQuickAxisTransformMode({ math.AXIS_X, math.AXIS_Y })
				else
					pm:SetQuickAxisTransformMode({ math.AXIS_Z })
				end
			end
		else
			local vp = pm:GetViewport()
			if util.is_valid(vp) then
				if args[2] == "select" then
					vp:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SELECT)
				elseif args[2] == "translate" then
					vp:SetTranslationManipulatorMode()
				elseif args[2] == "rotate" then
					vp:SetRotationManipulatorMode()
				elseif args[2] == "scale" then
					vp:SetScaleManipulatorMode()
				end
			end
		end
	end
end)

console.register_command("pfm_undo", function(pl, ...)
	pfm.undo()
end)

console.register_command("pfm_redo", function(pl, ...)
	pfm.redo()
end)

console.register_command("pfm_delete", function(pl, ...)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	local actorEditor = pm:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end
	local ids = {}
	for _, actor in ipairs(actorEditor:GetSelectedActors()) do
		if actor:IsValid() then
			table.insert(ids, tostring(actor:GetUniqueId()))
		end
	end

	actorEditor:RemoveActors(ids)
end)
