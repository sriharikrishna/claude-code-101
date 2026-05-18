"""Toy Laplace solve on the L-shape. Used in workshop exercise 01-alt.

This script is deliberately under-specified: no convergence study,
the mesh is too coarse. The exercise is to ask Claude Code to
improve it under your CLAUDE.md conventions.
"""
from firedrake import *
import matplotlib.pyplot as plt


def manufactured(mesh):
    """Manufactured solution for -Delta u = f on the L-shape.

    u_exact(x, y) = sin(pi x) sin(pi y),  so  f = 2 pi^2 sin(pi x) sin(pi y).
    """
    x, y = SpatialCoordinate(mesh)
    u_exact = sin(pi * x) * sin(pi * y)
    f = 2 * pi**2 * sin(pi * x) * sin(pi * y)
    return u_exact, f


def solve_lshape(mesh):
    V = FunctionSpace(mesh, "CG", 1)
    u = TrialFunction(V)
    v = TestFunction(V)

    u_exact, f = manufactured(mesh)

    a = inner(grad(u), grad(v)) * dx
    L = f * v * dx
    bc = DirichletBC(V, u_exact, 1)

    u_h = Function(V, name="u")
    solve(a == L, u_h, bcs=bc)
    return u_h


if __name__ == "__main__":
    mesh = Mesh("lshape.msh")  # the textbook coarse mesh
    u_h = solve_lshape(mesh)

    fig, ax = plt.subplots()
    c = tripcolor(u_h, axes=ax)
    fig.colorbar(c)
    ax.set_aspect("equal")
    ax.set_title("Laplace solution on L-shape")
    plt.savefig("solution.png", dpi=120, bbox_inches="tight")
    print("Saved solution.png")
