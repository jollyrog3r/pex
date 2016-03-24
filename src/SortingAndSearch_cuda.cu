/*
 * SortingAndSearch_cuda.cu
 *
 *  Created on: 19/03/2016
 *      Author: bruno
 */

#include "SortingAndSearch.h"
#include "aux.h"
#include "helper_cuda.h"
#include "helper_math.h"
#include "World.cuh"

#include <cuda.h>
#include <thrust/sort.h>
#include <thrust/device_ptr.h>
#include <thrust/binary_search.h>

#define EMPTY 0xffffffff

extern __constant__
SysParams system_params;

struct particle_before : public thrust::binary_function<uint4, uint4, bool>{
	__host__ __device__
	bool operator()(const uint4 &left, const uint4 &right) const{
		return (left.z < right.z) || (left.z == right.z && left.y < right.y) ||
				(left.z == right.z && left.y == right.y && left.x < right.x);
	}
};



__global__
void prepare_grid(unsigned int *dSortedGrid, float4 *dPos,
		unsigned int n_particles, float3 p_min, float d)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	if(idx>=n_particles) return;

	int3 gridPos = get_grid_pos(make_float3(dPos[idx]), p_min, d);

	dSortedGrid[idx].x = gridPos.x;
	dSortedGrid[idx].y = gridPos.y;
	dSortedGrid[idx].z = gridPos.z;
	dSortedGrid[idx].w = idx;

}


void SortingAndSearch::prepareGrid(float4 *dPos){
	unsigned int numThreads, numBlocks;
	computeGridSize(n_particles, 256, &numBlocks, &numThreads);

	prepare_grid<<<numBlocks, numThreads>>>(dSortedGrid, dPos, n_particles,
			p_min, d);

	getLastCudaError("Kernel execution failed: prepare_grid");
}

void SortingAndSearch::sortParticles(){
	thrust::sort(thrust::device_ptr<uint4>(dSortedGrid),
			thrust::device_ptr<uint4>(dSortedGrid + n_particles),
			less());
}

__global__
void reorder_pos_vel(float4 *sortedPos, float4 *sortedVel,
		uint4 *dSortedGrid, float4 *oldPos, float4 *oldVel,
        unsigned int n_particles)
{

	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	if(idx >= n_particles) return;

	uint p_id = dSortedGrid[idx].w;

	sortedPos[idx] = oldPos[p_id];
	sortedVel[idx] = oldVel[p_id];
}

void SortingAndSearch::reorderPosAndVel(float4 *dPos, float4 *dVel){
	unsigned int numBlocks, numThreads;
	computeGridSize(n_particles, 256, &numBlocks, &numThreads);

	reorder_pos_vel<<<numBlocks, numThreads>>>(dSortedPos, dSortedVel,
			dSortedGrid, dPos, dVel, n_particles);

	getLastCudaError("Kernel execution failed: reorder_pos_vel");
}

__global__
void calculate_contact_force(float4 *sortedPos, float4 *sortedVel,
		uint4 *dSortedGrid, float4 *force, unsigned int n_particles,
		float3 pMin, float d, int3 gridDim)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if(idx >= n_particles) return;

	float3 pos = make_float3(sortedPos[idx]);
	float3 vel = make_float3(sortedVel[idx]);

	int3 gridPos = get_grid_pos(pos, pMin, d);

	float3 resulting_force = make_float3(0);

	float r = system_params.particle_radius;

	for(int z = -1; z <= 1; z++){
		for(int y = -1; y <= 1; y++){
			// get index of first x-1 continue until x != x+1
			if(cell.y < 0 || cell.z < 0 ||
					cell.y >= gridDim.y || cell.z >= gridDim.z)
				continue;

			int x = gridPos.x-1 >=0 ? gridPos.x-1: gridPos.x;

			uint4 = make_uint4(x, gridPos.y + y, gridPos.z + z);
			int start = thrust::lower_bound(thrust::device_ptr<uint4>(dSortedGrid),
					thrust::device_ptr<uint4>(dSortedGrid + n_particles),
					less());
//			for(int x = -1; x <= 1; x++)
//			{
//                                int3 cell = gridPos + make_int3(x,y,z);
//
//
//				unsigned int hash =  makeHash(cell);
//				unsigned int start_idx = cellStart[hash];
//
//				if(start_idx != EMPTY){
//					unsigned int end_idx = cellEnd[hash];
//
//					for(unsigned int i=start_idx; i< end_idx; i++){
//						if(i == idx) continue; // jumps self
//						float3 neigh_pos = make_float3(sortedPos[i]);
//						float3 neigh_vel = make_float3(sortedVel[i]);
//
//						resulting_force += World::contactForce(pos, neigh_pos,
//								vel, neigh_vel, r, r);
//					}
//				}
//			}
		}
	}

	force[gridParticleIndex[idx]] = make_float4(resulting_force);
}

void SortingAndSearch::calculateContactForce(float4 *dPos, float4 *dVel, float4 *dFor){
	// will not use dPos and dVel since i have my own version stored
	unsigned int numBlocks, numThreads;
	computeGridSize(n_particles, 256, &numBlocks, &numThreads);

	calculate_contact_force<<<numBlocks, numThreads>>>(dSortedPos, dSortedVel,
			dSortedGrid, dFor, n_particles, p_min, d, gridSize);

	getLastCudaError("Kernel execution failed: calculate_contact_force");
}


