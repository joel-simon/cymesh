cimport numpy as np

cdef class Vert:
    cdef public unsigned int id
    cdef public double[::1] normal
    cdef public double curvature
    cdef public HalfEdge he
    cdef public double[::1] p
    cdef public dict data

    cpdef list faces(self)
    cpdef list neighbors(self)
    cpdef list edges(self)

cdef class Edge:
    cdef public unsigned int id
    cdef public HalfEdge he

    cpdef double length(self)
    cpdef tuple vertices(self)
    cpdef tuple oppositeVertices(self)
    cpdef bint isBoundary(self)
    cpdef void flip(self)

cdef class Face:
    cdef public unsigned int id
    cdef public double[:] normal
    cdef public HalfEdge he

    # Used for adaptive mesh refinement algorithm.
    cdef public unsigned int generation
    cdef public Face mate

    cpdef list vertices(self)
    cpdef list edges(self)
    cpdef double area(self)
    cpdef double[:] midpoint(self)

cdef class HalfEdge:
    cdef public unsigned int id
    cdef public HalfEdge twin
    cdef public HalfEdge next
    cdef public Vert vert
    cdef public Edge edge
    cdef public Face face
