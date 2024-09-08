/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#ifndef F_SH_CURVE_GLS
#define F_SH_CURVE_GLS

layout(LAYOUT_PUSH_CONSTANTS()) uniform PushConstants
{
    mat4 modelMatrix;
	vec4 color;
	vec2 xRange;
	vec2 yRange;
    uint viewportSize;
} u_pushConstants;

#endif
