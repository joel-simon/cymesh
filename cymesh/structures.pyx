# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True
from libc.math cimport sqrt
from vector3D cimport vdist
cimport numpy as np
import numpy as np

cdef class Vert:
    def __init__(self, id, x, y, z, he):
        self.id = id
        self.p = np.array([x, y, z])
        self.he = he
        self.normal = np.zeros(3)
        self.curvature = 0
        self.data = dict()

    cpdef list faces(self):
        """ Return a list of faces which contain this vert.
        """
        cdef list result = []
        cdef HalfEdge h, start, h_twin

        h = self.he
        start = h

        while True:
            result.append(h.face)
            h_twin = h.twin
            h = h_twin.next
            if h is start:
                break

        return result

    cpdef list neighbors(self):
        """ Return a list of vertexes directly connected to this one.
        """
        cdef list result = []
        cdef HalfEdge h, start, h_twin

        h = self.he
        start = h

        while True:
            h_twin = h.twin
            result.append(h_twin.vert)
            h = h_twin.next

            if h is start:
                break

        return result

cdef class Edge:
    def __init__(self, id, he):
        self.id = id
        self.he = he

    cpdef double length(self):
        cdef double[:] p1 = self.he.vert.p
        cdef double[:] p2 = self.he.twin.vert.p
        return vdist(p1, p2)

    cpdef tuple vertices(self):
        return (self.he.vert, self.he.twin.vert)

    cpdef tuple oppositeVertices(self):
        cdef HalfEdge he1, he2, he11, he12, he22

        if self.isBoundary():
            return None

        # Defining variables
        he1 = self.he
        he2 = he1.twin

        he11 = he1.next
        he12 = he11.next
        he21 = he2.next
        he22 = he21.next

        return (he12.vert, he22.vert)

    cpdef bint isBoundary(self):
        return self.he.face is None or self.he.twin.face is None

    cpdef void flip(self):
        # Edge operations
        cdef HalfEdge he1, he2, he11, he12, he22
        cdef Vert v1, v2, v3, v4
        cdef Face f1, f2

        # http://mrl.nyu.edu/~dzorin/cg05/lecture11.pdf
        if self.isBoundary():
            return

        # Defining variables
        he1 = self.he
        he2 = he1.twin
        f1, f2 = he1.face, he2.face
        he11 = he1.next
        he12 = he11.next
        he21 = he2.next
        he22 = he21.next
        v1, v2 = he1.vert, he2.vert
        v3, v4 = he12.vert, he22.vert

        if v3 in v4.neighbors():
            return

        # TODO: find out why this happens.
        if v3 is v4:# assert(v3 != v4)
            return

        # Logic
        he1.next = he22
        he1.vert = v3
        he2.next = he12
        he2.vert = v4
        he11.next = he1
        he12.next = he21
        he12.face = f2
        he21.next = he2
        he22.next = he11
        he22.face = f1

        if f2.he is he22:
            f2.he = he12
        if f1.he is he12:
            f1.he = he22
        if v1.he is he1:
            v1.he = he21
        if v2.he is he2:
            v2.he = he11

cdef class Face:
    def __init__(self, id, he):
        self.id = id
        self.he = he
        self.normal = np.zeros(3)
        self.mate = None
        self.generation = 0

    cpdef list vertices(self):
        return [self.he.vert, self.he.next.vert, self.he.next.next.vert]
        # cdef list result = []
        # cdef HalfEdge h = self.he
        # cdef HalfEdge start = h

        # while True:
        #     result.append(h.vert)
        #     h = h.next
        #     if h == start: break

        # return result

    cpdef list edges(self):
        cdef list result = []
        cdef HalfEdge h = self.he
        cdef HalfEdge start = h

        while True:
            result.append(h.edge)
            h = h
            if h == start: break

        return result

    cpdef double area(self):
        cdef double[:] p1 = self.he.vert.p
        cdef double[:] p2 = self.he.next.vert.p
        cdef double[:] p3 = self.he.next.next.vert.p
        cdef double a, b, c
        # http://www.iquilezles.org/blog/?p=1579
        a = (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2 + (p1[2] - p2[2])**2 # 1-2
        b = (p3[0] - p2[0])**2 + (p3[1] - p2[1])**2 + (p3[2] - p2[2])**2 # 2-3
        c = (p1[0] - p3[0])**2 + (p1[1] - p3[1])**2 + (p1[2] - p3[2])**2 # 1-3
        return sqrt(2*a*b + 2*b*c + 2*c*a - a*a - b*b - c*c) / 16.0

    cpdef double[:] midpoint(self):
        cdef double[:] p1 = self.he.vert.p
        cdef double[:] p2 = self.he.next.vert.p
        cdef double[:] p3 = self.he.next.next.vert.p
        cdef double[:] m = np.zeros(3)
        m[0] = (p1[0] + p2[0] + p3[0]) / 3.0
        m[1] = (p1[1] + p2[1] + p3[1]) / 3.0
        m[2] = (p1[2] + p2[2] + p3[2]) / 3.0
        return m

cdef class HalfEdge:
    def __init__(self, id, twin, next, vert, edge, face):
        self.id = id
        self.twin = twin
        self.next = next
        self.vert = vert
        self.edge = edge
        self.face = face

