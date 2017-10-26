# cython: boundscheck=False
# cython: wraparound=True
# cython: initializedcheck=False
# cython: nonecheck=False
# cython: cdivision=True
from libc.math cimport sqrt, acos

cdef inline void vadd(double target[3], double a[3], double b[3]):
    target[0] = a[0] + b[0]
    target[1] = a[1] + b[1]
    target[2] = a[2] + b[2]

cdef inline void vsub(double target[3], double a[3], double b[3]):
    target[0] = a[0] - b[0]
    target[1] = a[1] - b[1]
    target[2] = a[2] - b[2]

cdef inline void vmultf(double target[3], double a[3], double f):
    target[0] = a[0] * f
    target[1] = a[1] * f
    target[2] = a[2] * f

cdef inline void vdivf(double target[3], double a[3], double f) except *:
    if f == 0.0:
        raise ZeroDivisionError()
    target[0] = a[0] / f
    target[1] = a[1] / f
    target[2] = a[2] / f

cdef inline void cross(double target[3], double a[3], double b[3]):
    target[0] = a[1] * b[2] - a[2] * b[1]
    target[1] = a[2] * b[0] - a[0] * b[2]
    target[2] = a[0] * b[1] - a[1] * b[0]

cdef inline double dot(double a[3], double b[3]):
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]

cdef inline double vdist(double a[3], double b[3]):
    cdef double x = a[0] - b[0]
    cdef double y = a[1] - b[1]
    cdef double z = a[2] - b[2]
    return sqrt(x*x + y*y + z*z)

cdef inline void vset(double a[3], double b[3]):
    a[0] = b[0]
    a[1] = b[1]
    a[2] = b[2]

cdef inline void inormalized(double a[3]):
    cdef double d = sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2])
    if d == 0.0:
        return
    a[0] /= d
    a[1] /= d
    a[2] /= d

cdef double vangle(double a[3], double b[3]):
    return acos(dot(a, b) / (sqrt(dot(a, a)) * sqrt(dot(b, b))))
