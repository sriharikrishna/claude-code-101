# Plan — Cardinality-constrained portfolio with unopy + Pareto sweep

## Context

`nlp_seed.py` ships only the *data* for a sparse mean-variance portfolio MINLP
(50 assets, `mu`, `Sigma`, `K=8`). The exercise is to build, around that seed, a
**continuous `unopy` (UNO) formulation**, a **τ-sweep that traces the Pareto front**
risk vs. return, a **benchmark harness writing a CSV**, and a **trade-off plot** —
all in the current directory only.

Two design points were confirmed with the user:
- **Optimality gap:** record *both* UNO's native KKT residuals *and* a multistart
  gap-to-best, **plus** the fraction of multistart solves that reach `f_best`
  (a basin-hit-rate / difficulty measure). True global gaps are unavailable —
  UNO is a local NLP solver and the model is nonconvex (see Limitations).
- **Risk metric:** the prompt's "risk = μᵀw" is a typo. **Risk = wᵀΣw**,
  **return = −μᵀw**; the raw `μᵀw` is also logged so nothing is lost.

## The model (continuous relaxation solved by UNO)

Decision vector `x ∈ ℝ^{2n}` (n=50 ⇒ 100 vars): `x[0:n]=w`, `x[n:2n]=z`.

```
min_x  f(x) = wᵀΣw − τ·μᵀw            (MINIMIZE)
s.t.   c0:  Σ w          = 1          bounds [1, 1]
       c1:  Σ z         ≤ K           bounds [−inf, K]
       c2:  Σ wᵢ(1−zᵢ)  ≤ 0           bounds [−inf, 0]   (bilinear → nonconvex)
       w ∈ [0, 1],  z ∈ [0, 1]
```

Analytic derivatives (clean because the model is quadratic + bilinear — no autodiff):
- ∇f: `grad_w = 2Σw − τμ`, `grad_z = 0`.
- Jacobian (sparse coordinate, nnz = 4n): c0→`∂/∂wᵢ=1`; c1→`∂/∂zᵢ=1`;
  c2→`∂/∂wᵢ=(1−zᵢ)`, `∂/∂zᵢ=−wᵢ`.
- Lagrangian Hessian, lower triangle (nnz = n(n+1)/2 + n), pattern constant:
  `σ₀·[[2Σ,0],[0,0]] + λ₂·[[0,−I],[−I,0]]` (only c2 contributes; c0,c1 linear).
  Cross terms `(row=n+i, col=i) = −λ₂` sit in the lower triangle.

## unopy API mapping (verified against `interfaces/Python/example/example_hs015.py`)

`unopy` is a low-level callback interface (`pip install unopy`):
- `model = unopy.Model(unopy.PROBLEM_NONLINEAR, 2*n, unopy.ZERO_BASED_INDEXING)`
- `set_variables_lower_bounds / set_variables_upper_bounds`
- `set_objective(unopy.MINIMIZE, objective_cb, objective_gradient_cb)`
- `set_constraints(3, constraints_cb, lower, upper, nnz_jac, jac_rows, jac_cols, jacobian_cb)`
  — Jacobian in COO (row/col index) form; precompute index arrays once.
- `set_lagrangian_hessian(nnz_hess, unopy.LOWER_TRIANGLE, hess_rows, hess_cols, hessian_cb)`
  + `set_lagrangian_sign_convention(...)` (e.g. `MULTIPLIER_NEGATIVE`) — **must be
  validated** (see Validation), it flips the sign of the λ₂ Hessian term.
- `set_initial_primal_iterate(x0)`
- Solve: `s = unopy.UnoSolver(); s.set_preset("filtersqp"); result = s.optimize(model)`.
  Default preset **`filtersqp`** (SQP + exact Hessian suits this QP-like nonconvex
  problem); allow `ipopt` as an alternative via config. Wrap optional
  `set_option("linear_solver","MUMPS")` / `QP_solver` / `LP_solver` in try/except —
  bundled backends vary; fall back to preset defaults and log what was used.
- Result fields used: `solution_objective`, `optimization_status`, `solution_status`,
  `solution_stationarity`, `solution_primal_feasibility`, `solution_complementarity`,
  `primal_solution`, `number_iterations`, `cpu_time`.

## Module layout (all new files, current dir; `nlp_seed.py` reused unmodified)

- **`portfolio_model.py`** — `build_model(Sigma, mu, tau, K, x0)` → `unopy.Model`.
  Precomputes COO index arrays + symmetrizes/validates Σ once; closures capture
  `Sigma, mu, tau` for the callbacks. Also exposes pure helpers
  `objective_value`, `risk(w)=wᵀΣw`, `ret(w)=−μᵀw` for post-processing.
- **`solve.py`** — `solve_once(tau, K, x0, preset)` → result dict
  (`w, z, objective, risk, ret, mu_w, kkt_*`, `status`, `n_iter`, `solve_time`,
  `selected`). `selected = {i : wᵢ > 1e-5}`. Includes `check_derivatives()` doing
  finite-difference checks of grad/Jacobian/Hessian before any sweep is trusted.
- **`benchmark.py`** — drives the τ-sweep + multistart, writes both CSVs.
  argparse: `--tau-grid`, `--K`, `--n-starts`, `--preset`, `--seed`,
  `--runs-csv ./bench_runs.csv`, `--summary-csv ./bench_summary.csv` (paths
  configurable, default into current dir).
- **`plot_pareto.py`** — reads the summary CSV, draws the trade-off plot.
  argparse `--summary-csv`, `--out ./pareto.png`.

## Pareto / multistart strategy

- **τ grid:** `[0.0] + logspace(-2, 1.5, ~24)` (configurable). τ=0 = min-variance;
  large τ = max-return. Log spacing because the frontier is curved.
- **Continuation:** iterate τ in increasing order; seed each τ with the previous
  τ's best `w,z` (traces a connected branch, faster convergence).
- **Multistart per τ (for gap + hit rate):** `n_starts` random starts —
  `w ~ Dirichlet(1ₙ)` (feasible: ≥0, sums to 1), `z ~ U[0,1]ⁿ` — **plus** the
  continuation start. Seed deterministically from `(seed, τ_index, start_id)`.
  Keep only solves with feasible/locally-optimal `optimization_status`.
- **Per τ:** `f_best = min feasible objective`; `gap_i = (f_i − f_best)/(|f_best|+1e-12)`;
  `reached_best = gap_i < 1e-6`; `hit_fraction = mean(reached_best)`.

## CSV schema

**`bench_runs.csv`** — one row per `(τ, start)`:
`tau, start_id, status, objective, risk, return, mu_w, kkt_stationarity,
kkt_feasibility, kkt_complementarity, gap_to_best, reached_best, solve_time_s,
n_iterations, n_selected, selected_assets` (assets as `"3|7|12|..."`).

**`bench_summary.csv`** — one row per τ (the best feasible solve):
`tau, objective, risk, return, mu_w, n_selected, selected_assets,
kkt_stationarity, hit_fraction, mean_solve_time_s, best_solve_time_s, n_starts_feasible`.

## Plot (`plot_pareto.py`)

- Main axes: **x = risk (wᵀΣw)**, **y = return (−μᵀw)**, one point per τ from the
  summary (the efficient frontier), connected in τ order, colored by τ (colorbar).
  Note in the caption that down-left is the better region for these two
  *minimization* objectives. Marker size ∝ `n_selected`.
- Small diagnostics subplot: `hit_fraction` vs τ (and/or `kkt_stationarity` vs τ)
  to visualize where the nonconvex problem gets hard.
- `figsize=(8,5)`, dpi 150, saved to configurable `--out` (default `./pareto.png`).

## Validation (before trusting any run)

1. `check_derivatives()` — finite-difference vs analytic grad, Jacobian, **and
   Hessian** at a random feasible point; this is what catches a wrong
   `set_lagrangian_sign_convention`.
2. Σ load check: symmetrize `0.5(Σ+Σᵀ)`, assert `min eig > 0` (PSD).
3. τ=0 sanity: solution ≈ min-variance portfolio; objective monotone-ish along τ.

## Verification (end to end)

1. `python nlp_seed.py` — confirms data loads (already works).
2. `python solve.py` — runs `check_derivatives()` + one solve, prints w, risk,
   return, KKT residuals, selected assets (expect ≤ K).
3. `python benchmark.py --tau-grid "0,0.5,5" --n-starts 2` — smoke test; inspect
   both CSVs for the columns above.
4. `python plot_pareto.py` — produce `pareto.png`; eyeball a downward/curved frontier.
5. Full run: default grid + `--n-starts 5`.

## Limitations to state in code/docstrings

- **No global optimality gap.** Model is nonconvex (bilinear c2); UNO returns local
  KKT points. `gap_to_best` is gap-to-best-*found*, not a certified global gap;
  KKT residuals measure local optimality only.
- **Continuous relaxation.** z is relaxed to [0,1]; cardinality is enforced softly.
  Selected assets come from `wᵢ > 1e-5`; |selected| may slightly exceed K.
  *Stretch:* round z to top-K and re-solve w-only for an integer-feasible point.
- Solver backend availability (BQPD/MUMPS/HiGHS) varies; harness probes and falls back.
