/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#ifndef F_SH_GRID_GLS
#define F_SH_GRID_GLS

layout(LAYOUT_PUSH_CONSTANTS()) uniform PushConstants
{
	mat4 modelMatrix;
	vec4 color;
	uint instanceCount;
	float strideV;
	float vMultiplier;
	uint horizontal;
    uint viewportSize;
} u_pushConstants;

#endif
