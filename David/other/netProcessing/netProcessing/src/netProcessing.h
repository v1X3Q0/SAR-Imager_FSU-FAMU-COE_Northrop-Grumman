#include "helper.h"

class netProcessing
{
public:
	int create_Hassets();
	int setStuff();
	int run();
private:
	cl_kernel kernel;
	cl_context* context;
	cl_device_id* devices;
	cl_program program;

	cl_mem inputBuffer;
	cl_mem outputBuffer;
	cl_int status;
};