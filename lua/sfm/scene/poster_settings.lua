util.register_class("sfm.PosterSettings",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"width",1920)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"constrainAspect",true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"height",1080)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"DPI",300)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"heightInPixels",true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"units",0)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"widthInPixels",true)

function sfm.PosterSettings:__init()
  sfm.BaseElement.__init(self,sfm.PosterSettings)
end
