--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

fudm.ELEMENT_TYPE_PFM_VOLUMETRIC = fudm.register_type("PFMVolumetric",{fudm.PFMEntityComponent},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_VOLUMETRIC,"enabled",fudm.Bool(true))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_VOLUMETRIC,"materialName",fudm.String("volumes/generic_volume"))

function fudm.PFMVolumetric:GetComponentName() return "pfm_volumetric" end
function fudm.PFMVolumetric:GetIconMaterial() return "gui/pfm/icon_particle_item" end

function fudm.PFMVolumetric:ChangeMaterial(matName)
    self:SetMaterialName(matName)
end

function fudm.PFMVolumetric:SetupControls(actorEditor,itemComponent)
    local itemBaseProps = itemComponent:AddItem(locale.get_text("pfm_base_properties"))
    actorEditor:AddProperty(locale.get_text("material"),itemBaseProps,function(parent)
        local el = gui.create("WIFileEntry",parent)
        el:SetValue(self:GetMaterialName())
        el:SetBrowseHandler(function(resultHandler)
            gui.open_model_dialog(function(dialogResult,matName)
                if(dialogResult ~= gui.DIALOG_RESULT_OK) then return end
                resultHandler(matName)
            end)
        end)
        el:AddCallback("OnValueChanged",function(el,value)
            self:ChangeMaterial(value)
        end)
        return el
    end)
end
