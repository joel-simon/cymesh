# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True
from libc.math cimport sqrt, acos

cdef inline void vadd(double[:] target, double[:] a, double[:] b):
    target[0] = a[0] + b[0]
    target[1] = a[1] + b[1]
    target[2] = a[2] + b[2]

cdef inline void vsub(double[:] target, double[:] a, double[:] b):
    target[0] = a[0] - b[0]
    target[1] = a[1] - b[1]
    target[2] = a[2] - b[2]

cdef inline void vmultf(double[:] target, double[:] a, double f):
    target[0] = a[0] * f
    target[1] = a[1] * f
    target[2] = a[2] * f

cdef inline void vdivf(double[:] target, double[:] a, double f) except *:
    if f == 0.0:
        raise ZeroDivisionError()
    target[0] = a[0] / f
    target[1] = a[1] / f
    target[2] = a[2] / f

cdef inline void vcross(double[:] target, double[:] a, double[:] b):
    target[0] = a[1] * b[2] - a[2] * b[1]
    target[1] = a[2] * b[0] - a[0] * b[2]
    target[2] = a[0] * b[1] - a[1] * b[0]

cdef inline double dot(double[:] a, double[:] b):
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]

cdef inline double vdist(double[:] a, double[:] b):
    """ Euclidian distance between two 3D vectors.
        Faster than numpy.linalg.norm.
    """
    cdef double x = a[0] - b[0]
    cdef double y = a[1] - b[1]
    cdef double z = a[2] - b[2]
    return sqrt(x*x + y*y + z*z)

cdef inline void vset(double[:] a, double[:] b):
    a[0] = b[0]
    a[1] = b[1]
    a[2] = b[2]

cdef inline void inormalized(double[:] a):
    cdef double d = sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2])
    if d == 0.0:
        return
    a[0] /= d
    a[1] /= d
    a[2] /= d

cdef inline double vangle(double[:] a, double[:] b):
    return acos(dot(a, b) / (sqrt(dot(a, a)) * sqrt(dot(b, b))))

cdef inline double norm(double[:] a):
    return sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2])

