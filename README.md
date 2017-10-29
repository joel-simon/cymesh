# CyMesh

A Half-Edge mesh implemented in cython. The mesh is intended for dynamic manipulation. Splitting edges, fliping edges and calculating normals and curvatures are all supported.

Currently only supports tri-meshes.

TODO:

* support n-gon meshes and have a tri-mesh subclass
* save as .obj

## INSTALL
Requires cython and pygame/pyopengl for viewing.

```
git clone https://github.com/Sloth6/cymesh
cd cymesh
python setup.py build_ext --inplace
python demo.py
```

To install locally.

```
python setup.py install
```

## Demo
Here is all the code in demo.py for creating a mesh from an .obj file and viewing it. Mesh's can also be created from a list of polygons.

```
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

```

## Interface

### Mesh

```
Attributes:
    readonly list verts
    readonly list faces
    readonly list edges
    readonly list halfs

Methods:
    void shortenEdges()
    int splitEdges(double max_edge_length=0.0)
    double volume()
    void calculateNormals()
    void calculateCurvature()
    list getNearby(Vert v, int n)
    Vert splitEdge(Edge e)
```

### Vert

```
Attributes:
	readonly unsigned int id
	public double p[3]
	readonly double normal[3]
	readonly double curvature
	readonly HalfEdge he
	public dict data

Methods:
	list faces()
	list neighbors()
```

### Edge

```
Attributes:
    readonly unsigned int id

Methods:
    double length()
    tuple vertices()
    bint isBoundary()
    void flip()
```

### Face

```
Attributes:
    readonly unsigned int id
    readonly double normal[3]

Methods:
    list vertices()
    list edges()
```
