from structures cimport Vert, Edge, Face, HalfEdge

cdef inline double signed_triangle_volume(double[:] p1, double[:] p2, double[:] p3):
    cdef double v321 = p3[0] * p2[1] * p1[2]
    cdef double v231 = p2[0] * p3[1] * p1[2]
    cdef double v312 = p3[0] * p1[1] * p2[2]
    cdef double v132 = p1[0] * p3[1] * p2[2]
    cdef double v213 = p2[0] * p1[1] * p3[2]
    cdef double v123 = p1[0] * p2[1] * p3[2]
    return (1./6.0) * (-v321 + v231 + v312 - v132 - v213 + v123)

cdef class Mesh:
    cdef readonly list verts
    cdef readonly list faces
    cdef readonly list edges
    cdef readonly list halfs

    # Object constructor methods.
    cpdef Vert _vert(self, double x, double y, double z, HalfEdge he=*)
    cpdef Edge _edge(self, HalfEdge he=*)
    cpdef Face _face(self, HalfEdge he=*)
    cpdef HalfEdge _half(self, HalfEdge twin=*, HalfEdge next=*,
                          Vert vert=*, Edge edge=*, Face face=*)

    # Public methods.
    cpdef void shortenEdges(self)
    cpdef int splitEdges(self, double max_edge_length=*) except -1
    cpdef double volume(self)
    cpdef double surfaceArea(self)
    cpdef void calculateNormals(self)
    cpdef void calculateCurvature(self)
    cpdef list getNearby(self, Vert v, int n)
    cpdef Vert splitEdge(self, Edge e)
    cpdef double[:] boundingBox(self)
    cpdef void writeObj(self, str path)
