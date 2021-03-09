/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "sh_grid.gls"

layout(location = 0) out vec4 fs_color;

bool is_grid_spacing(float v)
{
	const float e = 0.1;
	return mod(abs(fs_in.vertPos_ws.x) +e,v) <= e *2.0 || mod(abs(fs_in.vertPos_ws.z) +e,v) <= e *2.0;
}

layout(LAYOUT_PUSH_CONSTANTS()) uniform Data {
	mat4 M;
	vec4 gridOrigin; // w component is scale
	float radius;
} u_data;

void main()
{
	float a = min(1.0 -min(length(fs_in.vertPos_ws.xyz -u_data.gridOrigin.xyz) /fs_in.vertPos_ws.w,1.0),1.0);
	fs_color = vec4(0,0,0,a);

	if(abs(fs_in.vertPos_ws.x -u_data.gridOrigin.x) < 0.1 || abs(fs_in.vertPos_ws.z -u_data.gridOrigin.z) < 0.1)
		fs_color.rgb = vec3(1,1,0);
	else
	{
		fs_color.a *= 0.8;
		if(is_grid_spacing(100.0))
			fs_color.b = 1.0;
		else if(is_grid_spacing(50.0))
			fs_color.g = 1.0;
		else if(is_grid_spacing(10.0))
			fs_color.r = 1.0;
	}
}
