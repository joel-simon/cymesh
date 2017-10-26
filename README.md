# CyMesh

A Half-Edge mesh implemented in cython. The mesh is intended for dynamic manipulation. Splitting edges, fliping edges and calculating normals and curvatures are all supported.


## INSTALL
Requires numpy and pygame/pyopengl for viewing.

```
git clone https://github.com/Sloth6/cymesh
cd cymesh
python setup.py install
python demo.py
```

Here is all the code in demo.py for creating a mesh from an .obj file and viewing it. Mesh's can also be created from a list of polygons.

```
from cymesh.mesh import Mesh
from cymesh.viewer import Viewer

m = Mesh.from_obj('triangulated_sphere_2.obj')
m.calculateNormals()
m.calculateCurvature()

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
    int splitEdges(double max_edge_length)
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