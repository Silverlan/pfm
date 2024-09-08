/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 in_vert_pos;
layout(location = 1) in vec2 in_vert_uv;

#include "sprite.glsl"

void main()
{
	vec3 vpos = u_pushConstants.origin.xyz;
		//-u_pushConstants.camRight.xyz *in_vert_pos.x *10.0
		//+u_pushConstants.camUp.xyz *in_vert_pos.y *10.0;

	vs_out.vert_uv = in_vert_uv;

	gl_Position = u_pushConstants.MVP *vec4(vpos,1.0);
	gl_Position /= gl_Position.w;
	gl_Position.xy += in_vert_pos.xy *u_pushConstants.size *2;
}
