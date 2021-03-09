/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define SHADER_VERTEX_BUFFER_LOCATION 0
#define SHADER_COLOR_BUFFER_LOCATION 1
#define SHADER_BONE_INDEX_BUFFER_LOCATION 2

#define SHADER_UNIFORM_BONE_MATRIX_SET 0
#define SHADER_UNIFORM_BONE_MATRIX_BINDING 0

#define SHADER_UNIFORM_CAMERA_SET 0
#define SHADER_UNIFORM_CAMERA_BINDING 0

#include "../../modules/sh_limits.gls"
#include "../../modules/sh_camera_info.gls"
#include "sh_grid.gls"
/*
layout(std140,LAYOUT_ID(SHADER_UNIFORM_BONE_MATRIX_SET,SHADER_UNIFORM_BONE_MATRIX_BINDING)) uniform Bones
{
	mat4 matrices[MAX_BONES];
} u_bones;
*/
layout(location = SHADER_VERTEX_BUFFER_LOCATION) in vec3 in_vert_pos;
//layout(location = SHADER_COLOR_BUFFER_LOCATION) in vec4 in_vert_color;
//layout(location = SHADER_BONE_INDEX_BUFFER_LOCATION) in int in_vert_bone;

layout(LAYOUT_PUSH_CONSTANTS()) uniform Data {
	mat4 M;
	vec4 gridOrigin; // w component is scale
	float radius;
} u_data;

void main()
{
	vec4 pos = u_data.M *vec4(in_vert_pos *u_data.gridOrigin.w,1.0);
	vs_out.vertPos_ws = vec4(pos.xyz,u_data.radius);
	//if(in_vert_bone >= 0)
	//	pos = u_bones.matrices[in_vert_bone] *pos;
	gl_Position = u_camera.VP *pos;
	//vs_out.frag_col = in_vert_color;
}