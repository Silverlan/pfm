/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 400

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 in_vert_pos;
layout(location = 1) in vec2 in_vert_uv;

layout(location = 0) out vec2 vs_vert_uv;
layout(location = 1) out vec3 vs_vert_world_dir;

layout(LAYOUT_PUSH_CONSTANTS()) uniform PushConstants
{
    mat4 invViewProjection;
} u_pushConstants;

void main()
{
	gl_Position = vec4(in_vert_pos,0.0,1.0);
	vs_vert_uv = in_vert_uv;
	mat4 vp = u_pushConstants.invViewProjection;
	vs_vert_world_dir = (vp *vec4(in_vert_uv.x *2.0 -1.0,in_vert_uv.y *2.0 -1.0,0,1)).xyz;
}
