# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True

from cymesh.mesh cimport Mesh
from cymesh.structures cimport Vert, Face, Edge, HalfEdge

cpdef void split(Mesh mesh, Face f1, int max_vertices=-1, int depth=0) except *:
    """ Root(3) subdivision, insert one vertex inside the face.
        http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.43.1955&rep=rep1&type=pdf
    """
    cdef int generation = f1.generation
    cdef double[:] midp
    cdef Vert v1, v2, v3, v4
    cdef HalfEdge he1, he2, he3, he11, he12, he21, he22, he31, he32
    cdef Face f2, f3
    cdef Edge e12, e23, e13

    if depth > 6: # Stupid hack to prevent 0-area faces: TODO - figure out why.
        f1.generation += 1
        return

    if max_vertices != -1 and len(mesh.verts) == max_vertices:
        return

    generation = f1.generation

    if generation % 2 == 0:
        midp = f1.midpoint()
        v4 = mesh._vert(midp[0], midp[1], midp[2])
        he1 = f1.he
        he2 = f1.he.next
        he3 = f1.he.next.next

        v1 = he1.vert
        v2 = he2.vert
        v3 = he3.vert

        f2 = mesh._face()
        f3 = mesh._face()

        # Create three new edges.
        e12 = mesh._edge()
        e23 = mesh._edge()
        e13 = mesh._edge()

        # Create two new half-edges for each face.
        he11 = mesh._half(vert=v2, face=f1, edge=e12, next=None, twin=None)
        he12 = mesh._half(vert=v4, face=f1, edge=e13, next=he1, twin=None)

        he21 = mesh._half(vert=v3, face=f2, edge=e23, next=None, twin=None)
        he22 = mesh._half(vert=v4, face=f2, edge=e12, next=he2, twin=None)

        he31 = mesh._half(vert=v1, face=f3, edge=e13, next=None, twin=None)
        he32 = mesh._half(vert=v4, face=f3, edge=e23, next=he3, twin=None)

        # Set half edge twins and nexts.
        he1.next = he11
        he11.next = he12
        he11.twin = he22
        he12.twin = he31

        he2.next = he21
        he21.next = he22
        he21.twin = he32
        he22.twin = he11

        he3.next = he31
        he31.next = he32
        he31.twin = he12
        he32.twin = he21

        # Connect old to faces.
        he2.face = f2
        he3.face = f3

        #Connect elements ot half-edges
        f2.he = he2
        f3.he = he3
        e12.he = he11
        e23.he = he21
        e13.he = he31
        v4.he = he12

        # Adaptive Refinement Logic.
        f1.generation = generation + 1
        f2.generation = generation + 1
        f3.generation = generation + 1

        f1.mate = he1.twin.face
        f2.mate = he2.twin.face
        f3.mate = he3.twin.face

        assert f1.area() > 0
        assert f2.area() > 0
        assert f3.area() > 0

        if f1.mate.generation == f1.generation:
            he1.edge.flip()
            f1.generation += 1
            f1.mate.generation += 1

        if f2.mate.generation == f2.generation:
            he2.edge.flip()
            f2.generation += 1
            f2.mate.generation += 1

        if f3.mate.generation == f3.generation:
            he3.edge.flip()
            f3.generation += 1
            f3.mate.generation += 1
        else:
            assert f1.mate is not None
    else:
        if f1.mate.generation == f1.generation - 2:
            split(mesh, f1.mate, max_vertices, depth+1)

        split(mesh, f1.mate, max_vertices, depth+1)

cpdef void divide_adaptive(Mesh mesh, double max_face_area) except *:
    cdef Face face
    cdef list to_divide = []

    for face in mesh.faces:
        if face.area() > max_face_area:
            to_divide.append(face)

    for face in to_divide:
        split(mesh, face)
