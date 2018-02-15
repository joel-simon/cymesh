import random
import numpy as np
cimport numpy as np
from cymesh.vector3D cimport vdist
from cymesh.mesh cimport Mesh

cpdef double[:] d2_features(Mesh mesh, int n_points=1024, int bins=64) except *:
    """ 3D Shape features from 'Matching 3D Models with Shape Distributions'
        Paper pdf: https://graphics.stanford.edu/courses/cs468-01-fall/Papers/osada_funkhouser_chazelle_dobkin.pdf
        Returns a feature vector of size 'bins' from arbitrary sized mesh.
    """
    cdef int i, j
    cdef int n_verts = len(mesh.verts)
    cdef double[:] values = np.zeros(n_points)

    cdef int n = 0
    while n < n_points:
        i = random.randint(0, n_verts-1)
        j = random.randint(0, n_verts-1)
        if i != j:
            values[n] = vdist(mesh.verts[i].p, mesh.verts[j].p)
            n += 1

    return np.histogram(values, bins=bins, normed=True)[0]