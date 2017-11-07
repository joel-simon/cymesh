import numpy as np
cimport numpy as np
from vector3D cimport cross, dot, vadd, vsub, vdivf, vdist, inormalized, vmultf

cdef class Mesh:
    """ A half edge data structure for tri-meshes.
    """
    def __init__(self, raw_points, raw_polygons):
        self.verts = []
        self.faces = []
        self.edges = []
        self.halfs = []

        # Objects for construction.
        cdef int nv = len(raw_points)
        cdef int nf = len(raw_polygons)
        cdef HalfEdge he, h_ba, h_ab, twin
        cdef dict pair_to_half = {} # (i,j) tuple -> half edge
        cdef dict he_boundary = {} # Create boundary edges.
        cdef int n_halfs = 0
        cdef int a, b

        cdef list verts = []
        cdef list halfs = []

        """ Build half-edge data structure.
        """
        # Create Vert objects.
        for i, p in enumerate(raw_points):
            verts.append(self._vert(p[0], p[1], p[2], he=None))

        # Create Face objects.
        for poly in raw_polygons:
            if len(poly) != 3:
                raise ValueError('Only Triangular Meshes Accepted.')

            face = self._face()
            face_half_edges = []

            # Create half-edge for each edge.
            for i, a in enumerate(poly):
                b = poly[ (i+1) % len(poly) ]
                pair_ab = (verts[a].id, verts[b].id)
                pair_ba = (verts[b].id, verts[a].id)

                h_ab = self._half(face=face, vert=verts[a], twin=None, next=None, edge=None)
                halfs.append(h_ab)

                pair_to_half[pair_ab] = len(halfs)-1
                face_half_edges.append(len(halfs)-1)


                # Link to twin if it exists.
                if pair_ba in pair_to_half:
                    h_ba =  halfs[pair_to_half[pair_ba]]
                    h_ba.twin = h_ab
                    h_ab.twin = h_ba
                    h_ab.edge = h_ba.edge
                else:
                    edge = self._edge(h_ab)
                    h_ab.edge = edge

            # Link them together via their 'next' pointers.
            for i, he_id in enumerate(face_half_edges):
                he = halfs[he_id]
                he.next = halfs[face_half_edges[(i+1) % len(poly)]]

        for (a, b) in pair_to_half:
            if (b, a) not in pair_to_half:
                twin = halfs[pair_to_half[(a, b)]]
                h_ba = self._half(vert=verts[b], twin=twin, next=None, edge=twin.edge, face=None)

                halfs.append(h_ba)
                he_boundary[b] = (len(halfs)-1, a)

        cdef int start, end
        # Link external boundary edges.
        for start, (he_id, end) in he_boundary.items():
            he = halfs[he_id]
            he.next = halfs[he_boundary[end][0]]
            # self.boundary_start = he

    @classmethod
    def from_obj(cls, filename):
        points = []
        faces = []

        with open(filename, 'r') as objfile:
            for line in objfile:
                if line.startswith('#'):
                    continue
                values = line.split()
                if not values:continue
                if values[0] == 'v':
                    points.append([float(v) for v in values[1:4]])
                elif values[0] == 'f':
                    face = []
                    for v in values[1:]:
                        w = v.split('/')
                        face.append(int(w[0]) - 1) # .obj uses 1 based indexing.
                    faces.append(face)

        return cls(points, faces)

    # Constructor functions.
    cdef Vert _vert(self, double x, double y, double z, HalfEdge he=None):
        cdef Vert vert = Vert(len(self.verts), x, y, z, he)
        self.verts.append(vert)
        return vert

    cdef Edge _edge(self, HalfEdge he=None):
        cdef Edge edge = Edge(len(self.edges), he)
        self.edges.append(edge)
        return edge

    cdef Face _face(self, HalfEdge he=None):
        cdef Face face = Face(len(self.faces), he)
        self.faces.append(face)
        return face

    cdef HalfEdge _half(self, HalfEdge twin=None, HalfEdge next=None, \
                          Vert vert=None, Edge edge=None, Face face=None):
        cdef HalfEdge he = HalfEdge(len(self.halfs), twin, next, vert, edge, face)

        if twin:
            twin.twin = he
        if vert:
            vert.he = he
        if edge:
            edge.he = he
        if face:
            face.he = he

        self.halfs.append(he)

        return he

    # Mesh modifying
    cpdef void shortenEdges(self):
        cdef:
            double d
            double epsilon = .01
            Vert v1, v2
            Edge edge

        for edge in self.edges:
            # Select Opposite Edges.
            v1 = edge.he.next.next.vert
            v2 = edge.he.twin.next.next.vert
            d = vdist(v1.p, v2.p)

            if edge.length() - d > epsilon:
                edge.flip()

    cpdef int splitEdges(self, double max_edge_length=0.0) except -1:
        """ Split all edges whose lenghths are greater than given limit.
        """
        cdef int n = 0
        cdef Edge edge

        # Copy list to avoid editing in place.
        for edge in list(self.edges):
            if edge.length() >= max_edge_length:
                self.splitEdge(edge)
                n += 1

        return n

    # Mesh calculation
    cpdef void calculateNormals(self):
        cdef:
            Face face
            Vert va, vb, vc
            double vab[3]
            double vbc[3]

        """ Initialize vert norm values to 0. """
        for va in self.verts:
            vmultf(va.normal, va.normal, 0)

        """ Calculate face normals. """
        for face in self.faces:
            va, vb, vc = face.vertices()
            vsub(vab, vb.p, va.p)
            vsub(vbc, vc.p, vb.p)
            cross(face.normal, vab, vbc)
            inormalized(face.normal)

        """ Add face normal to all adjacent verts. """
        for face in self.faces:
            va, vb, vc = face.vertices()
            vadd(va.normal, va.normal, face.normal)
            vadd(vb.normal, vb.normal, face.normal)
            vadd(vc.normal, vc.normal, face.normal)

        """ Normalize normals to unit length. """
        for va in self.verts:
            inormalized(va.normal)

        # node = self.faces
        # for i in range(self.n_faces):
        #     face = <Face *> node.data
        #     inormalized(&face.normal)
        #     node = node.next

    cpdef void calculateCurvature(self):
        # https://computergraphics.stackexchange.com/questions/1718/what-is-the-simplest-way-to-compute-principal-curvature-for-a-mesh-triangle
        cdef:
            Edge e
            Vert v1, v2
            HalfEdge h, start, h_twin
            int i = 0
            double a[3]
            double b[3]
            double total_curvature, d

        for v1 in self.verts:
            i = 0
            total_curvature = 0

            h = v1.he
            start = h

            while True:
                ###################
                # Curvature logic.

                # Iterate over each edge connected to vertex.
                h_twin = h.twin
                e = h.edge

                vsub(a, h.vert.normal, h.twin.vert.normal)
                vsub(b, h.vert.p, h.twin.vert.p)
                d = vdist(h.vert.p, h_twin.vert.p)

                if d != 0:
                    total_curvature += dot(a, b) / d
                    i += 1

                ####################
                i += 1
                h = h_twin.next

                if h == start:
                    break

            if i != 0:
                v1.curvature = total_curvature / i

    cpdef double volume(self):
        # https://stackoverflow.com/a/1568551/2175411
        cdef double v = 0
        cdef Vert v1, v2, v3
        cdef Face face

        for face in self.faces:
            v1, v2, v3 = face.vertices()
            v += signed_triangle_volume(v1.p, v2.p, v3.p)

        return abs(v)

    cpdef list getNearby(self, Vert v, int n):
        if n < 1:
            raise ValueError('n must be > 0.')

        cdef Vert v1, v2
        cdef set vseen = set([v])
        cdef list vopen = [v]
        cdef list next_open
        cdef int i

        for i in range(n):
            next_open = []
            for v1 in vopen:
                for v2 in v1.neighbors():
                    if v2 not in vseen:
                        next_open.append(v2)
                    vseen.add(v2)
                vopen = next_open

        return list(vseen)

    cpdef Vert splitEdge(self, Edge e):
        """ Split an external or internal edge and return new vertex.
        """
        cdef Face other_face, f_nbc, f_anc, f_dna, f_dbn
        cdef HalfEdge h_ab, h_ba, h_bc, h_ca, h_cn, h_nc, h_an, h_na, h_bn
        cdef HalfEdge h_ad, h_db, h_dn, h_nd
        cdef Edge e_an, e_nb, e_cn, e_nd
        cdef Vert v_a, v_b, v_c, v_n
        cdef double x, y, z

        if e.he.face is None:
            e.he = e.he.twin

        other_face = e.he.twin.face

        # Three half edges that make up triangle.
        h_ab = e.he
        h_ba = h_ab.twin
        h_bc = e.he.next
        h_ca = e.he.next.next

        # Three vertices of triangle.
        v_a = h_ab.vert
        v_b = h_bc.vert
        v_c = h_ca.vert

        # New vertex.
        x = (v_a.p[0] + v_b.p[0]) / 2.0
        y = (v_a.p[1] + v_b.p[1]) / 2.0
        z = (v_a.p[2] + v_b.p[2]) / 2.0
        v_n = self._vert(x, y, z)

        # Create new face.
        f_nbc = self._face()
        f_anc =  h_ab.face
        # Create two new edges.
        e_an = e
        e_nb = self._edge()
        e_cn = self._edge() # The interior edge that splits triangle.

        # Create twin half edges on both sides of new interior edge.
        h_cn = self._half(twin=None, next=None, vert=v_c, edge=e_cn, face=f_nbc)
        h_nc = self._half(twin=h_cn, next=h_ca, vert=v_n, edge=e_cn, face=f_anc)

        # Half edges that border new split edges.
        h_an = h_ab
        h_an.face = f_anc
        h_bn = h_ba
        h_bn.edge = e_nb
        h_nb = self._half(twin=h_bn, next=h_bc, vert=v_n, edge=e_nb, face=f_nbc)
        h_na = self._half(twin=h_an, next=h_ba.next, vert=v_n, edge=e_an, face=None)
        h_bc.face = f_nbc
        h_bc.next = h_cn
        h_ca.next = h_an
        h_an.next = h_nc
        h_cn.next = h_nb
        h_bn.next = h_na
        h_bn.twin = h_nb

        if other_face is not None:
            h_ad = h_na.next
            h_db = h_ad.next
            v_d = h_db.vert
            # Create new faces
            f_dna = other_face
            f_dbn = self._face()
            # Create new edge
            e_nd = self._edge()
            # Create twin half edges on both sides of new interior edge.
            h_dn = self._half(twin=None, next=h_na, vert=v_d, edge=e_nd, face=f_dna)
            h_nd = self._half(twin=h_dn, next=h_db, vert=v_n, edge=e_nd, face=f_dbn)
            h_bn.next = h_nd
            h_bn.face = f_dbn
            h_na.face = f_dna
            h_dn.next = h_na
            h_db.face = f_dbn
            h_db.next = h_bn
            h_ad.face = f_dna
            h_ad.next = h_dn
            v_b.he = h_bn

        return v_n

    cpdef double[:] boundingBox(self):
        cdef Vert v = self.verts[0]
        cdef double[:] bbox = np.zeros(6)

        bbox[0:2] = v.p[0]#, v.p[0]]
        bbox[2:2] = v.p[1]#, v.p[1]]
        bbox[4:6] = v.p[2]#, v.p[2]]

        for v in self.verts:
            bbox[0] = min(bbox[0], v.p[0])
            bbox[1] = max(bbox[1], v.p[0])

            bbox[2] = min(bbox[2], v.p[1])
            bbox[3] = max(bbox[3], v.p[1])

            bbox[4] = min(bbox[4], v.p[2])
            bbox[5] = max(bbox[5], v.p[2])

        return bbox

    cpdef void writeObj(self, str path):
        with open(path, 'w+') as out:
            out.write('# Created by cymesh.\n')
            id_to_idx = {}

            for i, vert in enumerate(self.verts):
                id_to_idx[vert.id] = i
                out.write('v %f %f %f\n' % (vert.p[0], vert.p[1], vert.p[2]))

            for face in self.faces:
                v1, v2, v3 = face.vertices()
                id1 = id_to_idx[v1.id] + 1
                id2 = id_to_idx[v2.id] + 1
                id3 = id_to_idx[v3.id] + 1
                out.write('f %i %i %i\n' % (id1, id2, id3))

    # Query
    def export(self):
        """ Return mesh as numpy arrays.
        """
        cdef:
            Vert v1, v2, v3
            Edge edge
            Face face
            dict vid_to_idx = {}

        self.calculateNormals()
        self.calculateCurvature()

        verts = np.zeros((len(self.verts), 3))
        vert_normals = np.zeros((len(self.verts), 3))
        curvature = np.zeros(len(self.verts))

        edges = np.zeros((len(self.edges), 2), dtype='i')
        faces = np.zeros((len(self.faces), 3), dtype='i')
        face_normals = np.zeros((len(self.faces), 3))

        for i, v in enumerate(self.verts):
            verts[i] = v.p
            vid_to_idx[v.id] = i
            vert_normals[i] = v.normal
            curvature[i] = v.curvature

        for edge in self.edges:
            v1, v2 = edge.vertices()
            edges[i, 0] = vid_to_idx[v1.id]
            edges[i, 1] = vid_to_idx[v2.id]

        for face in self.faces:
            v1, v2, v3 = face.vertices()
            faces[i, 0] = vid_to_idx[v1.id]
            faces[i, 1] = vid_to_idx[v2.id]
            faces[i, 2] = vid_to_idx[v3.id]
            face_normals[i] = face.normal

        return {'vertices': verts, 'edges':edges, 'faces':faces,
                'vertice_normals': vert_normals, 'face_normals':face_normals,
                'curvature': curvature}
