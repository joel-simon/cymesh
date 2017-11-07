import unittest
import random
from cymesh.mesh import Mesh

class TestRandomlyDistribute(unittest.TestCase):
    def valdiate_mesh(self, mesh):
        fids = [face.id for face in mesh.faces]
        vids = [vert.id for vert in mesh.verts]
        eids = [edge.id for edge in mesh.edges]
        hids = [half.id for half in mesh.halfs]

        self.assertTrue(len(fids) == len(set(fids)))
        self.assertTrue(len(vids) == len(set(vids)))
        self.assertTrue(len(eids) == len(set(eids)))
        self.assertTrue(len(hids) == len(set(hids)))

        for vert in mesh.verts:
            self.assertTrue(mesh.verts[vert.id] is vert)
            self.assertTrue(vert.he is not None)

        for edge in mesh.edges:
            self.assertTrue(mesh.edges[edge.id] is edge)
            self.assertTrue(edge.he is not None)

        for face in mesh.faces:
            self.assertTrue(mesh.faces[face.id] is face)
            self.assertTrue(face.he is not None)

        for he in mesh.halfs:
            self.assertTrue(mesh.halfs[he.id] is he)
            self.assertTrue(he.twin is not None)
            self.assertTrue(he.next is not None)
            self.assertTrue(he.vert is not None)
            self.assertTrue(he.edge is not None)
            self.assertTrue(he.face is not None)

        for vert in mesh.verts:
            vert_faces = set(vert.faces())
            vert_neighbors = set(vert.neighbors())

            self.assertTrue(len(vert_faces) > 0)
            self.assertTrue(len(vert_neighbors) > 0)

            for face in mesh.faces:
                if face in vert_faces:
                    self.assertTrue(vert in face.vertices())
                else:
                    self.assertTrue(vert not in face.vertices())

            for vert2 in mesh.verts:
                if vert2 in vert_neighbors:
                    self.assertTrue(vert in vert2.neighbors())
                else:
                    self.assertTrue(vert not in vert2.neighbors())

        for face in mesh.faces:
            face_vertices = set(face.vertices())
            self.assertTrue(len(face_vertices) > 0)

            for vert in mesh.verts:
                if vert in face_vertices:
                    self.assertTrue(face in vert.faces())
                else:
                    self.assertTrue(face not in vert.faces())

    def test_from_obj(self):
        mesh = Mesh.from_obj('triangulated_sphere_2.obj')
        self.valdiate_mesh(mesh)

    def test_split_edges(self):
        mesh = Mesh.from_obj('triangulated_sphere_2.obj')
        mesh.splitEdges()
        self.valdiate_mesh(mesh)

    def test_flip_edges(self):
        mesh = Mesh.from_obj('triangulated_sphere_2.obj')
        mesh.splitEdges()
        mesh.shortenEdges()
        self.valdiate_mesh(mesh)

    def test_modify(self):
        mesh = Mesh.from_obj('triangulated_sphere_2.obj')
        for _ in range(1):
            for v in mesh.verts:
                v.p[0] += (random.random()-.5) * .2
                v.p[1] += (random.random()-.5) * .2
                v.p[2] += (random.random()-.5) * .2
            mesh.splitEdges()
            mesh.shortenEdges()
        self.valdiate_mesh(mesh)

if __name__ == '__main__':
    unittest.main()
