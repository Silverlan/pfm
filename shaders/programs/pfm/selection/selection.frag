/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "selection.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"

void main()
{
	fs_color = vec4(0,128,255,255) /255.0;//u_pushConstants.selectionColor;
	extract_bright_color(fs_color);
}