#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define SHADER_POS_BUFFER_LOCATION 0
#define SHADER_RADIUS_BUFFER_LOCATION (SHADER_POS_BUFFER_LOCATION +1)
#define SHADER_PREVPOS_BUFFER_LOCATION (SHADER_RADIUS_BUFFER_LOCATION +1)
#define SHADER_AGE_BUFFER_LOCATION (SHADER_PREVPOS_BUFFER_LOCATION +1)
#define SHADER_COLOR_BUFFER_LOCATION (SHADER_AGE_BUFFER_LOCATION +1)
#define SHADER_ROTATION_BUFFER_LOCATION (SHADER_COLOR_BUFFER_LOCATION +1)
#define SHADER_LENGTH_YAW_BUFFER_LOCATION (SHADER_ROTATION_BUFFER_LOCATION +1)
#define SHADER_ANIMATION_FRAME_INDICES_LOCATION (SHADER_LENGTH_YAW_BUFFER_LOCATION +1)
#define SHADER_ANIMATION_FRAME_INTERP_FACTOR_LOCATION (SHADER_ANIMATION_FRAME_INDICES_LOCATION +1)

#include "/programs/particles/particle_generic.glsl"
#include "particle_animated_sprites.glsl"
#include "/common/inputs/render_settings.glsl"
#include "/common/inputs/camera.glsl"
#include "/programs/particles/particle.glsl"
#include "/programs/particles/vs_particle_vertex.glsl"
#include "/programs/particles/particle_vertex_data.glsl"

#if LIGHTING_ENABLED == 1
//#include "../modules/vs_light.gls"
#endif

void create_matrix_from_axis_angle(vec3 vAxisOfRot, float angleDegrees, out mat3x4 dst)
{
	float radians;
	float axisXSquared;
	float axisYSquared;
	float axisZSquared;
	float fSin;
	float fCos;

	radians = angleDegrees * (M_PI / 180.0);
	fSin = sin(radians);
	fCos = cos(radians);

	axisXSquared = vAxisOfRot[0] * vAxisOfRot[0];
	axisYSquared = vAxisOfRot[1] * vAxisOfRot[1];
	axisZSquared = vAxisOfRot[2] * vAxisOfRot[2];

	dst[0][0] = axisXSquared + (1 - axisXSquared) * fCos;
	dst[1][0] = vAxisOfRot[0] * vAxisOfRot[1] * (1 - fCos) + vAxisOfRot[2] * fSin;
	dst[2][0] = vAxisOfRot[2] * vAxisOfRot[0] * (1 - fCos) - vAxisOfRot[1] * fSin;

	dst[0][1] = vAxisOfRot[0] * vAxisOfRot[1] * (1 - fCos) - vAxisOfRot[2] * fSin;
	dst[1][1] = axisYSquared + (1 - axisYSquared) * fCos;
	dst[2][1] = vAxisOfRot[1] * vAxisOfRot[2] * (1 - fCos) + vAxisOfRot[0] * fSin;

	dst[0][2] = vAxisOfRot[2] * vAxisOfRot[0] * (1 - fCos) + vAxisOfRot[1] * fSin;
	dst[1][2] = vAxisOfRot[1] * vAxisOfRot[2] * (1 - fCos) - vAxisOfRot[0] * fSin;
	dst[2][2] = axisZSquared + (1 - axisZSquared) * fCos;

	dst[0][3] = 0;
	dst[1][3] = 0;
	dst[2][3] = 0;
}

void rotate_vector(vec3 in1, mat3x4 in2, out vec3 outVal)
{
	outVal[0] = dot(in1,vec3(in2[0][0],in2[0][1],in2[0][2]));
	outVal[1] = dot(in1,vec3(in2[1][0],in2[1][1],in2[1][2]));
	outVal[2] = dot(in1,vec3(in2[2][0],in2[2][1],in2[2][2]));
}

void main()
{
	bool useCamBias = (u_instance.cameraBias != 0.0);
	float camBias = u_instance.cameraBias; // TODO???

	float rot = get_particle_rotation();
	float yaw = get_particle_rotation_yaw();

	vec3 vecWorldPos = get_particle_pos();//verts[get_vertex_index()];//get_particle_pos();
	if(useCamBias)
	{
		vec3 vEyeDir = normalize(u_renderSettings.posCam.xyz -vecWorldPos);
		vEyeDir *= camBias;
		vecWorldPos += vEyeDir;
	}

	float rad = get_particle_radius();
	vec3 vecCameraPos = u_renderSettings.posCam.xyz;
	vec3 vecViewToPos = vecWorldPos -vecCameraPos;
	float flLength = length(vecViewToPos);
	if(flLength < rad /2)
		return;

	vec3 vecNormal = vec3(0,0,1);
	vec3 vecRight = vec3(1,0,0);
	vec3 vecUp = vec3(0,-1,0);

	vecUp = normalize(u_instance.camUp_ws);
	vecRight = -normalize(u_instance.camRight_ws);
	vecNormal = normalize(cross(vecUp,vecRight));

	if(yaw != 0.0)
	{
		vec3 particleRight = vec3(1,0,0);
		mat3x4 matRot;
			create_matrix_from_axis_angle( vecUp, yaw, matRot );
			rotate_vector( vecRight, matRot, particleRight );
			vecRight = particleRight;
	}

	vecRight *= rad;
	vecUp *= rad;

	float x, y;
	vec3 vecCorner;

	float ca = cos(-rot);
	float sa = sin(-rot);

	//x = + ca - sa; y = - ca - sa;
	//vecCorner = vecWorldPos +x *vecRight;
	//vecCorner = vecCorner +y *vecUp;




	vec3 verts[4];

	x = + ca - sa; y = - ca - sa;
	vecCorner = vecWorldPos +x *vecRight;
	vecCorner = vecCorner +y *vecUp;
	verts[0] = vecCorner;

	x = + ca + sa; y = + ca - sa;
	vecCorner = vecWorldPos +x *vecRight;
	vecCorner = vecCorner +y *vecUp;
	verts[1] = vecCorner;

	x = - ca + sa; y = + ca + sa;
	vecCorner = vecWorldPos +x *vecRight;
	vecCorner = vecCorner +y *vecUp;
	verts[2] = vecCorner;

	x = - ca - sa; y = - ca + sa;
	vecCorner = vecWorldPos +x *vecRight;
	vecCorner = vecCorner +y *vecUp;
	verts[3] = vecCorner;

	vecWorldPos = verts[get_vertex_index()];//get_corner_particle_vertex_position(vec3(0,0,0),u_instance.orientation);
	vec3 vertexPosition_worldspace = vecWorldPos;
	gl_Position = get_view_projection_matrix() *vec4(vertexPosition_worldspace,1.0);

	vs_out.vert_uv = get_vertex_quad_pos() +vec2(0.5,0.5);
	vs_out.vert_uv = vec2(vs_out.vert_uv.y,1.0 -vs_out.vert_uv.x);
	vs_out.particle_color = in_color;
	// vs_out.particle_start = in_animationStart;
	vs_out.animationFrameIndices = in_animFrameIndices;
	vs_out.animationFrameInterpFactor = in_animInterpFactor;

#if LIGHTING_ENABLED == 1
	vs_out.vert_pos_ws.xyz = vertexPosition_worldspace;
	vs_out.vert_pos_cs = (get_view_matrix() *vec4(vertexPosition_worldspace,0.0)).xyz;
	vec3 n = normalize(vs_out.vert_pos_ws.xyz -vs_out.vert_pos_cs);
	vs_out.vert_normal = n;
	vs_out.vert_normal_cs = (get_view_matrix() *vec4(n,0.0)).xyz;

	//export_light_fragment_data(get_model_matrix() *vec4(vertexPosition_worldspace,1.0));
#endif
}
