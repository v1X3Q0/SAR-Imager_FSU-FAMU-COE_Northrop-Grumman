#include "helper.h"

#include "simu_overview.h"
#include "sar_OBJ.h"

#define STRINGIFY(A) #A
using namespace std;

static HWND   gHwnd;

int main(int argc, char* argv[])
{
	//SET UP GL ALLOCATIONS BEFORE CL
	//vertex based allocation
	// Read our .obj file
	
/*	cl_mem inputBuffer = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, (strlength + 1) * sizeof(char), (void *)input, NULL);
	cl_mem outputBuffer = clCreateBuffer(context, CL_MEM_WRITE_ONLY, (strlength + 1) * sizeof(char), NULL, NULL);*/

	/*Step 11: Read the cout put back to host memory.*/
	/*status = clEnqueueReadBuffer(commandQueue, outputBuffer, CL_TRUE, 0, strlength * sizeof(char), output, 0, NULL, NULL);

	output[strlength] = '\0';	//Add the terminal character to the end of output.
	cout << "\noutput string:" << endl;
	cout << output << endl;*/
	simu_overview simulation;
	simulation.init(argc, argv, &gHwnd);
	simulation.run();
	simulation.cleanup();
	//THE REST IS NECESSARY CLEANUP


	return SDK_SUCCESS;
}