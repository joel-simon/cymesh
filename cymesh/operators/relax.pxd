from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert
cpdef void relax_vert_cotangent(Vert vert, double[:] p) except *
cpdef void relax_mesh_cotangent(Mesh mesh) except *
cpdef void relax_mesh(Mesh mesh) except *
