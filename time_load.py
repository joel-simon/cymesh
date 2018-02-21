import time
from cymesh.mesh import Mesh

start = time.time()
mesh = Mesh.from_obj('/Users/joelsimon/Projects/coral_growth_all/outputs/batch24/1RLV__February_16_2018_14_38/12/0/80.coral.obj')
print(time.time() - start)
