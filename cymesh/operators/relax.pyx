# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True

from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert, HalfEdge
from cymesh.vector3D cimport vadd, vsub, dot, norm, vcross
import numpy as np
cimport numpy as np

cpdef void relax_vert_cotangent(Vert vert, double[:] p) except *:
    cdef double mean_x, mean_y, mean_z, cotan1, cotan2, total_angle, weight
    cdef int n_neighbors
    cdef int j = 0
    cdef double[:] outer_curr
    cdef double[:] outer_next
    cdef double[:] outer_prev
    cdef double[:] v1 = np.zeros(3)
    cdef double[:] v2 = np.zeros(3)
    cdef double[:] v3 = np.zeros(3)
    cdef double[:] v4 = np.zeros(3)
    cdef double[:] vtemp = np.zeros(3)

    mean_x = 0
    mean_y = 0
    mean_z = 0
    n_neighbors = 0
    total = 0

    neighbors = vert.neighbors()
    n_neighbors = len(neighbors)

    for j in range(n_neighbors):
        outer_curr = neighbors[j].p
        outer_next = neighbors[(j+1) % n_neighbors].p
        outer_prev = neighbors[j-1].p # cython:wraparound is set to True

        vsub(v1, vert.p, outer_prev)
        vsub(v2, outer_curr, outer_prev)

        vsub(v3, vert.p, outer_next)
        vsub(v4, outer_curr, outer_next)

        vcross(vtemp, v1, v2)
        cotan1 = dot(v1, v2) / norm(vtemp)

        vcross(vtemp, v3, v4)
        cotan2 = dot(v3, v4) / norm(vtemp)

        weight = (cotan1 + cotan2) * .5

        mean_x += outer_curr[0] * weight
        mean_y += outer_curr[1] * weight
        mean_z += outer_curr[2] * weight

        total += weight

    p[0] = mean_x / total
    p[1] = mean_y / total
    p[2] = mean_z / total


cpdef void relax_mesh_cotangent(Mesh mesh) except *:
    # Move vertexes towards their neighbors average with cotangent weights.
    cdef Vert vert
    cdef double mean_x, mean_y, mean_z, cotan1, cotan2, total_angle, weight
    cdef int n_neighbors
    cdef double[:,:] old_p = np.zeros((len(mesh.verts), 3))
    cdef double[:,:] next_p = np.zeros((len(mesh.verts), 3))
    cdef int i = 0
    cdef int j =0
    cdef double[:] outer_curr
    cdef double[:] outer_next
    cdef double[:] outer_prev
    cdef double[:] v1 = np.zeros(3)
    cdef double[:] v2 = np.zeros(3)
    cdef double[:] v3 = np.zeros(3)
    cdef double[:] v4 = np.zeros(3)
    cdef double[:] vtemp = np.zeros(3)

    for vert in mesh.verts:
        mean_x = 0
        mean_y = 0
        mean_z = 0
        n_neighbors = 0
        total = 0

        old_p[i,:] = vert.p

        neighbors = vert.neighbors()
        n_neighbors = len(neighbors)

        # http://rodolphe-vaillant.fr/?e=69
        for j in range(n_neighbors):
            outer_curr = neighbors[j].p
            outer_next = neighbors[(j+1) % n_neighbors].p
            outer_prev = neighbors[j-1].p # cython:wraparound is set to True

            vsub(v1, vert.p, outer_prev)
            vsub(v2, outer_curr, outer_prev)

            vsub(v3, vert.p, outer_next)
            vsub(v4, outer_curr, outer_next)

            vcross(vtemp, v1, v2)
            cotan1 = dot(v1, v2) / norm(vtemp)

            vcross(vtemp, v3, v4)
            cotan2 = dot(v3, v4) / norm(vtemp)

            weight = (cotan1 + cotan2) * .5

            mean_x += outer_curr[0] * weight
            mean_y += outer_curr[1] * weight
            mean_z += outer_curr[2] * weight

            total += weight

        next_p[i, 0] = mean_x / total
        next_p[i, 1] = mean_y / total
        next_p[i, 2] = mean_z / total
        i += 1

    i = 0
    for vert in mesh.verts:
        vert.p[0] = next_p[i, 0]
        vert.p[1] = next_p[i, 1]
        vert.p[2] = next_p[i, 2]
        i += 1

    mesh.calculateNormals()

    # # Project back by moving to the projection of old position onto new normal vector.
    cdef double[:] a, p
    cdef double[:] ab = np.zeros(3)
    cdef double[:] ap = np.zeros(3)
    cdef double[:] b = np.zeros(3)
    cdef double c
    i = 0
    for vert in mesh.verts:
        p = old_p[i]
        a = vert.p
        vadd(b, a, vert.normal)

        # https://gamedev.stackexchange.com/questions/72528/how-can-i-project-a-3d-point-onto-a-3d-line
        vsub(ap, p, a)
        vsub(ab, b, a)
        c = dot(ap, ab) / dot(ab, ab)
        vert.p[0] = a[0] + c * ab[0]
        vert.p[1] = a[1] + c * ab[1]
        vert.p[2] = a[2] + c * ab[2]
        i += 1

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

