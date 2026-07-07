"""Matrix-free linear operator: one implicit (backward-Euler) step of the 2D
heat equation u_t = Delta u on the unit square, 5-point finite differences,
homogeneous Dirichlet BCs. Exposes only apply(v) = (I - dt*L)^{-1} v and
shape; it never forms a dense matrix.
"""
import argparse

import numpy as np
import scipy.sparse as sp
from scipy.sparse.linalg import splu


class HeatStepOperator:
    """One implicit heat step as a matrix-free linear operator."""

    def __init__(self, N=40, dt=0.01):
        self.N = N
        self.dt = dt
        self.shape = (N * N, N * N)
        self.dtype = float
        L = self._laplacian(N)
        A = (sp.identity(N * N, format="csc") - dt * L).tocsc()
        self._solve = splu(A).solve  # prefactorize once; reuse every apply

    @staticmethod
    def _laplacian(N):
        """2D 5-point Laplacian on an N-by-N interior grid (negative definite)."""
        h = 1.0 / (N + 1)
        d = sp.diags([1.0, -2.0, 1.0], [-1, 0, 1], shape=(N, N)) / h**2
        I = sp.identity(N)
        return (sp.kron(I, d) + sp.kron(d, I)).tocsc()

    def apply(self, v):
        """Action of the operator on a vector: one implicit time step."""
        v = np.asarray(v, dtype=float).reshape(-1)
        return self._solve(v)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(
        description="Time-step the 2D heat equation with the matrix-free operator."
    )
    ap.add_argument("--N", type=int, default=40, help="interior grid is N x N")
    ap.add_argument("--dt", type=float, default=0.01, help="time-step size")
    ap.add_argument("--steps", type=int, default=10, help="number of implicit steps to take")
    args = ap.parse_args()

    M = HeatStepOperator(N=args.N, dt=args.dt)

    # initial condition: a hot spot at the center of the plate
    u = np.zeros((args.N, args.N))
    u[args.N // 2, args.N // 2] = 1.0
    u = u.reshape(-1)

    print(f"step {0:>3}: peak temperature = {u.max():.4f}")
    for step in range(1, args.steps + 1):
        u = M.apply(u)
        print(f"step {step:>3}: peak temperature = {u.max():.4f}")
