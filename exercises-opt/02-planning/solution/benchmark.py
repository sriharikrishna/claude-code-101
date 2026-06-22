"""Pareto-front benchmark harness for the cardinality-constrained portfolio.

Sweeps the risk/return trade-off parameter τ and, for each τ, runs a multistart
to probe the nonconvex landscape. Writes two CSVs:

  * runs CSV    — one row per (τ, start): objectives, KKT residuals, gap-to-best,
                  whether that start reached the best objective, timing, assets.
  * summary CSV — one row per τ: the best feasible solve plus ``hit_fraction``
                  (fraction of starts that reached f_best — a difficulty measure).

Optimality-gap caveat: the model is nonconvex (bilinear complementarity), so UNO
returns a *local* KKT point. ``gap_to_best`` is the gap to the best objective
*found across starts*, not a certified global gap; KKT residuals measure local
optimality only.

Usage::

    python benchmark.py                          # default log-spaced τ grid
    python benchmark.py --tau-grid "0,0.5,5" --n-starts 2
"""
import argparse
import csv

import numpy as np

import portfolio_model as pm
import solve as slv

RUNS_FIELDS = [
    "tau", "start_id", "ok", "optimization_status", "solution_status",
    "objective", "risk", "return", "mu_w",
    "kkt_stationarity", "kkt_feasibility", "kkt_complementarity",
    "gap_to_best", "reached_best", "solve_time_s", "n_iterations",
    "n_selected", "selected_assets",
]
SUMMARY_FIELDS = [
    "tau", "objective", "risk", "return", "mu_w", "n_selected", "selected_assets",
    "kkt_stationarity", "hit_fraction", "mean_solve_time_s", "best_solve_time_s",
    "n_starts", "n_starts_feasible",
]

GAP_TOL = 1e-6  # relative gap below which a start counts as "reached f_best"


def default_tau_grid():
    """τ = 0 (min-variance) plus a log-spaced sweep toward max-return."""
    return np.concatenate([[0.0], np.logspace(-2, 1.5, 24)])


def parse_tau_grid(spec):
    if spec is None:
        return default_tau_grid()
    return np.array([float(t) for t in spec.split(",") if t.strip() != ""])


def assets_str(indices):
    return "|".join(str(i) for i in indices)


def run_tau(Sigma, mu, tau, ti, K, n_starts, seed, preset, prev_x):
    """Run all starts for one τ. Returns (run_rows, summary_row, best_x)."""
    n = len(mu)
    starts = []
    if prev_x is not None:
        starts.append(("cont", np.asarray(prev_x, float)))  # continuation warm start
    for s in range(n_starts):
        rng = np.random.default_rng((seed, ti, s))
        w0 = rng.dirichlet(np.ones(n))          # feasible: w ≥ 0, 1ᵀw = 1
        z0 = rng.random(n)                       # z ∈ [0,1]^n
        starts.append((f"rand{s}", np.concatenate([w0, z0])))

    results = []
    for start_id, x0 in starts:
        r = slv.solve_once(Sigma, mu, tau, K, x0, preset=preset)
        r["start_id"] = start_id
        results.append(r)

    feasible = [r for r in results if r["ok"]]
    best_x = None
    if feasible:
        f_best = min(r["objective"] for r in feasible)
        best = min(feasible, key=lambda r: r["objective"])
        best_x = best["x"]
        for r in results:
            if r["ok"]:
                r["gap_to_best"] = (r["objective"] - f_best) / (abs(f_best) + 1e-12)
                r["reached_best"] = r["gap_to_best"] < GAP_TOL
            else:
                r["gap_to_best"] = ""
                r["reached_best"] = False
        n_hit = sum(1 for r in results if r["reached_best"])
        hit_fraction = n_hit / len(results)
        summary = {
            "tau": float(tau),
            "objective": best["objective"], "risk": best["risk"],
            "return": best["return"], "mu_w": best["mu_w"],
            "n_selected": best["n_selected"],
            "selected_assets": assets_str(best["selected_assets"]),
            "kkt_stationarity": best["kkt_stationarity"],
            "hit_fraction": hit_fraction,
            "mean_solve_time_s": float(np.mean([r["solve_time_s"] for r in results])),
            "best_solve_time_s": best["solve_time_s"],
            "n_starts": len(results),
            "n_starts_feasible": len(feasible),
        }
    else:
        for r in results:
            r["gap_to_best"] = ""
            r["reached_best"] = False
        summary = {
            "tau": float(tau), "objective": "", "risk": "", "return": "",
            "mu_w": "", "n_selected": "", "selected_assets": "",
            "kkt_stationarity": "", "hit_fraction": 0.0,
            "mean_solve_time_s": float(np.mean([r["solve_time_s"] for r in results])),
            "best_solve_time_s": "", "n_starts": len(results),
            "n_starts_feasible": 0,
        }

    run_rows = [{
        "tau": float(tau), "start_id": r["start_id"], "ok": r["ok"],
        "optimization_status": r["optimization_status"],
        "solution_status": r["solution_status"],
        "objective": r["objective"], "risk": r["risk"], "return": r["return"],
        "mu_w": r["mu_w"], "kkt_stationarity": r["kkt_stationarity"],
        "kkt_feasibility": r["kkt_feasibility"],
        "kkt_complementarity": r["kkt_complementarity"],
        "gap_to_best": r["gap_to_best"], "reached_best": r["reached_best"],
        "solve_time_s": r["solve_time_s"], "n_iterations": r["n_iterations"],
        "n_selected": r["n_selected"],
        "selected_assets": assets_str(r["selected_assets"]),
    } for r in results]
    return run_rows, summary, best_x


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tau-grid", default=None,
                    help="comma-separated τ values (default: 0 + logspace(-2,1.5,24))")
    ap.add_argument("--K", type=int, default=None, help="cardinality (default: from nlp_seed.py)")
    ap.add_argument("--n-starts", type=int, default=5, help="random starts per τ")
    ap.add_argument("--preset", default="filtersqp", help="UNO preset (filtersqp/ipopt/filterslp)")
    ap.add_argument("--seed", type=int, default=0, help="base RNG seed for starts")
    ap.add_argument("--runs-csv", default="bench_runs.csv")
    ap.add_argument("--summary-csv", default="bench_summary.csv")
    args = ap.parse_args()

    Sigma, mu, n, min_eig = pm.load_data()
    K = args.K if args.K is not None else int(__import__("nlp_seed").K)
    taus = parse_tau_grid(args.tau_grid)
    taus = np.sort(taus)  # ascending → continuation traces a connected branch

    print(f"n={n}, K={K}, min eig(Sigma)={min_eig:.3e}, preset={args.preset}")
    print(f"{len(taus)} τ values, {args.n_starts} random starts each\n")

    all_runs, summaries, prev_x = [], [], None
    for ti, tau in enumerate(taus):
        run_rows, summary, best_x = run_tau(
            Sigma, mu, tau, ti, K, args.n_starts, args.seed, args.preset, prev_x)
        all_runs.extend(run_rows)
        summaries.append(summary)
        if best_x is not None:
            prev_x = best_x  # warm-start next τ from this τ's best
        if summary["objective"] != "":
            print(f"  τ={tau:8.4f}  obj={summary['objective']:12.6f}  "
                  f"risk={summary['risk']:.5f}  return={summary['return']:+.5f}  "
                  f"sel={summary['n_selected']:>2}  hit={summary['hit_fraction']:.2f}")
        else:
            print(f"  τ={tau:8.4f}  INFEASIBLE (no feasible start)")

    with open(args.runs_csv, "w", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=RUNS_FIELDS)
        wr.writeheader()
        wr.writerows(all_runs)
    with open(args.summary_csv, "w", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=SUMMARY_FIELDS)
        wr.writeheader()
        wr.writerows(summaries)

    print(f"\nWrote {len(all_runs)} run rows -> {args.runs_csv}")
    print(f"Wrote {len(summaries)} summary rows -> {args.summary_csv}")


if __name__ == "__main__":
    main()
