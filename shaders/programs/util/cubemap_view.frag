/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 400

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 vs_vert_uv;
layout(location = 1) in vec3 vs_vert_world_dir;

layout(location = 0) out vec4 fs_color;

#include "/math/equirectangular.glsl"

layout(LAYOUT_ID(TEXTURE, TEXTURE)) uniform sampler2D u_texture;

void main()
{
	vec3 dir = normalize(vec3(0,1,0) +vec3(vs_vert_uv.x,0,vs_vert_uv.y));
	float horizontalRange = 360.0;
	vec2 uv = direction_to_equirectangular_uv_coordinates(normalize(vs_vert_world_dir),360.0 /horizontalRange);

	float zoom = 1.0;
	uv -= 0.5;
	uv *= zoom;
	uv += 0.5;

	vec2 uvFactor = vec2(1,1);
	vec2 uvOffset = vec2(0,0);
	uv = (uv *uvFactor) +uvOffset;

	fs_color = texture(u_texture,uv);
}
