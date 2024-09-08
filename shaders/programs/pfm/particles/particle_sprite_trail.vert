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
#include "particle_sprite_trail.glsl"
#include "/common/inputs/render_settings.glsl"
#include "/common/inputs/camera.glsl"
#include "/programs/particles/particle.glsl"
#include "/programs/particles/vs_particle_vertex.glsl"
#include "/programs/particles/particle_vertex_data.glsl"

#if LIGHTING_ENABLED == 1
//#include "../modules/vs_light.gls"
#endif

void main()
{
	vec3 vecWorldPos = get_particle_pos();//get_particle_vertex_position(u_instance.camPos);

	vec3 curPosWs = get_particle_pos();
	vec3 prevPosWs = get_prev_particle_pos();
	vec3 dtPosWs = prevPosWs -curPosWs;
	float l = length(dtPosWs);
	dtPosWs = normalize(dtPosWs);
	// float flOODt = ( pParticles->m_flDt != 0.0f ) ? ( 1.0f / pParticles->m_flDt ) : 1.0f;
	// TODO
	float age = get_particle_age();
	float lengthScale = (age >= u_instance.lengthFadeInTime) ? 1.0 : (age /u_instance.lengthFadeInTime);
	float ptLen = get_particle_length();
	l = lengthScale *l *ptLen;
	l = log(l +2) *12; // This makes it match Source Engine behavior more closely, but I'm unsure why. TODO: FIXME (Try using deltaTime as factor instead?)
	if(l <= 0.0)
		return;
	l = clamp(l,u_instance.minLength,u_instance.maxLength);

	float rad = min(get_particle_radius(),l);
	dtPosWs *= l;

	vec3 vDirToBeam = vecWorldPos -u_renderSettings.posCam.xyz;
	vec3 vTangentY = cross(vDirToBeam,dtPosWs);
	vTangentY = normalize(vTangentY);

	vec3 verts[4];
	verts[0] = vecWorldPos -vTangentY *rad *0.5;
	verts[1] = vecWorldPos +vTangentY *rad *0.5;
	verts[3] = verts[0] +dtPosWs;
	verts[2] = verts[1] +dtPosWs;

	//verts[0] = vecWorldPos +vec3(0.5,-0.5,0) *100;
	//verts[1] = vecWorldPos +vec3(-0.5,-0.5,0) *100;
	//verts[2] = vecWorldPos +vec3(-0.5,0.5,0) *100;
	//verts[3] = vecWorldPos +vec3(0.5,0.5,0) *100;

	vec3 vertexPosition_worldspace = verts[get_vertex_index()];//get_particle_vertex_position(u_instance.camPos);//verts[0];


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
