util.register_class("sfm.Scene.MovieSettings")
function sfm.Scene.MovieSettings:__init()
  self.m_videoTarget = 6
  self.m_clearDecals = false
  self.m_stereoscopic = false
  self.m_audioTarget = 2
  self.m_width = 1280
  self.m_stereoSingleFile = false
  self.m_height = 720
  self.m_fileName = ""
end

function sfm.Scene.MovieSettings:Load(el)
  self.m_movieTarget = el:GetAttributeValue("videoTarget")
  self.m_clearDecals = el:GetAttributeValue("clearDecals")
  self.m_stereoscopic = el:GetAttributeValue("stereoscopic")
  self.m_audioTarget = el:GetAttributeValue("audioTarget")
  self.m_width = el:GetAttributeValue("width")
  self.m_stereoSingleFile = el:GetAttributeValue("stereoSingleFile")
  self.m_height = el:GetAttributeValue("height")
  self.m_fileName = el:GetAttributeValue("filename")
end

function sfm.Scene.MovieSettings:GetVideoTarget() return self.m_videoTarget end
function sfm.Scene.MovieSettings:GetClearDecals() return self.m_clearDecals end
function sfm.Scene.MovieSettings:GetStereoscopic() return self.m_stereoscopic end
function sfm.Scene.MovieSettings:GetAudioTarget() return self.m_audioTarget end
function sfm.Scene.MovieSettings:GetWidth() return self.m_width end
function sfm.Scene.MovieSettings:GetStereoSingleFile() return self.m_stereoSingleFile end
function sfm.Scene.MovieSettings:GetHeight() return self.m_height end
function sfm.Scene.MovieSettings:GetFileName() return self.m_fileName end

util.register_class("sfm.Scene.TimeSelection")
function sfm.Scene.TimeSelection:__init()
  self.m_enabled = false
  self.m_holdRight = 214748
  self.m_relative = false
  self.m_falloffLeft = -214748
  self.m_interpolatorLeft = 6
  self.m_falloffRight = 214748
  self.m_threshold = 0.0005
  self.m_holdLeft = -214748
  self.m_interpolatorRight = 6
  self.m_resampleInterval = 0.01
  self.m_recordingState = 3
end

function sfm.Scene.TimeSelection:Load(el)
  self.m_enabled = el:GetAttributeValue("enabled")
  self.m_holdRight = el:GetAttributeValue("hold_right")
  self.m_relative = el:GetAttributeValue("relative")
  self.m_falloffLeft = el:GetAttributeValue("falloff_left")
  self.m_interpolatorLeft = el:GetAttributeValue("interpolator_left")
  self.m_falloffRight = el:GetAttributeValue("falloff_right")
  self.m_threshold = el:GetAttributeValue("threshold")
  self.m_holdLeft = el:GetAttributeValue("hold_left")
  self.m_interpolatorRight = el:GetAttributeValue("interpolator_right")
  self.m_resampleInterval = el:GetAttributeValue("resampleinterval")
  self.m_recordingState = el:GetAttributeValue("recordingstate")
end

function sfm.Scene.TimeSelection:IsEnabled() return self.m_enabled end
function sfm.Scene.TimeSelection:GetHoldRight() return self.m_holdRight end
function sfm.Scene.TimeSelection:GetRelative() return self.m_relative end
function sfm.Scene.TimeSelection:GetFalloffLeft() return self.m_falloffLeft end
function sfm.Scene.TimeSelection:GetInterpolatorLeft() return self.m_interpolatorLeft end
function sfm.Scene.TimeSelection:GetFalloffRight() return self.m_falloffRight end
function sfm.Scene.TimeSelection:GetThreshold() return self.m_threshold end
function sfm.Scene.TimeSelection:GetHoldLeft() return self.m_holdLeft end
function sfm.Scene.TimeSelection:GetInterpolatorRight() return self.m_interpolatorRight end
function sfm.Scene.TimeSelection:GetResampleInterval() return self.m_resampleInterval end
function sfm.Scene.TimeSelection:GetRecordingState() return self.m_recordingState end

util.register_class("sfm.Scene.ProceduralPresets")
function sfm.Scene.ProceduralPresets:__init()
  self.m_jitterIterations = 5
  self.m_jitterScaleVector = 2.5
  self.m_jitterScale = 1
  self.m_smoothIterations = 5
  self.m_smoothScaleVector = 2.5
  self.m_smoothScale = 1
  self.m_staggerInterval = 0.0833
end

function sfm.Scene.ProceduralPresets:Load(el)
  self.m_jitterIterations = el:GetAttributeValue("jitteriterations")
  self.m_jitterScaleVector = el:GetAttributeValue("jitterscale_vector")
  self.m_jitterScale = el:GetAttributeValue("jitterscale")
  self.m_smoothIterations = el:GetAttributeValue("smoothiterations")
  self.m_smoothScaleVector = el:GetAttributeValue("smoothscale_vector")
  self.m_smoothScale = el:GetAttributeValue("smoothscale")
  self.m_staggerInterval = el:GetAttributeValue("staggerinterval")
end

function sfm.Scene.ProceduralPresets:GetJitterIterations() return self.m_jitterIterations end
function sfm.Scene.ProceduralPresets:GetJitterScaleVector() return self.m_jitterScaleVector end
function sfm.Scene.ProceduralPresets:GetJitterScale() return self.m_jitterScale end
function sfm.Scene.ProceduralPresets:GetSmoothIterations() return self.m_smoothIterations end
function sfm.Scene.ProceduralPresets:GetSmoothScaleVector() return self.m_smoothScaleVector end
function sfm.Scene.ProceduralPresets:GetSmoothScale() return self.m_smoothScale end
function sfm.Scene.ProceduralPresets:GetStaggerInterval() return self.m_staggerInterval end

util.register_class("sfm.Scene.RenderSettings")

util.register_class("sfm.Scene.RenderSettings.ProgressiveRefinement")
function sfm.Scene.RenderSettings.ProgressiveRefinement:__init()
  self.m_useAntialiasing = 1
  self.m_useDepthOfField = 1
  self.m_on = 1
  self.m_overrideDepthOfFieldQuality = 0
  self.m_overrideMotionBlurQuality = 0
  self.m_useMotionBlur = 1
  self.m_overrideDepthOfFieldQualityValue = 1
  self.m_overrideMotionBlurQualityValue = 1
  self.m_overrideShutterSpeed = 0
  self.m_overrideShutterSpeedValue = 0.0208333
end

function sfm.Scene.RenderSettings.ProgressiveRefinement:Load(el)
  self.m_useAntialiasing = el:GetAttributeValue("useAntialiasing")
  self.m_useDepthOfField = el:GetAttributeValue("useDepthOfField")
  self.m_on = el:GetAttributeValue("on")
  self.m_overrideDepthOfFieldQuality = el:GetAttributeValue("overrideDepthOfFieldQuality")
  self.m_overrideMotionBlurQuality = el:GetAttributeValue("overrideMotionBlurQuality")
  self.m_useMotionBlur = el:GetAttributeValue("useMotionBlur")
  self.m_overrideDepthOfFieldQualityValue = el:GetAttributeValue("overrideDepthOfFieldQualityValue")
  self.m_overrideMotionBlurQualityValue = el:GetAttributeValue("overrideMotionBlurQualityValue")
  self.m_overrideShutterSpeed = el:GetAttributeValue("overrideShutterSpeed")
  self.m_overrideShutterSpeedValue = el:GetAttributeValue("overrideShutterSpeedValue")
end

function sfm.Scene.RenderSettings:__init()
  self.m_frameRate = 24
  self.m_drawToolRenderablesMask = 15
  self.m_engineCameraEffects = false
  self.m_lightAverage = 0
  self.m_toneMapScale = 1.0
  self.m_modelLod = 0
  self.m_ambientOcclusionMode = 1
  self.m_showAmbientOcclusion = 0
  self.m_drawGameRenderablesMask = 216
  self.m_progressiveRefinement = sfm.Scene.RenderSettings.ProgressiveRefinement()
end

function sfm.Scene.RenderSettings:Load(el)
  self.m_frameRate = el:GetAttributeValue("frameRate")
  self.m_drawToolRenderablesMask = el:GetAttributeValue("drawToolRenderablesMask")
  self.m_engineCameraEffects = el:GetAttributeValue("engineCameraEffects")
  self.m_lightAverage = el:GetAttributeValue("lightAverage")
  self.m_toneMapScale = el:GetAttributeValue("toneMapScale")
  self.m_modelLod = el:GetAttributeValue("modelLod")
  self.m_ambientOcclusionMode = el:GetAttributeValue("ambientOcclusionMode")
  self.m_showAmbientOcclusion = el:GetAttributeValue("showAmbientOcclusion")
  self.m_drawGameRenderablesMask = el:GetAttributeValue("drawGameRenderablesMask")
  self.m_progressiveRefinement:Load(el:GetAttributeValue("ProgressiveRefinement"))
end

function sfm.Scene.RenderSettings:GetFrameRate() return self.m_frameRate end
function sfm.Scene.RenderSettings:GetDrawToolRenderablesMask() return self.m_drawToolRenderablesMask end
function sfm.Scene.RenderSettings:GetEngineCameraEffects() return self.m_engineCameraEffects end
function sfm.Scene.RenderSettings:GetLightAverage() return self.m_lightAverage end
function sfm.Scene.RenderSettings:GetToneMapScale() return self.m_toneMapScale end
function sfm.Scene.RenderSettings:GetModelLod() return self.m_modelLod end
function sfm.Scene.RenderSettings:GetAmbientOcclusionMode() return self.m_ambientOcclusionMode end
function sfm.Scene.RenderSettings:GetShowAmbientOcclusion() return self.m_showAmbientOcclusion end
function sfm.Scene.RenderSettings:GetDrawGameRenderablesMask() return self.m_drawGameRenderablesMask end
function sfm.Scene.RenderSettings:GetProgressiveRefinement() return self.m_progressiveRefinement end

util.register_class("sfm.Scene.PosterSettings")
function sfm.Scene.PosterSettings:__init()
  self.m_width = 1920
  self.m_constrainAspect = true
  self.m_height = 1080
  self.m_DPI = 300
  self.m_heightInPixels = true
  self.m_units = 0
  self.m_widthInPixels = true
end

function sfm.Scene.PosterSettings:Load(el)
  self.m_width = el:GetAttributeValue("width")
  self.m_constrainAspect = el:GetAttributeValue("constrainAspect")
  self.m_height = el:GetAttributeValue("height")
  self.m_DPI = el:GetAttributeValue("DPI")
  self.m_heightInPixels = el:GetAttributeValue("heightInPixels")
  self.m_units = el:GetAttributeValue("units")
  self.m_widthInPixels = el:GetAttributeValue("widthInPixels")
end

function sfm.Scene.PosterSettings:GetWidth() return self.m_width end
function sfm.Scene.PosterSettings:GetConstrainAspect() return self.m_constrainAspect end
function sfm.Scene.PosterSettings:GetHeight() return self.m_height end
function sfm.Scene.PosterSettings:GetDPI() return self.m_DPI end
function sfm.Scene.PosterSettings:GetHeightInPixels() return self.m_heightInPixels end
function sfm.Scene.PosterSettings:GetUnits() return self.m_units end
function sfm.Scene.PosterSettings:GetWidthInPixels() return self.m_widthInPixels end

util.register_class("sfm.Scene.Settings")
function sfm.Scene.Settings:__init()
  self.m_movieSettings = sfm.Scene.MovieSettings()
  self.m_timeSelection = sfm.Scene.TimeSelection()
  self.m_proceduralPresets = sfm.Scene.ProceduralPresets()
  self.m_renderSettings = sfm.Scene.RenderSettings()
  self.m_posterSettings = sfm.Scene.PosterSettings()
end

function sfm.Scene.Settings:Load(el)
  self.m_movieSettings:Load(el:GetAttributeValue("movieSettings"))
  self.m_timeSelection:Load(el:GetAttributeValue("timeSelection"))
  -- self.m_sharedPresetGroupSettings = el:GetAttributeValue("sharedPresetGroupSettings")
  -- self.m_graphEditorState = el:GetAttributeValue("graphEditorState")
  self.m_proceduralPresets:Load(el:GetAttributeValue("proceduralPresets"))
  self.m_renderSettings:Load(el:GetAttributeValue("renderSettings"))
  self.m_posterSettings:Load(el:GetAttributeValue("posterSettings"))
end

function sfm.Scene.Settings:GetMovieSettings() return self.m_movieSettings end
function sfm.Scene.Settings:GetTimeSelection() return self.m_timeSelection end
function sfm.Scene.Settings:GetProceduralPresets() return self.m_proceduralPresets end
function sfm.Scene.Settings:GetRenderSettings() return self.m_renderSettings end
function sfm.Scene.Settings:GetPosterSettings() return self.m_posterSettings end

util.register_class("sfm.Scene.Session")
function sfm.Scene.Session:__init(elSession)
  self.m_settings = sfm.Scene.Settings()
  self:Load(elSession)
end

function sfm.Scene.Session:Load(el)
  self.m_settings:Load(el:GetAttributeValue("settings"))
end

function sfm.Scene.Session:GetSettings() return self.m_settings end

