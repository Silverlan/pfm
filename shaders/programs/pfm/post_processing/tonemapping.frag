#version 400

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 vs_vert_uv;

layout(LAYOUT_ID(TEXTURE, TEXTURE)) uniform sampler2D u_texture;

layout(LAYOUT_PUSH_CONSTANTS()) uniform RenderSettings {
	float exposure;
	int toneMapping;

	uint ldrInputTexture;
	float placeholder; // Unused

	vec4 avgIntensity; // a is unused
	float minLuminance;
	float maxLuminance;
	float logAvgLuminance;

	// Algorithm-specific parameters
	float arg0;
	float arg1;
	float arg2;
	float arg3;
	float arg4;
} u_renderSettings;

layout(location = 0) out vec4 fs_color;

#include "/common/fs_tonemapping.glsl"
#include "fs_tonemapping_tizian.glsl"

#define TONE_MAPPING_WARD TONE_MAPPING_COUNT
#define TONE_MAPPING_FERWERDA (TONE_MAPPING_WARD +1)
#define TONE_MAPPING_SCHLICK (TONE_MAPPING_FERWERDA +1)
#define TONE_MAPPING_TUMBLIN_RUSHMEIER (TONE_MAPPING_SCHLICK +1)
#define TONE_MAPPING_DRAGO (TONE_MAPPING_TUMBLIN_RUSHMEIER +1)
#define TONE_MAPPING_REINHARD_DEVLIN (TONE_MAPPING_DRAGO +1)
#define TONE_MAPPING_FILMLIC1 (TONE_MAPPING_REINHARD_DEVLIN +1)
#define TONE_MAPPING_FILMLIC2 (TONE_MAPPING_FILMLIC1 +1)
#define TONE_MAPPING_INSOMNIAC (TONE_MAPPING_FILMLIC2 +1)

void main()
{
	vec4 col = texture(u_texture,vs_vert_uv);

	if(u_renderSettings.ldrInputTexture == 1)
	{
		// Input image is already a gamma-corrected LDR image (probably a preview image).
		// We'll undo the gamma-correction, however the tone-mapping won't be as accurate as for
		// a HDR image.
		col.rgb = srgb_to_linear(col.rgb);
	}

	float avgLuminance = u_renderSettings.avgIntensity[3];
	switch(u_renderSettings.toneMapping)
	{
		case TONE_MAPPING_NONE:
		case -1:
			break;
		case TONE_MAPPING_WARD:
			col.rgb = ward(col.rgb *u_renderSettings.exposure,u_renderSettings.logAvgLuminance,u_renderSettings.arg0,u_renderSettings.exposure);
			break;
		case TONE_MAPPING_FERWERDA:
			col.rgb = ferwerda(col.rgb *u_renderSettings.exposure,u_renderSettings.maxLuminance /2.0,u_renderSettings.arg0,u_renderSettings.exposure);
			break;
		case TONE_MAPPING_SCHLICK:
			col.rgb = schlick(col.rgb *u_renderSettings.exposure,u_renderSettings.arg0,u_renderSettings.maxLuminance,u_renderSettings.exposure);
			break;
		case TONE_MAPPING_TUMBLIN_RUSHMEIER:
			col.rgb = tumblin_rushmeier(col.rgb *u_renderSettings.exposure,avgLuminance,u_renderSettings.arg0,u_renderSettings.arg1,u_renderSettings.exposure);
			break;
		case TONE_MAPPING_DRAGO:
			col.rgb = drago(
				col.rgb *u_renderSettings.exposure,u_renderSettings.logAvgLuminance,u_renderSettings.maxLuminance,
				u_renderSettings.arg0,u_renderSettings.arg1,u_renderSettings.arg2,u_renderSettings.arg3,u_renderSettings.exposure
			);
			break;
		case TONE_MAPPING_REINHARD_DEVLIN:
			col.rgb = reinhard_devlin(
				col.rgb *u_renderSettings.exposure,u_renderSettings.arg0,u_renderSettings.arg1,u_renderSettings.arg2,u_renderSettings.arg3,
				avgLuminance,u_renderSettings.avgIntensity.rgb,u_renderSettings.exposure
			);
			break;
		case TONE_MAPPING_FILMLIC1:
			col.rgb = filmic1(col.rgb *u_renderSettings.exposure);
			break;
		case TONE_MAPPING_FILMLIC2:
			col.rgb = filmic2(col.rgb *u_renderSettings.exposure,u_renderSettings.arg0);
			break;
		case TONE_MAPPING_INSOMNIAC:
			col.rgb = insomniac(col.rgb *u_renderSettings.exposure,avgLuminance,u_renderSettings.arg0,u_renderSettings.arg1,u_renderSettings.arg2,u_renderSettings.arg3,u_renderSettings.arg4);
			break;
		default:
			col.rgb = apply_tone_mapping(col.rgb,u_renderSettings.toneMapping,u_renderSettings.exposure);
			break;
	}
	fs_color = col;
}
