attribute vec3 vertPos_;
uniform mat4 MVP;
void main()
{
	// Output position of the vertex, in clip space : MVP * position
	gl_Position =  MVP * vec4(vertPos_, 1);
}