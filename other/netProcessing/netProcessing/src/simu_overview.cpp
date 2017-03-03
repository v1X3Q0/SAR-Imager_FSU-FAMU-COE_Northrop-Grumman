#include "helper.h"
#include "simu_overview.h"

#define WINDOW_WIDTH 512
#define WINDOW_HEIGHT 512

#define screenWidth  512
#define screenHeight 512

using namespace std;
using namespace appsdk;

int mouseOldX;                      /**< mouse controls */
int mouseOldY;
int mouseButtons = 0;
float rotateX = 0.0f;
float rotateY = 0.0f;
float translateZ = -5.0f;
float translateY = -3.0f;
float y_shift_view = 0.0;

#ifdef _WIN32
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{

	case WM_CREATE:
		return 0;

	case WM_CLOSE:
		PostQuitMessage(0);
		return 0;

	case WM_DESTROY:
		return 0;

	case WM_LBUTTONUP:
		mouseButtons = 0;
		return 0;

	case WM_LBUTTONDOWN:
		mouseOldX = LOWORD(lParam);
		mouseOldY = HIWORD(lParam);
		mouseButtons = 1;
		return 0;

	case WM_MOUSEMOVE:
	{
		int x = LOWORD(lParam);
		int y = HIWORD(lParam);
		if (mouseButtons)
		{
			int dx = x - mouseOldX;
			int dy = y - mouseOldY;
			rotateX += (dy * 0.02f);
			rotateY += (dx * 0.02f);
		}
		mouseOldX = x;
		mouseOldY = y;
	}
	return 0;

	case WM_KEYDOWN:
		switch (wParam)
		{

		case VK_ESCAPE:
			PostQuitMessage(0);
			return 0;

		}
		return 0;
	case WM_MOUSEWHEEL:
		if (GET_WHEEL_DELTA_WPARAM(wParam) > 0)
			y_shift_view += .1;
		else
			y_shift_view -= .1;

	default:
		return DefWindowProc(hWnd, message, wParam, lParam);

	}
}
#endif

simu_overview::simu_overview()
{
	theta = 0.0f;
	animate = 0.0f;            /**< Animation rate */

	t1;
	t2;
	frameCount = 0;
	frameRefCount = 90;
	totalElapsedTime = 0.0;
	propGLOBAL = 0;

	viewMat = glm::mat4(1.0);
	projMat = glm::perspective(20.0f, (GLfloat)WINDOW_WIDTH / (GLfloat)WINDOW_HEIGHT, 0.1f, 10.0f);
}
int simu_overview::enableGLAndGetGLContext(cl_platform_id plat_o)
{
	platform = plat_o;
	BOOL ret = FALSE;
	DISPLAY_DEVICE dispDevice;
	DWORD deviceNum;
	int  pfmt;
	PIXELFORMATDESCRIPTOR  pfd;
	pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
		;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cColorBits = 24;
	pfd.cRedBits = 8;
	pfd.cRedShift = 0;
	pfd.cGreenBits = 8;
	pfd.cGreenShift = 0;
	pfd.cBlueBits = 8;
	pfd.cBlueShift = 0;
	pfd.cAlphaBits = 8;
	pfd.cAlphaShift = 0;
	pfd.cAccumBits = 0;
	pfd.cAccumRedBits = 0;
	pfd.cAccumGreenBits = 0;
	pfd.cAccumBlueBits = 0;
	pfd.cAccumAlphaBits = 0;
	pfd.cDepthBits = 24;
	pfd.cStencilBits = 8;
	pfd.cAuxBuffers = 0;
	pfd.iLayerType = PFD_MAIN_PLANE;
	pfd.bReserved = 0;
	pfd.dwLayerMask = 0;
	pfd.dwVisibleMask = 0;
	pfd.dwDamageMask = 0;

	ZeroMemory(&pfd, sizeof(PIXELFORMATDESCRIPTOR));

	dispDevice.cb = sizeof(DISPLAY_DEVICE);

	DWORD displayDevices = 0;
	DWORD connectedDisplays = 0;

	int xCoordinate = 0;
	int yCoordinate = 0;
	int xCoordinate1 = 0;

	for (deviceNum = 0; EnumDisplayDevices(NULL, deviceNum, &dispDevice, 0);
		deviceNum++)
	{
		if (dispDevice.StateFlags & DISPLAY_DEVICE_MIRRORING_DRIVER)
		{
			continue;
		}

		if (!(dispDevice.StateFlags & DISPLAY_DEVICE_ACTIVE))
		{
			continue;
		}

		DEVMODE deviceMode;

		// initialize the DEVMODE structure
		ZeroMemory(&deviceMode, sizeof(deviceMode));
		deviceMode.dmSize = sizeof(deviceMode);
		deviceMode.dmDriverExtra = 0;

		EnumDisplaySettings(dispDevice.DeviceName, ENUM_CURRENT_SETTINGS, &deviceMode);

		xCoordinate = deviceMode.dmPosition.x;
		yCoordinate = deviceMode.dmPosition.y;

		WNDCLASS windowclass;

		windowclass.style = CS_OWNDC;
		windowclass.lpfnWndProc = WndProc;
		windowclass.cbClsExtra = 0;
		windowclass.cbWndExtra = 0;
		windowclass.hInstance = NULL;
		windowclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
		windowclass.hCursor = LoadCursor(NULL, IDC_ARROW);
		windowclass.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
		windowclass.lpszMenuName = NULL;
		windowclass.lpszClassName = reinterpret_cast<LPCSTR>("SB23");
		RegisterClass(&windowclass);

		(*gHwnd) = CreateWindow(reinterpret_cast<LPCSTR>("SB23"),
			reinterpret_cast<LPCSTR>("OpenGL Texture Renderer"),
			WS_CAPTION | WS_POPUPWINDOW,
			fncArgs.isDeviceIdEnabled() ? xCoordinate1 : xCoordinate,
			yCoordinate,
			screenWidth,
			screenHeight,
			NULL,
			NULL,
			windowclass.hInstance,
			NULL);
		gHdc = GetDC(*gHwnd);

		pfmt = ChoosePixelFormat(gHdc,
			&pfd);
		if (pfmt == 0)
		{
			std::cout << "Failed choosing the requested PixelFormat.\n";
			return SDK_FAILURE;
		}

		ret = SetPixelFormat(gHdc, pfmt, &pfd);
		if (ret == FALSE)
		{
			std::cout << "Failed to set the requested PixelFormat.\n";
			return SDK_FAILURE;
		}

		gGlCtx = wglCreateContext(gHdc);
		if (gGlCtx == NULL)
		{
			std::cout << "Failed to create a GL context" << std::endl;
			return SDK_FAILURE;
		}

		ret = wglMakeCurrent(gHdc, gGlCtx);
		if (ret == FALSE)
		{
			std::cout << "Failed to bind GL rendering context";
			return SDK_FAILURE;
		}
		displayDevices++;

		cl_context_properties properties[] =
		{
			CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
			CL_GL_CONTEXT_KHR,   (cl_context_properties)gGlCtx,
			CL_WGL_HDC_KHR,      (cl_context_properties)gHdc,
			0
		};

		if (!clGetGLContextInfoKHR)
		{
			clGetGLContextInfoKHR = (clGetGLContextInfoKHR_fn)
				clGetExtensionFunctionAddressForPlatform(platform, "clGetGLContextInfoKHR");
			if (!clGetGLContextInfoKHR)
			{
				std::cout << "Failed to query proc address for clGetGLContextInfoKHR";
				return SDK_FAILURE;
			}
		}

		size_t deviceSize = 0;
		status = clGetGLContextInfoKHR(properties,
			CL_CURRENT_DEVICE_FOR_GL_CONTEXT_KHR,
			0,
			NULL,
			&deviceSize);
		CHECK_OPENCL_ERROR(status, "clGetGLContextInfoKHR failed!!");

		if (deviceSize == 0)
		{
			// no interopable CL device found, cleanup
			wglMakeCurrent(NULL, NULL);
			wglDeleteContext(gGlCtx);
			DeleteDC(gHdc);
			gHdc = NULL;
			gGlCtx = NULL;
			DestroyWindow(*gHwnd);
			// try the next display
			continue;
		}
		else
		{
			if (fncArgs.deviceId == 0)
			{
				ShowWindow(*gHwnd, SW_SHOW);
				//Found a winner
				break;
			}
			else if (fncArgs.deviceId != connectedDisplays)
			{
				connectedDisplays++;
				wglMakeCurrent(NULL, NULL);
				wglDeleteContext(gGlCtx);
				DeleteDC(gHdc);
				gHdc = NULL;
				gGlCtx = NULL;
				DestroyWindow(*gHwnd);
				if (xCoordinate >= 0)
				{
					xCoordinate1 += deviceMode.dmPelsWidth;
					// try the next display
				}
				else
				{
					xCoordinate1 -= deviceMode.dmPelsWidth;
				}

				continue;
			}
			else
			{
				ShowWindow(*gHwnd, SW_SHOW);
				//Found a winner
				break;
			}
		}

	}

	if (!gGlCtx || !gHdc)
	{
		OPENCL_EXPECTED_ERROR("OpenGL interoperability is not feasible.");
	}

	cl_context_properties properties[] =
	{
		CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
		CL_GL_CONTEXT_KHR,   (cl_context_properties)gGlCtx,
		CL_WGL_HDC_KHR,      (cl_context_properties)gHdc,
		0
	};


	if (fncArgs.deviceType.compare("gpu") == 0)
	{
		status = clGetGLContextInfoKHR(properties,
			CL_CURRENT_DEVICE_FOR_GL_CONTEXT_KHR,
			sizeof(cl_device_id),
			&interopDeviceId,
			NULL);
		CHECK_OPENCL_ERROR(status, "clGetGLContextInfoKHR failed!!");

		// Create OpenCL context from device's id
		context = clCreateContext(properties,
			1,
			&interopDeviceId,
			0,
			0,
			&status);
		CHECK_OPENCL_ERROR(status, "clCreateContext failed!!");
		std::cout << "Interop Device Id " << interopDeviceId << std::endl;
	}
	else
	{
		context = clCreateContextFromType(
			properties,
			CL_DEVICE_TYPE_CPU,
			NULL,
			NULL,
			&status);
		CHECK_OPENCL_ERROR(status, "clCreateContextFromType failed!!");
	}

	// OpenGL animation code goes here

	// GL init
	glewInit();
	if (!glewIsSupported("GL_VERSION_2_0 " "GL_ARB_pixel_buffer_object"))
	{
		std::cerr << "Support for necessary OpenGL extensions missing."
			<< std::endl;
		return SDK_FAILURE;
	}

	//glEnable(GL_TEXTURE_2D);
	glClearColor(1.0, 1.0, 1.0, 1.0);
	//glDisable(GL_DEPTH_TEST);

	glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	glEnable(GL_DEPTH_TEST);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(
		60.0,
		(GLfloat)WINDOW_WIDTH / (GLfloat)WINDOW_HEIGHT,
		0.1,
		10.0);

	return SDK_SUCCESS;
}

int simu_overview::init(int argc, char** argv, HWND* Hwnd_)
{
	gHwnd = Hwnd_;
	if (fncArgs.initialize())
		return -1;
	if (fncArgs.parseCommandLine(argc, argv))
		return -1;
	cl_device_type dType;
	if (!fncArgs.deviceType.compare("cpu"))
		dType = CL_DEVICE_TYPE_CPU;
	else
	{
		dType = CL_DEVICE_TYPE_GPU;
		if (fncArgs.isThereGPU() == false)
		{
			std::cout << "GPU not found. Falling back to CPU device" << std::endl;
			dType = CL_DEVICE_TYPE_CPU;
		}
	}
	platform = NULL;
	int retValue = getPlatform(platform, fncArgs.platformId,
		fncArgs.isPlatformEnabled());
	CHECK_ERROR(retValue, SDK_SUCCESS, "getPlatform() failed");

	retValue = displayDevices(platform, dType);
	CHECK_ERROR(retValue, SDK_SUCCESS, "displayDevices() failed");

#ifdef _WIN32
	retValue = enableGLAndGetGLContext(platform);
	if (retValue != SDK_SUCCESS)
		return retValue;
#else
	retValue = initializeGLAndGetCLContext(platform,
		context,
		interopDeviceId);
	if (retValue != SDK_SUCCESS)
		return retValue;
#endif
	//CL SETUP
	/*Step1: Getting platforms and choose an available one.*/


	/*Step 3: Create context.*/

	/*Step 4: Creating command queue associate with the context.*/
	if (dType == CL_DEVICE_TYPE_CPU)
	{
		// getting device on which to run the sample
		status = getDevices(context, &devices, fncArgs.deviceId,
			fncArgs.isDeviceIdEnabled());
		CHECK_ERROR(status, SDK_SUCCESS, "sampleCommon::getDevices() failed");
		interopDeviceId = devices[fncArgs.deviceId];
	}
	commandQueue = clCreateCommandQueue(
		context,
		interopDeviceId,
		0,
		&status);
	CHECK_OPENCL_ERROR(status, "clCreateCommandQueue failed.");

	SAR_DEVICE.create_Hassets();

	return SDK_SUCCESS;
}

int simu_overview::cleanup()
{

	/*Step 12: Clean the resources.*/
	status = clReleaseCommandQueue(commandQueue);	//Release  Command queue.
	status = clReleaseContext(context);				//Release context.

	if (devices != NULL)
	{
		free(devices);
		devices = NULL;
	}
	return SDK_SUCCESS;
}

int simu_overview::run()
{
	if (!fncArgs.quiet && !fncArgs.verify)
	{
#ifdef _WIN32
		// program main loop
		while (!quit)
		{
			// check for messages
			if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
			{
				// handle or dispatch messages
				if (msg.message == WM_QUIT)
				{
					quit = TRUE;
				}
				else
				{
					TranslateMessage(&msg);
					DispatchMessage(&msg);
				}
			}
			else
			{
				// OpenGL animation code goes here

				t1 = clock() * CLOCKS_PER_SEC;
				frameCount++;

				// run OpenCL kernel to generate vertex positions
				//executeKernel();
				glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

				// set view matrix
				//glMatrixMode(GL_MODELVIEW);
				//glLoadIdentity();
				viewMat = glm::mat4(1.0);
				viewMat = glm::translate(viewMat, glm::vec3(0.0, translateY, y_shift_view + translateZ));
				viewMat = glm::rotate(viewMat, rotateX, glm::vec3(1.0, 0.0, 0.0));
				viewMat = glm::rotate(viewMat, rotateY, glm::vec3(0.0, 1.0, 0.0));

				SAR_DEVICE.run(&viewMat, &projMat, gHdc);

				glFinish();

				SwapBuffers(gHdc);

				t2 = clock() * CLOCKS_PER_SEC;
				totalElapsedTime += (double)(t2 - t1);
				if (frameCount && frameCount > frameRefCount)
				{

					// set  Window Title
					char title[256];
					double fMs = (double)((totalElapsedTime / (double)CLOCKS_PER_SEC) /
						(double)frameCount);
					int framesPerSec = (int)(1.0 / (fMs / CLOCKS_PER_SEC));
#if defined (_WIN32) && !defined(__MINGW32__)
					sprintf_s(title, 256, "OpenCL SAR SIM | %d fps ", framesPerSec);
#endif
					SetWindowText(*gHwnd, title);
					frameCount = 0;
					totalElapsedTime = 0.0;
				}

				animate += 0.01f;
			}

		}
#endif
	}
	else
	{
		cout << "\ncould not run the sample, stuff GL stuff isn not ready\n";
		cleanup();
	}
	return SDK_SUCCESS;
}