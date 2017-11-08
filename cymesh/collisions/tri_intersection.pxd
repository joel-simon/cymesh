cdef extern from 'triangle_triangle_intersection.h':
    int tri_tri_intersection_test_3d(double p1[3], double q1[3], double r1[3],
                                     double p2[3], double q2[3], double r2[3],
                                     int * coplanar,
                                     double source[3],double target[3])

cpdef int tri_tri_intersection(double[::1] P1, double[::1] P2,
                                double[::1] P3, double[::1] Q1,
                                double[::1] Q2, double[::1] Q3) except -1
