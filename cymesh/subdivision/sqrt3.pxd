from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert, Face, Edge, HalfEdge

cpdef void split(Mesh mesh, Face f1, int max_vertices=?, int depth=?) except *
cpdef void divide_adaptive(Mesh mesh, double max_face_area) except *
