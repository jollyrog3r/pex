/*
 * World.cpp
 *
 *  Created on: 29/01/2016
 *      Author: bruno
 */

#include "World.cuh"
#include "ParticleSystem.cuh"
#include "helper_math.h"
#include "ParticleSystem.h"

extern __constant__
SysParams system_params;

__device__
void World::checkBoudaries(float4* pos, float4* vel)
{
	// impede as partículas de passarem pelas bordas
	if (pos->x > system_params.p_max.x - system_params.particle_radius)
	{
		pos->x = system_params.p_max.x - system_params.particle_radius;
		vel->x *= system_params.boundary_damping;
	}

	if (pos->x < system_params.p_min.x + system_params.particle_radius)
	{
		pos->x = system_params.p_min.x + system_params.particle_radius;
		vel->x *= system_params.boundary_damping;
	}

	if (pos->y > system_params.p_max.y - system_params.particle_radius)
	{
		pos->y = system_params.p_max.y - system_params.particle_radius;
		vel->y *= system_params.boundary_damping;
	}
	if (pos->y < system_params.p_min.y + system_params.particle_radius)
	{
		pos->y = system_params.p_min.y + system_params.particle_radius;
		vel->y *= system_params.boundary_damping;
	}

	if (pos->z > system_params.p_max.z - system_params.particle_radius)
	{
		pos->z = system_params.p_max.z - system_params.particle_radius;
		vel->z *= system_params.boundary_damping;
	}

	if (pos->z < system_params.p_min.z + system_params.particle_radius)
	{
		pos->z = system_params.p_min.z + system_params.particle_radius;
		vel->z *= system_params.boundary_damping;
	}

}

__device__
float3 World::contactForce(float3 posA, float3 posB,
		float3 velA, float3 velB,
        float radiusA, float radiusB)
{
	float3 relPos = posB - posA;

	float dist = length(relPos);
	float collideDist = radiusA + radiusB;

	float3 force = make_float3(0);

	if(dist < collideDist){
		float3 norm = relPos / dist;

		// relative velocity
		float3 relVel = velB - velA;

		// relative tangential velocity
		float3 tanVel = relVel - (dot(relVel, norm) * norm);

		// spring force
		force = system_params.spring*(collideDist - dist) * norm;
		// dashpot (damping) force // damping = 0.02
		force += system_params.damping*relVel;
		// tangential shear force
		force += system_params.shear*tanVel;

	}

	return force;
}





