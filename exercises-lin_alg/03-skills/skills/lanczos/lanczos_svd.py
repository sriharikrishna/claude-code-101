"""Dominant singular values of a LARGE SPARSE matrix or a MATRIX-FREE operator
via Lanczos (scipy.sparse.linalg.svds).

The --problem module must expose get_sparse() (a scipy sparse matrix) and/or
get_operator() (an object with .apply and .shape). Select which with --source.
The object is never densified. The operator is assumed symmetric, so the
adjoint action rmatvec is taken to be apply.
"""
import argparse
import importlib.util
import sys
from pathlib import Path

import numpy as np
import scipy.sparse as sp
from scipy.sparse.linalg import LinearOperator, aslinearoperator, svds


def load_problem(path: Path):
    spec = importlib.util.spec_from_file_location("problem_mod", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["problem_mod"] = mod
    spec.loader.exec_module(mod)
    return mod


def as_operator(obj):
    if sp.issparse(obj):
        return aslinearoperator(obj)
    return LinearOperator(obj.shape, matvec=obj.apply, rmatvec=obj.apply)


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--problem", required=True, help="Path to a .py exposing get_sparse()/get_operator()")
    p.add_argument("--source", choices=["sparse", "operator"], default="sparse")
    p.add_argument("--k", type=int, default=6, help="how many dominant singular values")
    args = p.parse_args(argv)

    mod = load_problem(Path(args.problem))
    getter = "get_sparse" if args.source == "sparse" else "get_operator"
    if not hasattr(mod, getter):
        sys.exit(f"--source {args.source} requires {getter}() in the problem module.")
    obj = getattr(mod, getter)()
    if isinstance(obj, np.ndarray):
        sys.exit("This object is dense. Use the qr-iteration skill for dense matrices.")

    op = as_operator(obj)
    _, s, _ = svds(op, k=args.k)
    s = np.sort(s)[::-1]
    label = "sparse matrix" if args.source == "sparse" else "matrix-free operator"
    print(f"{label} {op.shape}: dominant {args.k} singular values via Lanczos (svds)")
    print(f"  {np.round(s, 4)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
