#pragma once
#include "helper.h"
#include "sar_OBJ.h"

extern HWND gHwnd;

class simu_overview
{
private:
	sar_toRender SAR_DEVICE;

	float theta = 0.0f;
	cl_float animate = 0.0f;            /**< Animation rate */
	glm::mat4 viewMat;
	glm::mat4 projMat;

	cl_device_id interopDeviceId;
	cl_context context;
	cl_int status = CL_SUCCESS;
	cl_device_id *devices;
	cl_platform_id platform;
	cl_command_queue commandQueue;

	clock_t t1, t2;
	int frameCount = 0;
	int frameRefCount = 90;
	double totalElapsedTime = 0.0, propGLOBAL = 0;
	double secondsPFrame;


	appsdk::CLCommandArgs fncArgs;

#ifdef _WIN32
	HWND*		gHwnd;
	HDC           gHdc;
	HGLRC         gGlCtx;
	BOOL quit = FALSE;
	MSG msg;
#else
	GLXContext gGlCtx;
#define GLX_CONTEXT_MAJOR_VERSION_ARB           0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB           0x2092
	typedef GLXContext(*GLXCREATECONTEXTATTRIBSARBPROC)(Display*, GLXFBConfig,
		GLXContext, Bool, const int*);
	Window      win;
	Display     *displayName;
	XEvent          xev;
#endif


public:
	simu_overview();
	int init(int argc, char** argv, HWND*);
	int enableGLAndGetGLContext(cl_platform_id);
	int cleanup();
	int setStuff();
	int run();
};