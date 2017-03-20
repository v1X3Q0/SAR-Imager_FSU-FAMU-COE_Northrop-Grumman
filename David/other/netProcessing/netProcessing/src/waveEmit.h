#pragma once
#include "helper.h"

#define		MAX_PART	1024 * 1024

class wave_emit
{
private:
	cl_int status;

	cl_context context;
	cl_device_id *device;
	cl_command_queue cq;

	cl_kernel iDLKern, proKern, emiKern, resKern;
	cl_program waveProgram;
	cl_mem deadList, c_ParticleBuffer;

	cl_bool chgTRPair;

	double secondsPFrame;

	void* output;
	enum { rLEFT = 1, rRIGHT, rTOP, rBOTTOM } tAntXY;
	unsigned short rAntXY;
	//16 bits, left of antenna to right, then top of antenna to bottom
public:
	int init(cl_context, cl_device_id*, cl_command_queue);
	int genEmitter();
	int initDeadList();
	int cleanup();
	int setStuff();
	int run();
	int chngPair();
};