#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "/programs/scene/vs_world.glsl"
#include "/common/inputs/material.glsl"

void main()
{
	vec3 camPos = u_renderSettings.posCam.xyz;
	vec3 vertexPos = in_vert_pos.xyz;
	vertexPos = (get_model_matrix() *vec4(vertexPos,1.0)).xyz;
	float distance = length(vertexPos -camPos);

	float fov = get_fov();
	float scalingFactor = get_mat_outline_width();
	float distanceScale = get_mat_scale_by_distance_factor();
	if(distanceScale > 0.0)
		scalingFactor *= distance *fov *distanceScale; // Scale to keep the same size regardless of the distance to the camera
	else
		scalingFactor *= 80; // Arbitrary factor to roughly match the same size of the scaling factor in the other case if the distance to the model is ~3 meters

	export_world_fragment_data(in_vert_pos.xyz +in_vert_normal.xyz *scalingFactor, false, false);
}
