import unittest
import numpy as np
from cymesh.collisions.tri_intersection import tri_tri_intersection

def intersect(tri_a, tri_b):
    tri_a = np.array(tri_a)
    tri_b = np.array(tri_b)
    return tri_tri_intersection(tri_a[0], tri_a[1], tri_a[2],
                                tri_b[0], tri_b[1], tri_b[2],)
class TestRandomlyDistribute(unittest.TestCase):
    def test_intersecting_1(self):
        inter_tri_a =  [[-2.086964, 1.219437, -0.480749],
                        [0.105598, -1.323423, 0.293974],
                        [0.105598, 1.219437, -0.480749]]

        inter_tri_b = [[-3.696262, 0.634013, -1.157567],
                        [0.716440, -0.634013, 1.178764],
                        [-1.503700, 0.634013, -1.157567]]

        self.assertTrue(intersect(inter_tri_a, inter_tri_b))

    def test_non_intersecting_1(self):
        non_inter_tri_a = [[-1.152708, 0.000000, -1.318530],
                        [1.039854, -0.000000, 1.339728],
                        [1.039854, 0.000000, -1.318530]]

        non_inter_tri_b = [[-3.696262, 0.000000, -1.318530],
                            [0.716440, -0.000000, 1.339728],
                            [-1.503700, 0.000000, -1.318530]]

        self.assertFalse(intersect(non_inter_tri_a, non_inter_tri_b))

    def test_non_intersecting_2(self):
        non_inter_tri_a = [[-0.543499, 0.512505, -0.022],
                            [-0.4708595, 0.596209, -0.098856],
                            [-0.543499, 0.512505, -0.175722]]

        non_inter_tri_b = [[-0.48288, 0.4783765, 0.2770005],
                            [-0.419127, 0.589371, 0.179248],
                            [-0.543499, 0.512505, 0.131742]]

        self.assertFalse(intersect(non_inter_tri_a, non_inter_tri_b))

if __name__ == '__main__':
    unittest.main()
