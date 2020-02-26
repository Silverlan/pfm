--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("game.Filmmaker",game.Generic)

function game.Filmmaker:__init()
	game.Generic.__init(self)
end

function game.Filmmaker:InitializeDefaultPlayerDimensions(pl)
	pl:SetStandHeight(72.0)
	pl:SetStandEyeLevel(64.0)
	pl:SetCrouchHeight(36.0)
	pl:SetCrouchEyeLevel(28.0)
	pl:SetWalkSpeed(400.0)
	pl:SetRunSpeed(400.0)
	pl:SetSprintSpeed(400.0)
	pl:SetCrouchedWalkSpeed(133.33)
	local charComponent = pl:GetEntity():GetComponent(ents.COMPONENT_CHARACTER)
	if(charComponent ~= nil) then charComponent:SetJumpPower(240.0) end
end

function game.Filmmaker:InitializePlayerModel(pl)
	local ent = pl:GetEntity()
	game.load_model("player/scout.wmd") -- Make sure the model is loaded so we can use the activity names here
	local activityTranslation = {
		[game.Model.Animation.ACT_IDLE] = game.Model.Animation.FindActivityId("ACT_MP_STAND_PRIMARY"),
		[game.Model.Animation.ACT_RUN] = game.Model.Animation.FindActivityId("ACT_MP_RUN_PRIMARY"),
		[game.Model.Animation.ACT_WALK] = game.Model.Animation.FindActivityId("ACT_MP_RUN_PRIMARY"),
		[game.Model.Animation.ACT_CROUCH] = game.Model.Animation.FindActivityId("ACT_MP_CROUCH_PRIMARY"),
		[game.Model.Animation.ACT_CROUCH_WALK] = game.Model.Animation.FindActivityId("ACT_MP_CROUCHWALK_PRIMARY"),
		[game.Model.Animation.ACT_JUMP] = game.Model.Animation.FindActivityId("ACT_MP_JUMP_FLOAT_primary")
	}
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:AddEventCallback(ents.AnimatedComponent.EVENT_TRANSLATE_ACTIVITY,function(activity)
			activity = activityTranslation[activity] or activity
			return util.EVENT_REPLY_HANDLED,activity
		end)
	end

	local obsC = ent:GetComponent(ents.COMPONENT_OBSERVABLE)
	if(obsC ~= nil) then
		obsC:SetLocalCameraOffset(ents.ObservableComponent.CAMERA_TYPE_THIRD_PERSON,Vector(0,20,-60))
		obsC:SetLocalCameraOrigin(ents.ObservableComponent.CAMERA_TYPE_THIRD_PERSON,Vector(0,55,0))
		-- obsC:SetLocalCameraOrigin(ents.ObservableComponent.CAMERA_TYPE_FIRST_PERSON,Vector(0,64,0))
	end

	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	if(CLIENT == true) then
		local vb = ents.get_view_body()
		if(vb ~= nil) then
			local mdlComponent = vb:GetModelComponent()
			if(mdlComponent ~= nil) then
				mdlComponent:SetModel("player/soldier_legs.wmd")
			end
		end
		ent:AddComponent("pfm_player")
		return
	end
	if(mdlComponent ~= nil) then mdlComponent:SetModel("player/scout.wmd") end
	pl:SetObserverMode(ents.PlayerComponent.OBSERVERMODE_THIRDPERSON)
end
