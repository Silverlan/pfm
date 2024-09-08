/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#ifndef F_SH_MDE_SKELETON_GLS
#define F_SH_MDE_SKELETON_GLS

#include "/common/export.glsl"

#define SHADER_VERTEX_DATA_LOCATION 0

layout(location = SHADER_VERTEX_DATA_LOCATION) EXPORT_VS VS_OUT
{
	vec4 vertPos_ws;
}
#ifdef GLS_FRAGMENT_SHADER
	fs_in
#else
	vs_out
#endif
;

#endif
