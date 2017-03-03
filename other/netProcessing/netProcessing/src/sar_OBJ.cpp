#include "sar_OBJ.h"

using namespace std;
using namespace appsdk;

sar_toRender::sar_toRender()
{
	modelMat = glm::mat4(1.0);
}

int sar_toRender::create_Hassets()
{
	bool res;
	cl_float* pos;

	std::vector<glm::vec3> vertices;
	std::vector<glm::vec2> uvs;
	std::vector<glm::vec3> normals; // Won't be used at the moment.

	res = loadOBJ("assets/SAR_Objects/Receivers.obj", vertices, /*uvs,*/ normals);
	glGenBuffers(1, &recBuf);
	glBindBuffer(GL_ARRAY_BUFFER, recBuf);
	glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(glm::vec3), &vertices[0], GL_STATIC_DRAW);
	recSize = vertices.size();
	vertices.clear();
	//uvs.clear();
	normals.clear();

	res = loadOBJ("assets/SAR_OBJECTS/Transmitters.obj", vertices, /*uvs,*/ normals);
	glGenBuffers(1, &traBuf);
	glBindBuffer(GL_ARRAY_BUFFER, traBuf);
	glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(glm::vec3), &vertices[0], GL_STATIC_DRAW);
	traSize = vertices.size();
	vertices.clear();
	//uvs.clear();
	normals.clear();

	res = loadOBJ("assets/SAR_OBJECTS/Frame.obj", vertices, /*uvs,*/ normals);
	glGenBuffers(1, &fraBuf);
	glBindBuffer(GL_ARRAY_BUFFER, fraBuf);
	glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(glm::vec3), &vertices[0], GL_STATIC_DRAW);
	fraSize = vertices.size();
	vertices.clear();
	//uvs.clear();
	normals.clear();

	antProgID = LoadShaders("shaders/stdVertOut.vert", "shaders/stdFragOut.frag");
	antColorID = glGetUniformLocation(antProgID, "_color");
	// Get a handle for our buffers
	vertPosID = glGetAttribLocation(antProgID, "vertPos_");
	MVPID = glGetUniformLocation(antProgID, "MVP");
	return SDK_SUCCESS;
}

int sar_toRender::run(glm::mat4* view, glm::mat4* proj, HDC gHdc)
{
	/*Step 10: Running the kernel.*/
	glUseProgram(antProgID);

	// Compute the MVP matrix from keyboard and mouse input

	// set model matrix
	/*glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glMultMatrixf((GLfloat*)&modelMat);*/
	glm::mat4 mvp_ = (*proj) * (*view) * modelMat;

	glUniformMatrix4fv(MVPID, 1, GL_FALSE, &mvp_[0][0]);

	// 1rst attribute buffer : vertices
	glEnableVertexAttribArray(vertPosID);
	glBindBuffer(GL_ARRAY_BUFFER, recBuf);
	glVertexAttribPointer(
		vertPosID,  // The attribute we want to configure
		3,                            // size
		GL_FLOAT,                     // type
		GL_FALSE,                     // normalized?
		0,                            // stride
		(void*)0                      // array buffer offset
	);
	// render from the vbo
	//glVertexPointer(4, GL_FLOAT, 0, 0);
	//glEnableClientState(GL_VERTEX_ARRAY);
	//glColor3f(1.0, 0.0, 0.0);
	glUniform3f(antColorID, 0.0, 1.0, 0.0);
	glDrawArrays(GL_TRIANGLES, 0, recSize);
	//glDisableClientState(GL_VERTEX_ARRAY);
	glDisableVertexAttribArray(vertPosID);


	glEnableVertexAttribArray(vertPosID);
	glBindBuffer(GL_ARRAY_BUFFER, traBuf);
	glVertexAttribPointer(
		vertPosID,  // The attribute we want to configure
		3,                            // size
		GL_FLOAT,                     // type
		GL_FALSE,                     // normalized?
		0,                            // stride
		(void*)0                      // array buffer offset
	);
	glUniform3f(antColorID, 1.0, 0.0, 0.0);
	glDrawArrays(GL_TRIANGLES, 0, traSize);
	glDisableVertexAttribArray(vertPosID);


	glEnableVertexAttribArray(vertPosID);
	glBindBuffer(GL_ARRAY_BUFFER, fraBuf);
	glVertexAttribPointer(
		vertPosID,  // The attribute we want to configure
		3,                            // size
		GL_FLOAT,                     // type
		GL_FALSE,                     // normalized?
		0,                            // stride
		(void*)0                      // array buffer offset
	);
	glUniform3f(antColorID, 0.0, 0.0, 1.0);
	glDrawArrays(GL_TRIANGLES, 0, fraSize);
	glDisableVertexAttribArray(vertPosID);

	//glPopMatrix();
	return SDK_SUCCESS;
}

int sar_toRender::cleanup()
{
	return SDK_SUCCESS;
}