cdef class Vert:
    cdef readonly unsigned int id
    cdef readonly double normal[3]
    cdef readonly double curvature
    cdef readonly HalfEdge he
    cdef public double p[3]
    cdef public dict data

    cpdef list faces(self)
    cpdef list neighbors(self)

cdef class Edge:
    cdef readonly unsigned int id
    cdef readonly HalfEdge he
    # cdef readonly double curvature

    cpdef double length(self)
    cpdef tuple vertices(self)
    cpdef bint isBoundary(self)
    cpdef void flip(self)

cdef class Face:
    cdef readonly unsigned int id
    cdef readonly double normal[3]
    cdef readonly HalfEdge he

    cpdef list vertices(self)
    cpdef list edges(self)

cdef class HalfEdge:
    cdef readonly unsigned int id
    cdef readonly HalfEdge twin
    cdef readonly HalfEdge next
    cdef readonly Vert vert
    cdef readonly Edge edge
    cdef readonly Face face
