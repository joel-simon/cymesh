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
