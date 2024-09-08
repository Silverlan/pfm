#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "/common/inputs/material.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"

void main()
{
	fs_color = u_material.material.color;
	extract_bright_color(fs_color *u_material.material.glowScale);
}