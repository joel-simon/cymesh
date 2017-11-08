from __future__ import division

import time
from random import random, choice, seed
import numpy as np

from cymesh.mesh import Mesh
from cymesh.view import Viewer
from cymesh.collisions.findCollisions import findCollisions

seed(1234)

mesh = Mesh.from_obj('triangulated_sphere_2.obj')
print('loaded mesh')

max_length =  max(e.length() for e in mesh.edges) * 1.5
start = time.time()

for i in range(10):
    print('looping', i, len(mesh.verts))

    mesh.calculateNormals()
    mesh.calculateCurvature()

    curves = np.array([v.curvature for v in mesh.verts])

    print(curves.min(), curves.max(), curves.mean())

    for vert in mesh.verts:
        vert.data['old_x'] = vert.p[0]
        vert.data['old_y'] = vert.p[1]
        vert.data['old_z'] = vert.p[2]

        if vert.data.get('collided', False):
            continue

        if vert.curvature < .3:
            vert.p[0] += random() * vert.normal[0] * .4
            vert.p[1] += random() * vert.normal[1] * .4
            vert.p[2] += random() * vert.normal[2] * .4

    collisions = findCollisions(mesh)

    for vi, collided in enumerate(collisions):
        if collided:
            vert = mesh.verts[vi]
            vert.data['collided'] = True
            vert.p[0] = vert.data['old_x']
            vert.p[1] = vert.data['old_y']
            vert.p[2] = vert.data['old_z']

    mesh.splitEdges(max_length)
    mesh.shortenEdges()

print('finished in ', time.time() - start)

mesh.writeObj('collided_mesh.obj')

v = Viewer((800, 800))
v.startDraw()
v.drawMesh(mesh)
v.endDraw()
v.mainLoop()

