import unittest
import numpy as np

from cymesh.mesh import Mesh
from cymesh.collisions.tri_intersection import tri_tri_intersection
from cymesh.collisions.findCollisions import findCollisions

def brute_force_collisions(mesh):
    collided = np.zeros(len(mesh.verts), dtype='uint8')

    print(collided.shape)

    for face1 in mesh.faces:
        v1, v2, v3 = face1.vertices()
        for face2 in mesh.faces:
            v4, v5, v6 = face2.vertices()

            if v1.id == v4.id or v1.id == v5.id or v1.id == v6.id:
                continue

            elif v2.id == v4.id or v2.id == v5.id or v2.id == v6.id:
                continue

            elif v3.id == v4.id or v3.id == v5.id or v3.id == v6.id:
                continue

            if tri_tri_intersection(v1.p, v2.p, v3.p, v4.p, v5.p, v6.p):
                collided[v1.id] = 1
                collided[v2.id] = 1
                collided[v3.id] = 1
                collided[v4.id] = 1
                collided[v5.id] = 1
                collided[v6.id] = 1

    return collided

class TestRandomlyDistribute(unittest.TestCase):
    def test(self):
        mesh = Mesh.from_obj('test/mesh_with_intersections.obj')

        brute_collisions = brute_force_collisions(mesh)
        speed_collisions = findCollisions(mesh)

        print(sum(brute_collisions))
        print(sum(speed_collisions))

        self.assertTrue((brute_collisions == speed_collisions).all())

if __name__ == '__main__':
    unittest.main()
