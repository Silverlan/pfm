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
#include "/common/inputs/entity.glsl"

void main()
{
	fs_color = u_instance.data.color;
	extract_bright_color(fs_color);
}