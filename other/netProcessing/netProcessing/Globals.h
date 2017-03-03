class GPUParticleWhole
{
private:
	float4	m_TintAndAlpha;			// The color and opacity
	float2	m_VelocityXY;			// View space velocity XY used for streak extrusion
	float	m_EmitterNdotL;			// The lighting term for the while emitter
	uint	m_EmitterProperties;	// The index of the emitter in 0-15 bits, 16-23 for atlas index, 24th bit is whether or not the emitter supports velocity-based streaks

	float	m_Rotation;				// The rotation angle
	uint	m_IsSleeping;			// Whether or not the particle is sleeping (ie, don't update position)
	uint	m_CollisionCount;		// Keep track of how many times the particle has collided
	float	m_pads[1];

	//PART B

	float3	m_Position;				// World space position
	float	m_Mass;					// Mass of particle

	float3	m_Velocity;				// World space velocity
	float	m_Lifespan;				// Lifespan of the particle.

	float	m_DistanceToEye;		// The distance from the particle to the eye
	float	m_Age;					// The current age counting down from lifespan to zero
	float	m_StartSize;			// The size at spawn time
	float	m_EndSize;				// The time at maximum age

	GPUParticleWhole();
	void reset();
}

GPUParticleWhole::GPUParticleWhole()
{
	m_TintAndAlpha = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
	m_VelocityXY = (float2)(0.0f, 0.0f);
	m_EmitterNdotL 0;
	m_EmitterProperties = 0;

	m_Rotation = 0;
	m_IsSleeping = 0;
	m_CollisionCount = 0;
	m_pads[0] = 0;


	m_Position = (float3)(0.0f, 0.0f, 0.0f);
	m_Mass = 0;

	m_Velocity = (float3)(0.0f, 0.0f, 0.0f);
	m_Lifespan = 0;

	m_DistanceToEye = 0;
	m_Age = 0;
	m_StartSize = 0;
	m_EndSize = 0;

}
void GPUParticleWhole::reset()
{
	m_TintAndAlpha = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
	m_VelocityXY = (float2)(0.0f, 0.0f);
	m_EmitterNdotL 0;
	m_EmitterProperties = 0;

	m_Rotation = 0;
	m_IsSleeping = 0;
	m_CollisionCount = 0;
	m_pads[0] = 0;


	m_Position = (float3)(0.0f, 0.0f, 0.0f);
	m_Mass = 0;

	m_Velocity = (float3)(0.0f, 0.0f, 0.0f);
	m_Lifespan = 0;

	m_DistanceToEye = 0;
	m_Age = 0;
	m_StartSize = 0;
	m_EndSize = 0;

}