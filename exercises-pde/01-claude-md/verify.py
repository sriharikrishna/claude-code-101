import firedrake as fd
mesh = fd.UnitSquareMesh(8, 8)
V = fd.FunctionSpace(mesh, "CG", 1)
print("Function space dim:", V.dim())
