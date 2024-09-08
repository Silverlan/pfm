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

#include "grid.glsl"
#include "/programs/gui/vs_shared.glsl"

void main()
{
	vec2 basePos = in_vert_pos;
	basePos *= u_pushConstants.vMultiplier;
	float stride = u_pushConstants.strideV;
	if(u_pushConstants.horizontal == 1)
		basePos.y = -1.0 +SH_INSTANCE_INDEX *stride;
	else
		basePos.x = -1.0 +SH_INSTANCE_INDEX *stride;
	vec2 vertPos = get_vertex_position(basePos).xy;
	gl_Position = vec4(vertPos,0,1);
}
