#include "waveEmit.h"

using namespace appsdk;

int wave_emit::init(cl_context context_, cl_device_id *device_, cl_command_queue cq_)
{
	context = context_;
	device = device_;
	cq = cq_;
	const char *filename = "assets/waveEmit.cl";
	string sourceStr;
	status = convertToString(filename, sourceStr);
	const char *source = sourceStr.c_str();
	size_t sourceSize[] = { strlen(source) };
	waveProgram = clCreateProgramWithSource(context_, 1, &source, sourceSize, NULL);
	status = clBuildProgram(waveProgram, 1, device, NULL, NULL, NULL);

	iDLKern = clCreateKernel(waveProgram, "initDeadList", NULL);
	proKern = clCreateKernel(waveProgram, "propagate", NULL);
	emiKern = clCreateKernel(waveProgram, "emission", NULL);
	resKern = clCreateKernel(waveProgram, "Reset", NULL);

	vector<glm::vec3> vertices, normals;
	loadOBJ("assets/particleEmission.obj", vertices, normals);
	GLuint vertexObj;
	// Create Vertex buffer object
	glGenBuffers(1, &vertexObj);
	glBindBuffer(GL_ARRAY_BUFFER, vertexObj);
//	glBufferData(GL_ARRAY_BUFFER, vertices.size, (GLvoid *)vertices.data(), GL_DYNAMIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	// create OpenCL buffer from GL VBO
	cl_mem posBuf = clCreateFromGLBuffer(context, CL_MEM_WRITE_ONLY, vertexObj, &status);
	CHECK_OPENCL_ERROR(status, "clCreateFromGLBuffer failed. (posBuf)");

	//initialize our deadlist buffer
	deadList = clCreateBuffer(context, CL_MEM_READ_WRITE, MAX_PART * sizeof(cl_uint), NULL, NULL);
	deadList = clCreateBuffer(context, CL_MEM_READ_WRITE, MAX_PART * sizeof(cl_uint), NULL, NULL);
	//status = clSetKernelArg(iDLKern, 0, sizeof(cl_mem), (void *)&inputBuffer);

	//align(g_maxParticles, 256) / 256, 1, 1 )

	tAntXY = rLEFT;
	rAntXY = 0x0001;

	return SDK_SUCCESS;
}

int wave_emit::initDeadList()
{
	size_t size = MAX_PART;

	status = clSetKernelArg(iDLKern, 0, sizeof(cl_uint) * MAX_PART, (void*)&deadList);
	status = clEnqueueNDRangeKernel(cq, iDLKern, 1, NULL, &size, NULL, 0, NULL, NULL);

	//status = clEnqueueTask(cq, iDLKern, 1, NULL, NULL);
	return SDK_SUCCESS;
}

int wave_emit::cleanup()
{
	//status = clReleaseMemObject(inputBuffer);		//Release mem object.
	//status = clReleaseMemObject(outputBuffer);
	status = clReleaseKernel(iDLKern);				//Release kernel.
	status = clReleaseKernel(proKern);				//Release kernel.
	status = clReleaseKernel(emiKern);				//Release kernel.
	status = clReleaseProgram(waveProgram);				//Release the program object.

	if (output != NULL)
	{
		free(output);
		output = NULL;
	}
	return SDK_SUCCESS;
}

int wave_emit::setStuff()
{
	/*Step 9: Sets Kernel arguments.*/
	//status = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&inputBuffer);
	//status = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&outputBuffer);
	return SDK_SUCCESS;
}

int wave_emit::run()
{
	if (chgTRPair && (rAntXY << 1 != 0))
	{
		initDeadList();
		chgTRPair = true;
	}
	return SDK_SUCCESS;
}

int wave_emit::genEmitter()
{
	//clSetKernelArg(emiKern, 0, sizeof(double), )
	return SDK_SUCCESS;
}

int wave_emit::chngPair()
{
	if (chgTRPair == true)
	{
		initDeadList();
	}
	return SDK_SUCCESS;
}