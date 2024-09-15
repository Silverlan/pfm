#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "/common/inputs/material.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"

void main()
{
	fs_color = vec4(get_mat_color_factor(), get_mat_alpha_factor());
	extract_bright_color(fs_color *get_mat_glow_factor());
}