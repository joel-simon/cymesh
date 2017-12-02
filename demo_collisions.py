from __future__ import division

import time
from random import random, choice, seed
import numpy as np

from cymesh.mesh import Mesh
from cymesh.view import Viewer
from cymesh.collisions.findCollisions import findCollisions

from cymesh.subdivision.sqrt3 import divide_adaptive
from cymesh.operators.relax import relax_mesh

seed(1234)

mesh = Mesh.from_obj('triangulated_sphere_2.obj')
print('loaded mesh')

max_area =  max(f.area() for f in mesh.faces) * 1.5
start = time.time()

for i in range(10):
    print(i, 'n_verts:', len(mesh.verts))

    mesh.calculateNormals()
    mesh.calculateCurvature()

    for vert in mesh.verts:
        vert.data['old_p'] = np.copy(vert.p)

        if vert.data.get('collided', False):
            continue

        dist = random() * .4
        vert.p[0] += dist * vert.normal[0]
        vert.p[1] += dist * vert.normal[1]
        vert.p[2] += dist * vert.normal[2]

    collisions = findCollisions(mesh)
    print('n_collisions:', sum(collisions))

    for vi, collided in enumerate(collisions):
        if collided:
            vert = mesh.verts[vi]
            vert.data['collided'] = True
            vert.p[:] = vert.data['old_p']

    divide_adaptive(mesh, max_area)
    relax_mesh(mesh)

print('finished in ', time.time() - start)

mesh.writeObj('collided_mesh.obj')

v = Viewer((800, 800))
v.startDraw()
v.drawMesh(mesh)
v.endDraw()
v.mainLoop()

