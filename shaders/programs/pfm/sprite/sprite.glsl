/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#ifndef F_SH_PFM_SPRITE_GLS
#define F_SH_PFM_SPRITE_GLS

#include "/common/export.glsl"

layout(LAYOUT_PUSH_CONSTANTS()) uniform PushConstants
{
	mat4 MVP;
	vec4 origin;
	// vec4 camRight;
	// vec4 camUp;
	vec4 color;
	vec2 size;
} u_pushConstants;

struct VertexData
{
	vec2 vert_uv;
};

layout(location = 0) EXPORT_VS VertexData
#ifdef GLS_FRAGMENT_SHADER
	fs_in
#else
	vs_out
#endif
;

#endif
