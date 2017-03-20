#include "Globals.h"

#define		C	300000000

__kernel void propagate()
{

}

__kernel void emission(void* g_ParticleBuffer, double* secondsPFrame,
	float3* vertsInParticle, uint* deadlist, float* MVP)
{
	GPUParticleWhole pw;
	float3 temp_loc = vertsInParticle[get_global_id(0)];
	double velocityPFrame = secondsPFrame * C;

	pw.m_Velocity = temp_loc / length(temp_loc) * velocityPFrame;
	pw.m_CollisionCount = 0;
	pw.m_IsSleeping = 0;
	pw.m_Position = MVP * temp_loc;
	GPUParticleWhole *bufLoc = g_ParticleBuffer;
	bufLoc[get_global_id(0)] = pw;
}

__kernel void initDeadList(unsigned int *dlist)
{
	dlist[get_global_id(0)] = get_global_id(0);
}

__kernel void Reset(void* g_ParticleBuffer)
{
	GPUParticleWhole* loc = (GPUParticleWhole*)g_ParticleBuffer;
	loc[ get_global_id(0) ] = GPUParticleWhole();
}