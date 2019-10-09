--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("animation_set")

util.register_class("sfm.AnimationSet",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.AnimationSet,"gameModel",sfm.GameModel,"",sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)
sfm.BaseElement.RegisterProperty(sfm.AnimationSet,"camera",sfm.Camera,"",sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)

function sfm.AnimationSet:__init()
  sfm.BaseElement.__init(self,sfm.AnimationSet)
  self.m_controls = {}
  self.m_transformControls = {}
end

function sfm.AnimationSet:Load(el)
  sfm.BaseElement.Load(self,el)
	
	local attr = el:GetAttrV("controls")
  if(attr ~= nil) then
    for _,attr in ipairs(attr) do
      local elChild = attr:GetValue()
      if(elChild:GetType() == "DmeTransformControl") then
        local o = sfm.TransformControl()
        o:Load(elChild)
        table.insert(self.m_transformControls,o)
      else
        local o = sfm.Control()
        o:Load(elChild)
        table.insert(self.m_controls,o)
      end
    end
  end
end

function sfm.AnimationSet:GetControls() return self.m_controls end
function sfm.AnimationSet:GetTransformControls() return self.m_transformControls end

function sfm.AnimationSet:ToPFMAnimationSet(pfmAnimSet)
  local gameModel = self:GetGameModel()
  if(gameModel ~= nil) then
	 gameModel:ToPFMModel(pfmAnimSet:SetProperty("model",udm.PFMModel()))
  end

  local camera = self:GetCamera()
  if(camera ~= nil) then
    camera:ToPFMCamera(pfmAnimSet:SetProperty("camera",udm.PFMCamera()))
  end
	
	-- Flex controls
	for _,sfmControl in ipairs(self:GetControls()) do
		local pfmControl = pfmAnimSet:AddFlexControl(sfmControl:GetName())
		sfmControl:ToPFMControl(pfmControl)
	end
	
	-- Transform controls
	for _,sfmControl in ipairs(self:GetTransformControls()) do
		local pfmControl = pfmAnimSet:AddTransformControl(sfmControl:GetName())
		sfmControl:ToPFMControl(pfmControl)
	end
end
