util.register_class("sfm.ProgressiveRefinement",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useAntialiasing",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useDepthOfField",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"on",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideDepthOfFieldQuality",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideMotionBlurQuality",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useMotionBlur",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideDepthOfFieldQualityValue",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideMotionBlurQualityValue",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideShutterSpeed",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideShutterSpeedValue",0.0208333)

function sfm.ProgressiveRefinement:__init()
  sfm.BaseElement.__init(self,sfm.ProgressiveRefinement)
end
