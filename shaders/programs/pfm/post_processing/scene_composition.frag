#version 400

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 vs_vert_uv;

layout(LAYOUT_ID(TEXTURES, HDR_IMAGE)) uniform sampler2D u_texture;
layout(LAYOUT_ID(TEXTURES, BLOOM)) uniform sampler2D u_bloom;
layout(LAYOUT_ID(TEXTURES, GLOW)) uniform sampler2D u_glow;

layout(LAYOUT_PUSH_CONSTANTS()) uniform RenderSettings {
	float bloomScale;
	float glowScale;
} u_renderSettings;

layout(location = 0) out vec4 fs_color;

void main()
{
	vec4 col = texture(u_texture,vs_vert_uv);
	vec3 colBloom = texture(u_bloom,vs_vert_uv).rgb;
	col.rgb += colBloom *u_renderSettings.bloomScale;

	vec3 colGlow = texture(u_glow,vs_vert_uv).rgb;
	col.rgb += colGlow *u_renderSettings.glowScale;
	fs_color = col;
	fs_color.a = 1.0; // Without this, the Cycles image is invisible. TODO: Why?
}
