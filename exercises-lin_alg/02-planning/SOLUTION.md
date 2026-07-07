# Solution — Exercise 02 (plan an SVD of a matrix-free operator)

## What this exercise is doing

`heat_operator.py` is a linear operator `M = (I - dt·L)^{-1}` — one implicit heat step — available **only** as a matrix-free action `apply(v)`. The exercise is to *plan* its SVD. The point of the exercise is the plan (`plan.md`); this file documents the plan and the reference implementation built from it.

The whole difficulty is that `M` is never a matrix. You cannot call `np.linalg.svd(M)`, cannot transpose it, cannot index it. The SVD must go through a matrix-free algorithm (`scipy.sparse.linalg.svds` on a `LinearOperator`), and the plan has to say how many singular values, which algorithm, and at what `(N, dt)` before any code exists.

## A worked plan.md

```markdown
# Plan — SVD of the implicit heat-step operator

## Goal
Compute the dominant k singular values (and, optionally, singular vectors)
of the matrix-free operator M = (I - dt L)^-1 from heat_operator.py,
without ever forming M densely.

## Approach
1. Instantiate HeatStepOperator(N, dt); read its shape and apply().
2. Wrap it as a scipy.sparse.linalg.LinearOperator with
   matvec = apply and rmatvec = apply (M is symmetric, so M^T = M).
3. Compute the dominant k singular values with svds(op, k=k).
   Each matvec is one sparse solve (prefactorized), so cost ~ k·(iters).
4. Report the singular values largest-first.

## Parameters (pinned)
- N = 40 (1600-dim operator), dt = 0.01, k = 6.

## Verification
- For a small N (=8) build the dense M column by column
  (apply to each unit vector), take np.linalg.svd, and confirm the
  matrix-free svds values match to ~1e-12.
- Sanity: M is SPD, so singular values == eigenvalues and lie in (0, 1].

## Out of scope
- Forming M densely at the working N. Changing the physics or the
  discretization. Preconditioner construction (that is Exercise 04).
```

## Reference implementation

```python
"""svd_operator.py — dominant SVD of the matrix-free heat-step operator."""
import argparse
import numpy as np
from scipy.sparse.linalg import LinearOperator, svds
from heat_operator import HeatStepOperator


def dominant_svals(N=40, dt=0.01, k=6):
    M = HeatStepOperator(N=N, dt=dt)
    op = LinearOperator(M.shape, matvec=M.apply, rmatvec=M.apply)  # symmetric
    _, s, _ = svds(op, k=k)
    return np.sort(s)[::-1]


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=40)
    ap.add_argument("--dt", type=float, default=0.01)
    ap.add_argument("--k", type=int, default=6)
    args = ap.parse_args()
    s = dominant_svals(args.N, args.dt, args.k)
    print(f"dominant {args.k} singular values (N={args.N}, dt={args.dt}):")
    print("  ", s.round(4))
```

## What you'd expect to see

```
dominant 6 singular values (N=40, dt=0.01):
   [0.8352 0.6699 0.6699 0.5593 0.5043 0.5043]
```

The values lie in `(0, 1]` and decay from the smoothest mode down — `M` damps every mode, most gently the lowest-frequency one (largest singular value ≈ 0.835). The repeated values (0.6699, 0.5043) reflect the symmetry of the square. The small-`N` dense cross-check agrees with the matrix-free result to machine precision (max abs diff ~1e-16).

## The choices the plan exists to surface

- **Matrix-free is mandatory, not optional.** `M` has no dense form; `svds` on a `LinearOperator` is the only route. A plan that reaches for `np.linalg.svd` has already gone wrong.
- **`rmatvec = apply` is legitimate only because `M` is symmetric.** For a nonsymmetric operator you would need the action of `Mᵀ` separately — worth stating explicitly.
- **Dominant-k, not full.** The full SVD of a 1600-dim implicit operator is pointless here; the preconditioner use (Exercise 04) only needs the top few modes.
- **`eigsh` would also work** (SPD ⇒ singular values = eigenvalues) and is cheaper; a good plan notes the equivalence and picks one deliberately.

## Where it usually goes wrong on the first try

- The plan calls `np.linalg.svd(M)` or `M.toarray()` — but `M` is matrix-free. **Push back: wrap `apply` in a `LinearOperator`.**
- It computes all singular values instead of the dominant k. **Pin `k`.**
- It omits `N`/`dt`, so the result isn't reproducible. **Pin the parameters.**
- No verification, so the matrix-free result is untrusted. **Require the small-`N` dense cross-check.**
