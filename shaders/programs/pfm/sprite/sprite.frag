/*
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) out vec4 fs_color;
layout(location = 1) out vec4 fs_bloomColor;

layout(LAYOUT_ID(TEXTURE, TEXTURE)) uniform sampler2D u_texture;

#include "sprite.glsl"

void main()
{
	fs_color = texture(u_texture,fs_in.vert_uv) *u_pushConstants.color;
	fs_bloomColor = vec4(0,0,0,0);
}