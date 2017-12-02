# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True

from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert, HalfEdge
from cymesh.vector3D cimport vadd, vsub, dot
import numpy as np
cimport numpy as np

cpdef void relax_mesh(Mesh mesh) except *:
    # Move vertexes towards their neighbors average

    cdef Vert vert
    cdef double mean_x, mean_y, mean_z
    cdef HalfEdge h, start, h_twin
    cdef int n_neighbors
    cdef double[:,:] old_p = np.zeros((len(mesh.verts), 3))
    cdef int i = 0

    for vert in mesh.verts:
        mean_x = 0
        mean_y = 0
        mean_z = 0
        n_neighbors = 0

        old_p[i,:] = vert.p

        # Iterate the neighbors
        h = vert.he
        start = h
        while True:
            h_twin = h.twin

            mean_x += h_twin.vert.p[0]
            mean_y += h_twin.vert.p[1]
            mean_z += h_twin.vert.p[2]
            n_neighbors += 1

            h = h_twin.next
            if h is start:
                break

        assert n_neighbors > 0
        vert.p[0] = mean_x / n_neighbors
        vert.p[1] = mean_y / n_neighbors
        vert.p[2] = mean_z / n_neighbors
        i += 1

    mesh.calculateNormals()

    # Project back by moving to the proejction of old position onto new normal vector.
    cdef double[:] a, p
    cdef double[:] ab = np.zeros(3)
    cdef double[:] ap = np.zeros(3)
    cdef double[:] b = np.zeros(3)
    cdef double c

    i = 0
    for vert in mesh.verts:
        a = vert.p

        vadd(b, a, vert.normal)
        p = old_p[i]
        vsub(ap, p, a)
        vsub(ab, b, a)

        # https://gamedev.stackexchange.com/questions/72528/how-can-i-project-a-3d-point-onto-a-3d-line
        c = dot(ap, ab) / dot(ab, ab)

        vert.p[0] = a[0] + c * ab[0]
        vert.p[1] = a[1] + c * ab[1]
        vert.p[2] = a[2] + c * ab[2]
        i += 1

