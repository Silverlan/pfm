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

#include "curve.glsl"
#include "/programs/gui/vs_shared.glsl"

void main()
{
	vec2 basePos = vec2(
		(in_vert_pos[0] -u_pushConstants.xRange[0]) /(u_pushConstants.xRange[1] -u_pushConstants.xRange[0]),
		(in_vert_pos[1] -u_pushConstants.yRange[1]) /(u_pushConstants.yRange[0] -u_pushConstants.yRange[1])
	);
	basePos *= 2.0;
	basePos -= 1.0;
	vec4 pos = get_vertex_position(basePos);

	gl_Position = vec4(pos.xy,0.0,1.0);
}
