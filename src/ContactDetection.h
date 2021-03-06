/*
 * ContactDetection.h
 *
 *  Created on: 01/02/2016
 *      Author: bruno
 */

#ifndef CONTACTDETECTION_H_
#define CONTACTDETECTION_H_

#include <cstdlib>
#include <cstdio>
#include <string>

#include "helper_math.h"
#include "aux.h"

class ContactDetection {
public:
	ContactDetection(){}
	virtual ~ContactDetection(){}

	virtual void memInitialize() = 0;

	virtual void createNeighboorList(float4 *dPos, float4 *dVel) = 0;

	virtual void calculateContactForce(float4 *dPos, float4 *dVel, float4 *dFor) = 0;

	virtual void setParams(SysParams params) = 0;

	virtual std::string getName() = 0;
};

#endif /* CONTACTDETECTION_H_ */
