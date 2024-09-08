#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "/common/rma.glsl"

layout(location = 0) in vec2 vs_vert_uv;

layout(LAYOUT_ID(TEXTURES,ALBEDO_MAP)) uniform sampler2D u_albedoMap;
layout(LAYOUT_ID(TEXTURES,NORMAL_MAP)) uniform sampler2D u_normalMap;
layout(LAYOUT_ID(TEXTURES,RMA_MAP)) uniform sampler2D u_rma;

layout(location = 0) out vec4 fs_albedoMap;
layout(location = 1) out vec4 fs_chMask;
layout(location = 2) out vec4 fs_exponentMap;
layout(location = 3) out vec4 fs_normalMap;

float apply_image_level_adjustment(float value,float inLow,float gamma,float inHigh,float outLow,float outHigh)
{
	// See https://stackoverflow.com/a/48859502/2482983
	float gammaCorrection = 1.0 /gamma;
	value *= 255.0;
	value = 255 *((value -inLow) /(inHigh -inLow));

	value = 255 *(pow((value /255),gammaCorrection));

	value = (value /255) *(outHigh -outLow) +outLow;
	return value /255.0;
}

vec3 apply_image_level_adjustment(vec3 color,float inLow,float gamma,float inHigh,float outLow,float outHigh)
{
	return vec3(
		apply_image_level_adjustment(color.r,inLow,gamma,inHigh,outLow,outHigh),
		apply_image_level_adjustment(color.g,inLow,gamma,inHigh,outLow,outHigh),
		apply_image_level_adjustment(color.b,inLow,gamma,inHigh,outLow,outHigh)
	);
}

void main()
{
	// See https://youtu.be/tzej0FcOeUY for details
	vec4 rma = texture(u_rma,vs_vert_uv);

	// TODO: Apply albedo/roughness/metalness/emission factors from material

	float roughness = rma[RMA_CHANNEL_ROUGHNESS];
	float glossiness = 1.0 -roughness;

	vec3 newGloss = vec3(0,0,0);
	newGloss.r = apply_image_level_adjustment(
		glossiness,
		0.0,0.6,255,
		10,255
	);

	const bool hasCavity = false;
	vec3 cavity = vec3(1,1,1); // Currently unused
	if(hasCavity)
		newGloss.r *= cavity.r;

	vec4 normal = texture(u_normalMap,vs_vert_uv);
	normal.a = newGloss.r;

	vec3 oldGloss = vec3(1,1,1);
	oldGloss.r = apply_image_level_adjustment(
		glossiness,
		0.0,0.24,255,
		0,255
	);

	vec4 albedo = texture(u_albedoMap,vs_vert_uv);
	albedo.a = rma[RMA_CHANNEL_METALNESS];

	float invMetalness = 1.0 -rma[RMA_CHANNEL_METALNESS];
	float ao = rma[RMA_CHANNEL_AO];
	albedo.rgb = mix(albedo.rgb,albedo.rgb *ao,invMetalness);
	if(hasCavity)
		albedo.rgb = mix(albedo.rgb,albedo.rgb *cavity,invMetalness *0.5);

	newGloss.r *= 1.0 -apply_image_level_adjustment(
		invMetalness,
		0.0,0.4545,255,
		0,255
	);
	newGloss.r *= ao;

	fs_albedoMap = albedo;
	fs_chMask = vec4(newGloss,1);
	fs_exponentMap = vec4(oldGloss,1);
	fs_normalMap = normal;
}
