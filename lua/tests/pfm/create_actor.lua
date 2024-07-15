include("/tests/base.lua")

tests.queue("pfm_create_actor", function()
	include("/pfm/pfm.lua")
	pfm.add_event_listener("OnFilmmakerLaunched", function(pm)
		game.wait_for_frames(1, function()
			local actorEditor = pm:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				tests.complete(false, "Actor Editor is not valid!")
			else
				local modelName = "player/soldier"
				local actor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR, {
					["modelName"] = modelName,
				})
				if actor == nil then
					tests.complete(false, "Failed to create actor with model '" .. modelName .. "'!")
				else
					print("Actor has been created: ", actor)
					local ent = actor:FindEntity()
					if util.is_valid(ent) == false then
						tests.complete(false, "Actor '" .. tostring(actor) .. "' has no entity!")
					else
						print("Actor Entity: ", ent)
						tests.complete(true)
					end
				end
			end
		end, true)
	end)
	pfm.launch(nil)
end)
