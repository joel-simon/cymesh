from random import random
from cymesh.mesh import Mesh
from cymesh.view import Viewer

m = Mesh.from_obj('triangulated_sphere_2.obj')

# Add noise to mesh.
for v in m.verts:
    v.p[0] += random() * .1
    v.p[1] += random() * .1
    v.p[2] += random() * .1

# If not given a max length, all edges are split.
m.splitEdges()

# Flip edges which will become shorter.
m.shortenEdges()

# Normals and curvature updates must be called after making changes to mesh.
m.calculateNormals()
m.calculateCurvature()

# We can also export the mesh to a dict of numpy arrays.
export = m.export()
print(export.keys())
# > dict_keys(['faces', 'vertice_normals', 'face_normals', 'vertices', 'curvature', 'edges'])

# View the mesh with pyopengl.
v = Viewer()
v.startDraw()
v.drawMesh(m)
v.endDraw()
v.mainLoop()
