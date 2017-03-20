#ifndef SAR_OBJ_H
#define SAR_OBJ_H
#include "helper.h"

class sar_toRender
{
private:
	GLuint antProgID, vertPosID, antColorID, MVPID;
	GLuint recBuf, traBuf, fraBuf;
	GLsizei recSize, traSize, fraSize;

	glm::mat4 modelMat;
public:
	sar_toRender();
	int create_Hassets();
	int setStuff();
	int run(glm::mat4*, glm::mat4*, HDC);
	int cleanup();
};
#endif