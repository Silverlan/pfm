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

#include "timeline.glsl"
#include "/programs/gui/vs_shared.glsl"

void main()
{
	vec2 basePos = in_vert_pos;
	float y = basePos.y;
	if((SH_INSTANCE_INDEX %5) != 0)
		y = (y *0.5) -0.5;
	else if((SH_INSTANCE_INDEX %10) != 0)
		y = (y *0.8) -0.2;
	y *= u_pushConstants.yMultiplier;
	if(u_pushConstants.horizontal == 1)
	{
		basePos.x = -1.0 +SH_INSTANCE_INDEX *u_pushConstants.strideX;
		basePos.y = y;
	}
	else
	{
		basePos.y = -1.0 +SH_INSTANCE_INDEX *u_pushConstants.strideX;
		basePos.x = y;
	}
	vec2 vertPos = get_vertex_position(basePos).xy;
	gl_Position = vec4(vertPos,0,1);
}
