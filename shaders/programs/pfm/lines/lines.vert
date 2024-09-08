/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec3 in_vert_pos;

#include "lines.glsl"

void main()
{
	vec4 vpos = u_pushConstants.MVP *vec4(in_vert_pos,1.0);
	gl_Position = vpos;
}
