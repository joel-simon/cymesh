# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True

from vector3D cimport cross, dot, vadd, vsub, vdivf, vdist, inormalized, vmultf

cdef class Vert:
    def __init__(self, id, x, y, z, he):
        self.id = id
        self.p = [x, y, z]
        self.he = he
        self.normal = [0, 0, 0]
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
            if h == start:
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

            if h == start:
                break

        return result

cdef class Edge:
    def __init__(self, id, he):
        self.id = id
        self.he = he

    cpdef double length(self):
        cdef Vert v1 = self.he.vert
        cdef Vert v2 = self.he.next.vert

        return vdist(v1.p, v2.p)

    cpdef tuple vertices(self):
        return (self.he.vert, self.he.twin.vert)

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
    cpdef list vertices(self):
        cdef list result = []
        cdef HalfEdge h = self.he
        cdef HalfEdge start = h

        while True:
            result.append(h.vert)
            h = h.next
            if h == start: break

        return result

    cpdef list edges(self):
        cdef list result = []
        cdef HalfEdge h = self.he
        cdef HalfEdge start = h

        while True:
            result.append(h.edge)
            h = h
            if h == start: break

        return result

cdef class HalfEdge:
    def __init__(self, id, twin, next, vert, edge, face):
        self.id = id
        self.twin = twin
        self.next = next
        self.vert = vert
        self.edge = edge
        self.face = face

