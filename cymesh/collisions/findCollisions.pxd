from cymesh.mesh cimport Mesh

cdef inline bint bbox_intersect(double[:] a, double[:] b):
    return (a[0] < b[1] and a[1] > b[0]) and \
            (a[2] < b[3] and a[3] > b[2]) and \
            (a[4] < b[5] and a[5] > b[4])

# Singly linked list structure.
cdef struct Node:
    int value
    Node *next

cpdef int[:] findCollisions(Mesh mesh) except *
