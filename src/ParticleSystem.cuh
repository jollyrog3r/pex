/*
 * ParticleSystem.cuh
 *
 *  Created on: 27/01/2016
 *      Author: bruno
 */

#ifndef PARTICLESYSTEM_CUH_
#define PARTICLESYSTEM_CUH_

#include "ParticleSystem.h"

extern __constant__
SysParams system_params;

__global__
void integrate_system(float4 *pos, float4 *vel, float4* obstacles,
			float dt, unsigned int n_particles, unsigned int n_obstacles);

#endif /* PARTICLESYSTEM_CUH_ */
