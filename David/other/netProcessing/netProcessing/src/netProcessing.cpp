#include "helper.h"
#include "netProcessing.h"

using namespace std;

int netProcessing::create_Hassets()
{
	ifstream infile("assets/randomized_matrix.txt");
	DWORD dim, buffer;
	float bufferF;
	infile >> dim;
	vector<DWORD> mat_dimensions;
	while (dim--)
	{
		infile >> buffer;
		mat_dimensions.push_back(buffer);
	}
	vector<float> fullmat;
	vector<vector<float>> FULLMAT;
	FULLMAT.resize(mat_dimensions.size() - 1);
	DWORD size_bytes = 0;
	for (DWORD j = 0; j < mat_dimensions.size() - 1; j++)
	{
		for (DWORD i = j; i < mat_dimensions[i] * mat_dimensions[i + 1]; i++)
		{
			infile >> bufferF;
			fullmat.push_back(bufferF);
			size_bytes += 4;
		}
		FULLMAT.push_back(fullmat);
		fullmat.clear();
	}

	if (create_matrix() < 0)
		return -1;



	/*Step 5: Create program object */
	const char *filename = "shaders/sigmunfreud.cl";
	string sourceStr;
	status = convertToString(filename, sourceStr);
	const char *source = sourceStr.c_str();
	size_t sourceSize[] = { strlen(source) };
	program = clCreateProgramWithSource(*context, 1, &source, sourceSize, NULL);

	/*Step 6: Build program. */
	status = clBuildProgram(program, 1, devices, NULL, NULL, NULL);
	/*Step 8: Create kernel object */
	kernel = clCreateKernel(program, "sigmoid_Firing", NULL);

	/*Step 7: Initial input,output for the host and create memory objects for the kernel*/

	inputBuffer = clCreateBuffer(*context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, size_bytes, (void *)FULLMAT.data(), NULL);
	outputBuffer = clCreateBuffer(*context, CL_MEM_WRITE_ONLY, size_bytes, NULL, NULL);
	return SDK_SUCCESS;
}

int netProcessing::setStuff()
{
	/*Step 9: Sets Kernel arguments.*/
	status = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&inputBuffer);
	status = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&outputBuffer);
	return SDK_SUCCESS;
}

int netProcessing::run()
{
	//size_t global_work_size[1] = { strlength };
	//status = clEnqueueNDRangeKernel(commandQueue, kernel, 1, NULL, global_work_size, NULL, 0, NULL, NULL);
	return SDK_SUCCESS;
}