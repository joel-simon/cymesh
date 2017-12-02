# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True
from __future__ import print_function
from libc.math cimport floor, fmin, fmax, fabs
from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert, Face, Edge
from cymesh.collisions.tri_intersection cimport tri_tri_intersection
from cymem.cymem cimport Pool

import numpy as np
cimport numpy as np

cpdef int[:] findCollisions(Mesh mesh) except *:
    cdef Pool mem = Pool()

    cdef Edge edge
    cdef Face face
    cdef Node *node_a
    cdef Vert v1, v2, v3, v4, v5, v6
    cdef int nx, ny, nz, ix, iy, iz, fid, fid_a, fid_b, i, nynx
    cdef int dz, dy, dx, x_start, x_end, y_start, y_end, z_start, z_end
    cdef int vid1, vid2, vid3, vid4, vid5, vid6
    cdef int[:,:] face_vertices = np.zeros((len(mesh.faces), 3), dtype='i')
    cdef double[:,::1] vertices = np.zeros((len(mesh.verts), 3))
    cdef double[::1] vp1, vp2, vp3, vp4, vp5, vp6
    cdef double center_x, center_y, center_z, min_x, min_y, min_z, maxd
    cdef int[:,:] face_idx = np.zeros((len(mesh.faces), 3), dtype='i')
    cdef int[:] collided_faces = np.zeros(len(mesh.faces), dtype='i')
    cdef int[:] collided = np.zeros(len(mesh.verts), dtype='i')
    cdef double[:] bbox_a = np.zeros(6)
    cdef double[:] bbox_b = np.zeros(6)

    ############################################################################
    # Find the smallest value to offset everything by. prevents negative indexes.
    # Dimension size is the largest edge distance in any one dimension.

    min_x = mesh.verts[0].p[0]
    min_y = mesh.verts[0].p[1]
    min_z = mesh.verts[0].p[2]
    maxd = 0

    for edge in mesh.edges:
        v1 = edge.he.vert
        v2 = edge.he.twin.vert
        maxd = fmax(maxd, fabs(v1.p[0] - v2.p[0]))
        maxd = fmax(maxd, fabs(v1.p[1] - v2.p[1]))
        maxd = fmax(maxd, fabs(v1.p[2] - v2.p[2]))

    for v1 in mesh.verts:
        min_x = fmin(v1.p[0], min_x)
        min_y = fmin(v1.p[1], min_y)
        min_z = fmin(v1.p[2], min_z)

    for v1 in mesh.verts:
        assert v1.p[1] >= min_y, (v1.p[1], min_y)

    ############################################################################
    # Calculate grid size and then create.

    cdef double[:] bbox = mesh.boundingBox()
    nx = <int>((bbox[1] - bbox[0]) / maxd) + 1
    ny = <int>((bbox[3] - bbox[2]) / maxd) + 1
    nz = <int>((bbox[5] - bbox[4]) / maxd) + 1
    nynx = ny*nx

    cdef Node **grid = <Node **>mem.alloc((nx*ny*nz), sizeof(Node *))
    for i in range((nx*ny*nz)):
        grid[i] = NULL

    ############################################################################
    # Initialize all data buffers

    for v1 in mesh.verts:
        vertices[v1.id, 0] = v1.p[0]
        vertices[v1.id, 1] = v1.p[1]
        vertices[v1.id, 2] = v1.p[2]

    for face in mesh.faces:
        fid = face.id

        v1 = face.he.vert
        v2 = face.he.next.vert
        v3 = face.he.next.next.vert

        # Compute index bin of face center.
        center_x = (v1.p[0] + v2.p[0] + v3.p[0]) / 3.0
        center_y = (v1.p[1] + v2.p[1] + v3.p[1]) / 3.0
        center_z = (v1.p[2] + v2.p[2] + v3.p[2]) / 3.0

        face_idx[fid, 0] = <int>((center_x - min_x) / maxd)
        face_idx[fid, 1] = <int>((center_y - min_y) / maxd)
        face_idx[fid, 2] = <int>((center_z - min_z) / maxd)

        # Store face indices.
        face_vertices[fid, 0] = v1.id
        face_vertices[fid, 1] = v2.id
        face_vertices[fid, 2] = v3.id

        # Prepend node to linked list.
        i = face_idx[fid, 0] + face_idx[fid, 1]*nx + face_idx[fid, 2]*(nynx)

        if i < 0 or i >= nx*ny*nz:
            print(i, nx, ny, nz)
            print(list(face_idx[fid]))
            print(center_x, center_y, center_z)
            print(min_x, min_y, min_z)
            print(list(v1.p))
            print(list(v2.p))
            print(list(v3.p))
            assert False

        node_a = <Node *>mem.alloc(1, sizeof(Node))
        node_a.value = fid
        node_a.next = grid[i]
        grid[i] = node_a

    ############################################################################
    cdef size_t n_faces = len(mesh.faces)

    for fid in range(n_faces):
        if collided_faces[fid]:
            continue

        ix = face_idx[fid, 0]
        iy = face_idx[fid, 1]
        iz = face_idx[fid, 2]

        vid1 = face_vertices[fid, 0]
        vid2 = face_vertices[fid, 1]
        vid3 = face_vertices[fid, 2]

        vp1 = vertices[vid1]
        vp2 = vertices[vid2]
        vp3 = vertices[vid3]

        bbox_a[0] = min(vp1[0], vp2[0], vp3[0])
        bbox_a[1] = max(vp1[0], vp2[0], vp3[0])
        bbox_a[2] = min(vp1[1], vp2[1], vp3[1])
        bbox_a[3] = max(vp1[1], vp2[1], vp3[1])
        bbox_a[4] = min(vp1[2], vp2[2], vp3[2])
        bbox_a[5] = max(vp1[2], vp2[2], vp3[2])

        for dz in range(max(iz-1, 0), min(iz+1, nz)):
            for dy in range(max(iy-1, 0), min(iy+1, ny)):
                for dx in range(max(ix-1, 0), min(ix+1, nx)):

                    node_a = grid[dx + dy*nx + dz*(nynx)]

                    while node_a != NULL:
                        fid_b = node_a.value
                        node_a = node_a.next

                        vid4 = face_vertices[fid_b, 0]
                        vid5 = face_vertices[fid_b, 1]
                        vid6 = face_vertices[fid_b, 2]

                        # Connected faces cannot collide.
                        if vid1 == vid4 or vid1 == vid5 or vid1 == vid6:
                            continue

                        elif vid2 == vid4 or vid2 == vid5 or vid2 == vid6:
                            continue

                        elif vid3 == vid4 or vid3 == vid5 or vid3 == vid6:
                            continue

                        else:
                            vp4 = vertices[vid4]
                            vp5 = vertices[vid5]
                            vp6 = vertices[vid6]

                            bbox_b[0] = min(vp4[0], vp5[0], vp6[0])
                            bbox_b[1] = max(vp4[0], vp5[0], vp6[0])
                            bbox_b[2] = min(vp4[1], vp5[1], vp6[1])
                            bbox_b[3] = max(vp4[1], vp5[1], vp6[1])
                            bbox_b[4] = min(vp4[2], vp5[2], vp6[2])
                            bbox_b[5] = max(vp4[2], vp5[2], vp6[2])

                            if not bbox_intersect(bbox_a, bbox_b):
                                continue

                            if tri_tri_intersection(vp1, vp2, vp3, vp4, vp5, vp6):
                                # print('Found Collision')
                                # print('\t', fid, fid_b)
                                # print('\t', vid1, vid2, vid3)
                                # print('\t', vid4, vid5, vid6)
                                # print(list(bbox_a))
                                # print(list(bbox_b))
                                collided_faces[fid] = 1
                                collided_faces[fid_b] = 1
                                # collided[vid1] = 1
                                # collided[vid2] = 1
                                # collided[vid3] = 1
                                # collided[vid4] = 1
                                # collided[vid5] = 1
                                # collided[vid6] = 1

    for fid in range(n_faces):
        if collided_faces[fid]:
            collided[face_vertices[fid, 0]] = 1
            collided[face_vertices[fid, 1]] = 1
            collided[face_vertices[fid, 2]] = 1

    return collided
