--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

fudm.ELEMENT_TYPE_PFM_IMPERSONATEE = fudm.register_type("PFMImpersonatee",{fudm.PFMEntityComponent},true)

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_IMPERSONATEE,"modelName",fudm.String(""))

function fudm.PFMImpersonatee:GetComponentName() return "pfm_impersonatee" end
function fudm.PFMImpersonatee:GetIconMaterial() return "gui/pfm/icon_model_item" end

function fudm.PFMImpersonatee:SetupControls(actorEditor,itemComponent)
	actorEditor:AddProperty(locale.get_text("model"),itemComponent,function(parent)
		local el = gui.create("WIFileEntry",parent)
		el:SetValue(self:GetModelName())
		el:SetBrowseHandler(function(resultHandler)
			gui.open_model_dialog(function(dialogResult,mdlName)
				if(dialogResult ~= gui.DIALOG_RESULT_OK) then return end
				resultHandler(mdlName)
			end)
		end)
		el:AddCallback("OnValueChanged",function(el,value)
			if(#value > 0) then
				local actorC = self:FindParentElement()
				local mdlC = (actorC ~= nil) and actorC:FindComponent("pfm_model") or nil
				local srcMdl = mdlC:GetModelName()
				if(#srcMdl > 0 and mdlC ~= nil and ents.RetargetRig.Rig.exists(srcMdl,value) == false) then
					tool.get_filmmaker():OpenBoneRetargetWindow(srcMdl,value)
				end
			end
			self:SetModelName(value)
			tool.get_filmmaker():TagRenderSceneAsDirty()
		end)
		return el
	end)
end
