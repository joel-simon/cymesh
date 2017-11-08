cpdef int tri_tri_intersection(double[::1] P1, double[::1] P2,
                                double[::1] P3, double[::1] Q1,
                                double[::1] Q2, double[::1] Q3) except -1:
    cdef int coplanar = 0
    cdef double source[3]
    cdef double target[3]

    return tri_tri_intersection_test_3d(&P1[0], &P2[0], &P3[0], &Q1[0], &Q2[0],
                                        &Q3[0], &coplanar, source, target)
