#version 400

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 vs_vert_uv;

layout(LAYOUT_ID(0,0)) uniform sampler2D u_texture;

layout(LAYOUT_PUSH_CONSTANTS()) uniform PushConstants {
	mat4 modelMatrix;
	vec4 color;
	int alphaOnly;
	float lod;
	uint channels;
} u_pushConstants;

layout(location = 0) out vec4 fs_color;

#include "/common/color.glsl"
#include "/math/math.glsl"

void main()
{
	float h = 0.0;
	float s = 1.0;
	float v = 1.0;
	vec2 uv = (vs_vert_uv -0.5) *2;
	float l = length(uv);
	if(l > 1.0)
		discard;
	h = atan2(uv.x,-uv.y);
	s = l;
	vec3 rgb = hsv_to_rgb(vec3(h /(M_PI *2),s,v));
	fs_color = vec4(rgb,1);
	fs_color *= u_pushConstants.color;
}
