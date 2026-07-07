---
name: lanczos
origin: workshop
description: |
  Compute the dominant k singular values of a LARGE SPARSE matrix or a
  MATRIX-FREE linear operator (available only through matvec) using Lanczos
  (scipy.sparse.linalg.svds). Use when the object is sparse or is only
  available as an apply()/matvec — never densify it. For a small dense
  matrix, use the qr-iteration skill instead.
---

<!--
The `origin:` field tags skills you wrote yourself versus imported ones,
so future-you knows what's safe to modify.
-->


# Lanczos skill

Use this skill when:

- The user has a **large sparse** matrix and wants its dominant singular values.
- The user has a **matrix-free operator** (only `apply(v)` / matvec available), e.g. an implicit PDE solve.

Do **not** densify the object. For a small dense matrix, use the `qr-iteration` skill.

## How to invoke

```bash
# sparse matrix
python .claude/skills/lanczos/lanczos_svd.py --problem problem.py --source sparse --k 6

# matrix-free operator
python .claude/skills/lanczos/lanczos_svd.py --problem problem.py --source operator --k 6
```

The `--problem` module must expose `get_sparse()` (a scipy sparse matrix) and/or `get_operator()` (an object with `.apply` and `.shape`). `--source` selects which; `--k` sets how many dominant singular values.

Output looks like:

```
matrix-free operator (1600, 1600): dominant 6 singular values via Lanczos (svds)
  [0.8352 0.6699 0.6699 0.5593 0.5043 0.5043]
```

## Interpreting the output

- `svds` returns the dominant `k` singular values via implicitly restarted Lanczos; each iteration costs one matvec (for the operator, one `apply` = one sparse solve).
- If the helper aborts with "this object is dense," route it to `qr-iteration` instead.

## Extending

Add a `--which SM` option for the *smallest* singular values (useful for conditioning), or accept `rmatvec` separately so nonsymmetric operators are handled correctly (this skill assumes a symmetric operator, `rmatvec = apply`).
