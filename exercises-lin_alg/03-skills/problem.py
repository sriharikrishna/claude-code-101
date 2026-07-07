"""The three objects from exercises 01-02, exposed for the singular-value skills:

    get_dense()    -> the dense matrix from exercise 01 (matrix_A.npy)
    get_sparse()   -> the sparse matrix from exercise 01 (matrix_B.npz)
    get_operator() -> the matrix-free heat-step operator from exercise 02

Paths are resolved relative to this file, so it works from any cwd.
"""
import sys
from pathlib import Path

import numpy as np
import scipy.sparse as sp

HERE = Path(__file__).resolve().parent


def get_dense():
    return np.load(HERE.parent / "01-claude-md" / "matrix_A.npy")


def get_sparse():
    return sp.load_npz(HERE.parent / "01-claude-md" / "matrix_B.npz")


def get_operator():
    sys.path.insert(0, str(HERE.parent / "02-planning"))
    from heat_operator import HeatStepOperator
    return HeatStepOperator(N=40, dt=0.01)


if __name__ == "__main__":
    A = get_dense()
    B = get_sparse()
    M = get_operator()
    print(f"dense   : {A.shape} {A.dtype}")
    print(f"sparse  : {B.shape} {type(B).__name__}, nnz {B.nnz}")
    print(f"operator: {M.shape} matrix-free (apply only)")
