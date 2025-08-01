-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("material.lua")

sfm.register_element_type("GameModel")
sfm.link_dmx_type("DmeGameModel", sfm.GameModel)

sfm.register_element_type("Transform") -- Predeclaration
sfm.register_element_type("GlobalFlexControllerOperator") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.GameModel, "transform", sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.GameModel, "overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "overridePos")
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "modelName", "")
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "skin", 0)
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "body", 0)
sfm.BaseElement.RegisterArray(sfm.GameModel, "children", sfm.Dag)
sfm.BaseElement.RegisterArray(sfm.GameModel, "bones", sfm.Transform)
sfm.BaseElement.RegisterArray(sfm.GameModel, "flexnames", "", {
	getterName = "GetFlexNames",
	setterName = "SetFlexNames",
})
sfm.BaseElement.RegisterArray(sfm.GameModel, "flexWeights", 0.0)
sfm.BaseElement.RegisterArray(sfm.GameModel, "globalFlexControllers", sfm.GlobalFlexControllerOperator)
sfm.BaseElement.RegisterArray(sfm.GameModel, "materials", sfm.Material)
sfm.BaseElement.RegisterAttribute(sfm.GameModel, "visible", false, {
	getterName = "IsVisible",
})

function sfm.GameModel:GetPragmaModelPath()
	local path = util.Path.CreateFilePath(self:GetModelName())
	path:PopFront() -- Pop "models/" prefix
	return asset.get_normalized_path(path:GetString(), asset.TYPE_MODEL)
end
