# Modified version of http://www.pygame.org/wiki/OBJFileLoader
# LMB + move: rotate
# RMB + move: pan
# Scroll wheel: zoom in/out
import sys, pygame, math
from pygame.locals import *
from pygame.constants import *
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *

from OpenGL.arrays import vbo
from OpenGL.raw.GL.ARB.vertex_array_object import glGenVertexArrays, \
                                                  glBindVertexArray
class Viewer(object):
    def __init__(self, view_size=(800, 600)):
        self.on = True
        self.draw_grid = False
        pygame.init()
        glutInit()
        viewport = view_size

        hx = viewport[0]/2
        hy = viewport[1]/2
        srf = pygame.display.set_mode(viewport, OPENGL | DOUBLEBUF)

        glLightfv(GL_LIGHT0, GL_POSITION,  (-40, 200, 100, 0.0))
        glLightfv(GL_LIGHT0, GL_AMBIENT, (0.2, 0.2, 0.2, 1.0))
        glLightfv(GL_LIGHT0, GL_DIFFUSE, (0.5, 0.5, 0.5, 1.0))
        glEnable(GL_LIGHT0)
        glEnable(GL_LIGHTING)
        glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
        glEnable(GL_COLOR_MATERIAL)
        # glClearColor(0.4, 0.4, 0.4, 0.0)
        glClearColor(1.0, 1.0, 1.0, 0.0)

        glEnable(GL_DEPTH_TEST)
        glShadeModel(GL_SMOOTH)

        # glCullFace(GL_BACK)
        # glDisable( GL_CULL_FACE )

        # glPolygonMode ( GL_FRONT_AND_BACK, GL_LINE )

        self.clock = pygame.time.Clock()

        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        width, height = viewport
        gluPerspective(90.0, width/float(height), 1, 100.0)
        glEnable(GL_DEPTH_TEST)
        glMatrixMode(GL_MODELVIEW)

        # Transparancy?
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)

        glTranslated(-15, -15, -15)
        # make_plane(5)

        self.rx, self.ry = (0,0)
        self.tx, self.ty = (0,0)
        self.zpos = 10

        self.gl_lists = []


    def startDraw(self):
        self.gl_list = glGenLists(1)
        glNewList(self.gl_list, GL_COMPILE)

    def endDraw(self):
        glEndList()
        self.gl_lists.append(self.gl_list)
        self.gl_list = None

    def drawMesh(self, mesh):
        # In case changes have been made to the mesh.
        mesh.calculateNormals()

        norm_length = .15
        glColor(1, 1, 1)

        glBegin(GL_TRIANGLES)
        for face in mesh.faces:
            for vert in face.vertices():
                color = vert.data.get('color', (1.0,1.0,1.0))
                glColor(color)
                glNormal3fv(list(vert.normal))
                glVertex3fv(list(vert.p))

        glEnd()

        # glColor(.8, .8, .8)
        # for edge in mesh.edges:
        #     v1, v2 = edge.vertices()
        #     glLineWidth(1)
        #     glBegin(GL_LINES)
        #     glVertex3fv([v*1.001 for v in v1.p])
        #     glVertex3fv([v*1.001 for v in v2.p])
        #     glEnd()

        # glLineWidth(1)

        # face normals
        # glColor(0,0,1)
        # for face in mesh.faces:
        #     glBegin(GL_LINES)

        #     fv = face.vertices()

        #     center = [0.0, 0.0, 0.0]
        #     other = [0.0,0.0,0.0]

        #     for v in fv:
        #         center[0] += v.p[0]
        #         center[1] += v.p[1]
        #         center[2] += v.p[2]

        #     center = [v/len(fv) for v in center]

        #     normal = [c + (v*norm_length) for c, v in zip(center, face.normal)]

        #     glVertex3fv(center)
        #     glVertex3fv(normal)
        #     glEnd()

        # Draw curvature
        # glColor(0, 1, 0)
        # glLineWidth(3)

        # vert normals
        # glColor(1,0,0)
        # for vert, norm in zip(verts, vert_normals):
        #     glBegin(GL_LINES)
        #     norm *= norm_length
        #     glVertex3fv(vert)
        #     glVertex3fv(vert + norm)
        #     glEnd()

    def clear(self):
        self.gl_lists = []

    def handle_input(self, e):
        if e.type == QUIT:
            self.on = False

        elif e.type == KEYDOWN and e.key == K_ESCAPE:
            self.on = False

        elif e.type == MOUSEBUTTONDOWN:
            if e.button == 4: self.zpos = max(1, self.zpos-1)
            elif e.button == 5: self.zpos += 1
            elif e.button == 1: self.rotate = True
            elif e.button == 3: self.move = True

        elif e.type == MOUSEBUTTONUP:
            if e.button == 1: self.rotate = False
            elif e.button == 3: self.move = False

        elif e.type == MOUSEMOTION:
            i, j = e.rel
            if self.rotate:
                self.rx += i
                self.ry += j
            if self.move:
                self.tx += i
                self.ty -= j

        if e.type == KEYDOWN:
            if e.key == K_g:
                self.draw_grid = not self.draw_grid

    def step(self, i):
        pass

    def mainLoop(self):
        self.rotate = False
        self.move = False
        i = 0

        while self.on:
            self.clock.tick(15)
            self.step(i)

            for e in pygame.event.get():
                self.handle_input(e)

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            glLoadIdentity()

            # RENDER OBJECT
            glTranslate(self.tx/20., self.ty/20., - self.zpos)
            glRotate(self.ry, 1, 0, 0)
            glRotate(self.rx, 0, 1, 0)

            for gl_list in self.gl_lists:
                glCallList(gl_list)

            glLineWidth(1)
            if self.draw_grid:
                glCallList(G_OBJ_PLANE)

            pygame.display.flip()
            i += 1
