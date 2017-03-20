#ifndef HELPER_H
#define HELPER_H
#include <../../glew/include/GL/glew.h>
#include <CL/cl_gl.h>

#include <windows.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <time.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "external/objloader.hpp"
#include "external/shader.hpp"
#include "external/controls.hpp"

#include <SDKUtil\CLUtil.hpp>
#define	SDK_SUCCESS	0
#define	SDK_FAILURE	1

#define clGetGLContextInfoKHR clGetGLContextInfoKHR_proc
static clGetGLContextInfoKHR_fn clGetGLContextInfoKHR;

using namespace std;

extern int mouseOldX;                      /**< mouse controls */
extern int mouseOldY;
extern int mouseButtons;
extern float rotateX;
extern float rotateY;
extern float translateZ;

int convertToString(const char*, std::string&);
int create_matrix();
// Helper function to align values
int align(int value, int alignment); 

#endif