import glfw
from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
import numpy as np
import pyrr




class Window:
    def __init__(self, width: int, height:int, name:str,obj3d):
        self.obj3d = obj3d
        self.vertex_src = """
        # version 330
        layout(location = 0) in vec3 a_position;
        layout(location = 1) in vec3 a_color;
        uniform mat4 rotation;
        out vec3 v_color;
        void main()
        {
            gl_Position = rotation * vec4(a_position, 1.0);
            v_color = a_color;
        }
        """

        self.fragment_src = """
        # version 330
        in vec3 v_color;
        out vec4 out_color;
        void main()
        {
            out_color = vec4(v_color, 1.0);
        }
        """
        if not glfw.init():
            raise Exception("glfw can not be opened")

        self.window = glfw.create_window(width, height, name, None, None)
        if not self.window:
            glfw.terminate()
            raise Exception("glfw window failed to create")
        glfw.set_window_pos(self.window, 400, 200)
        glfw.set_window_size_callback(self.window, self.window_resize)
        glfw.make_context_current(self.window)

        self.shader = compileProgram(compileShader(self.vertex_src, GL_VERTEX_SHADER), compileShader(self.fragment_src, GL_FRAGMENT_SHADER))

        self.VBO = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.VBO)
        glBufferData(GL_ARRAY_BUFFER, self.obj3d.vertices.nbytes,
                     self.obj3d.vertices, GL_STATIC_DRAW)
        # Element Buffer Object
        self.EBO = glGenBuffers(1)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.EBO)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     self.obj3d.indices.nbytes, self.obj3d.indices, GL_STATIC_DRAW)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 24, ctypes.c_void_p(0))
        glEnableVertexAttribArray(1)
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 24, ctypes.c_void_p(12))
        glUseProgram(self.shader)
        glClearColor(0, 0.1, 0.1, 1)
        glEnable(GL_DEPTH_TEST)
        self.rotation_loc = glGetUniformLocation(self.shader, "rotation")
       
    def mainLoop(self):
        glfw.poll_events()
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        rot_x = pyrr.Matrix44.from_x_rotation(0.5 * glfw.get_time())
        rot_y = pyrr.Matrix44.from_y_rotation(0.8 * glfw.get_time())

        # glUniformMatrix4fv(rotation_loc, 1, GL_FALSE, rot_x * rot_y)
        # glUniformMatrix4fv(rotation_loc, 1, GL_FALSE, rot_x @ rot_y)
        glUniformMatrix4fv(self.rotation_loc, 1, GL_FALSE,
                        pyrr.matrix44.multiply(rot_x, rot_y))
        
        glDrawElements(GL_TRIANGLES, len(self.obj3d.indices), GL_UNSIGNED_INT, None)
        glfw.swap_buffers(self.window)


    def window_resize(self, window, width, height):
        glViewport(0, 0, width, height)


class Cube:
    def __init__(self,x,y,z,size):

        vertices = [x-(size/2), y-(size/2), z+(size/2), 1.0, 0.0, 0.0,
                    x+(size/2), y-(size/2), z+(size/2), 0.0, 1.0, 0.0,
                    x+(size/2), y+(size/2), z+(size/2), 0.0, 0.0, 1.0,
                    x-(size/2), y+(size/2), z+(size/2), 1.0, 1.0, 1.0,

                    x-(size/2), y-(size/2), z-(size/2), 1.0, 0.0, 0.0,
                    x+(size/2), y-(size/2), z-(size/2), 0.0, 1.0, 0.0,
                    x+(size/2), y+(size/2), z-(size/2), 0.0, 0.0, 1.0,
                    x-(size/2), y+(size/2), z-(size/2), 1.0, 1.0, 1.0]

        indices = [0, 1, 2, 2, 3, 0,
                4, 5, 6, 6, 7, 4,
                4, 5, 1, 1, 0, 4,
                6, 7, 3, 3, 2, 6,
                5, 6, 2, 2, 1, 5,
                7, 4, 0, 0, 3, 7]
        self.vertices = np.array(vertices, dtype=np.float32)
        self.indices = np.array(indices, dtype=np.uint32)

if __name__ == "__main__":
    cube1 = Cube(0.0,0.0,0.0,0.1)
    cube2 = Cube(0.5, 0.5, 0.0, 0.2)
    cubes = [cube1,cube2]
    win = Window(1280, 720, "turtle", cube2)
    while not glfw.window_should_close(win.window):
        win.mainLoop()

glfw.terminate()
