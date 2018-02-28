import time
import numpy as np
import matplotlib.pyplot as plt
from cymesh.mesh import Mesh
from cymesh.shape_features import d2_features, a2_features
mesh = Mesh.from_obj('my_mesh.obj')

t1 = time.time()
plt.plot(d2_features(mesh, n_points=2028*5, n_bins=32, hrange=(0.0, 3.0)), label='d2')
plt.plot(a2_features(mesh, n_points=2028*5, n_bins=32, hrange=(0.0, 3.0)), label='a2')
print('Finished in', time.time() - t1)
plt.legend()
plt.show()