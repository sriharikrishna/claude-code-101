"""Singular values of a DENSE matrix via unshifted QR iteration.

The --problem module must expose get_dense() returning a 2D numpy array.
QR iteration on A^T A drives it to diagonal; the singular values are the
square roots of the resulting eigenvalues, reported largest-first. The
dominant singular values converge first.
"""
import argparse
import importlib.util
import sys
from pathlib import Path

import numpy as np
import scipy.sparse as sp


def load_problem(path: Path):
    spec = importlib.util.spec_from_file_location("problem_mod", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["problem_mod"] = mod
    spec.loader.exec_module(mod)
    return mod


def qr_singular_values(A, iters=2000, tol=1e-9):
    M = np.asarray(A, dtype=float)
    M = M.T @ M
    for _ in range(iters):
        Q, R = np.linalg.qr(M)
        M = R @ Q
        off = np.sqrt(max(np.sum(M**2) - np.sum(np.diag(M) ** 2), 0.0))
        if off < tol:
            break
    eig = np.clip(np.diag(M), 0.0, None)
    return np.sort(np.sqrt(eig))[::-1]


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--problem", required=True, help="Path to a .py exposing get_dense()")
    p.add_argument("--k", type=int, default=6, help="how many largest singular values to print")
    p.add_argument("--check", action="store_true", help="cross-check against numpy.linalg.svd")
    args = p.parse_args(argv)

    mod = load_problem(Path(args.problem))
    if not hasattr(mod, "get_dense"):
        sys.exit("qr-iteration is for dense matrices: --problem must expose get_dense(). "
                 "For a sparse matrix or matrix-free operator, use the lanczos skill.")
    A = mod.get_dense()
    if sp.issparse(A):
        sys.exit("This object is sparse. QR iteration would densify A^T A — use the lanczos skill.")

    s = qr_singular_values(A)
    A = np.asarray(A, dtype=float)
    print(f"dense matrix {A.shape}: {len(s)} singular values via QR iteration")
    print(f"  largest {args.k}: {np.round(s[:args.k], 4)}")
    if args.check:
        ref = np.linalg.svd(A, compute_uv=False)
        print(f"  max |QR - numpy.svd| = {np.max(np.abs(s - ref)):.2e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
