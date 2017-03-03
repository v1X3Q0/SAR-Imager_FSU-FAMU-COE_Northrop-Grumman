__kernel void sigmoid_Firing(__global int* size, __global float* i_weights,
	__global float* bias, __global int* dimx, __global int* dimy)
{
	//dimy number of global kernels launched

	int num = get_global_id(0), result = 0;
	for(int i = 0; i < dimy[0]; i++)
		result += i_weights[i + dimx[0]] * i_weights[num * dimx[0] + i];
	result += bias[num];
	result *= -1;
	result = 1 + (1.0 / native_exp(result));
	i_weights[num + (1 + dimx[0]) * dimy[0]] = result;
}