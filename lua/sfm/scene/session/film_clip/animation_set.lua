include("animation_set")

util.register_class("sfm.AnimationSet",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.AnimationSet,"gameModel",sfm.GameModel)

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
	self:GetGameModel():ToPFMModel(pfmAnimSet:GetModel())
	
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
