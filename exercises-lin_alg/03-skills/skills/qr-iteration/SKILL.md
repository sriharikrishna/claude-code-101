---
name: qr-iteration
origin: workshop
description: |
  Compute the singular values of a DENSE matrix (a 2D numpy array) via
  unshifted QR iteration. Use when the matrix is small enough to hold and
  factor densely and you want its singular values. Not for sparse matrices
  or matrix-free operators — use the lanczos skill for those.
---

<!--
The `origin:` field tags skills you wrote yourself versus imported ones,
so future-you knows what's safe to modify. Use any short tag —
`workshop`, `mygroup`, `community`, etc.
-->


# QR-iteration skill

Use this skill when:

- The user has a **dense** matrix (a 2D numpy array) and wants its singular values.
- The matrix is small enough to hold in memory and factor densely.

Do **not** use it for a sparse matrix or a matrix-free operator — QR iteration on `A^T A` densifies the problem. Route those to the `lanczos` skill.

## How to invoke

```bash
python .claude/skills/qr-iteration/qr_svd.py \
    --problem problem.py \
    --k 6 \
    --check
```

The `--problem` argument points to a Python file exposing `get_dense()` that returns a 2D numpy array. `--k` sets how many (largest) singular values to print; `--check` cross-validates against `numpy.linalg.svd`.

Output looks like:

```
dense matrix (200, 200): 200 singular values via QR iteration
  largest 6: [27.9731 27.5842 26.8831 26.416  26.2265 25.9241]
  max |QR - numpy.svd| = 4.43e-04
```

## Interpreting the output

- Unshifted QR iteration converges the **dominant** singular values first; the smallest ones converge slowest, so `--check` differences (if any) live in the tail.
- If the helper aborts with "this object is sparse," you pointed a dense-only tool at a sparse matrix — use `lanczos`.

## Extending

Add a Wilkinson shift to accelerate convergence of the small singular values, or a `--tol`/`--iters` flag to trade accuracy for speed. Keep the "largest first" output order — it is how the result is read.
