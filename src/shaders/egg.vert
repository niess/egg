attribute vec4 vertex;
uniform mat4 projection;
uniform mat4 view;
varying vec4 vcolour;

void main()
{
        gl_Position = projection * view * vec4(vertex.xyz, 1.0);
        vcolour = vec4(0.5, 0.1, 0.1, 0.5);
}
