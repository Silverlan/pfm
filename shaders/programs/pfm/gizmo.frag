#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define DEBUG_MODE DEBUG_MODE_NONE

#include "/common/inputs/textures/albedo_map.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"
#include "/common/vertex_outputs/vertex_data.glsl"

void main()
{
	vec4 albedoColor = texture(u_albedoMap,get_vertex_uv());
	fs_color = albedoColor;
	vec4 colorMod = get_instance_color();
	fs_color.r *= colorMod.r;
	fs_color.g *= colorMod.g;
	fs_color.b *= colorMod.b;
	//if(CSPEC_BLOOM_OUTPUT_ENABLED == 1)
	//	extract_bright_color(fs_color);
}
