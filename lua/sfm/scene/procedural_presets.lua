util.register_class("sfm.ProceduralPresets",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitteriterations",5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitterscale_vector",2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"jitterscale",1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothiterations",5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothscale_vector",2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"smoothscale",1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets,"staggerinterval",0.0833)

function sfm.ProceduralPresets:__init()
  sfm.BaseElement.__init(self,sfm.ProceduralPresets)
end
