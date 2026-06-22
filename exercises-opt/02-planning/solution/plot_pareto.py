"""Plot the risk/return trade-off (Pareto front) from the benchmark summary CSV.

Left panel : risk (wᵀΣw) vs return (−μᵀw), one point per τ, connected in τ order
             and colored by τ. Both are *minimization* objectives, so the
             efficient region is the lower-left. Marker size ∝ number of selected
             assets.
Right panel: multistart hit-fraction vs τ — where the nonconvex problem gets hard.

Usage::

    python plot_pareto.py                      # reads bench_summary.csv -> pareto.png
    python plot_pareto.py --summary-csv s.csv --out front.png
"""
import argparse
import csv

import matplotlib
matplotlib.use("Agg")  # headless-safe
import matplotlib.pyplot as plt


def read_summary(path):
    """Read the summary CSV, keeping only τ rows that had a feasible solve."""
    rows = []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            if row["risk"] == "" or row["return"] == "":
                continue  # infeasible τ
            rows.append({
                "tau": float(row["tau"]),
                "risk": float(row["risk"]),
                "return": float(row["return"]),
                "n_selected": int(float(row["n_selected"])),
                "hit_fraction": float(row["hit_fraction"]),
            })
    rows.sort(key=lambda r: r["tau"])
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--summary-csv", default="bench_summary.csv")
    ap.add_argument("--out", default="pareto.png")
    args = ap.parse_args()

    rows = read_summary(args.summary_csv)
    if not rows:
        raise SystemExit(f"No feasible rows in {args.summary_csv}")

    tau = [r["tau"] for r in rows]
    risk = [r["risk"] for r in rows]
    ret = [r["return"] for r in rows]
    nsel = [r["n_selected"] for r in rows]
    hit = [r["hit_fraction"] for r in rows]

    fig, (ax, ax2) = plt.subplots(1, 2, figsize=(11, 4.5))

    # --- Pareto front ---
    ax.plot(risk, ret, "-", color="0.7", lw=1, zorder=1)
    sc = ax.scatter(risk, ret, c=tau, cmap="viridis",
                    s=[25 + 18 * k for k in nsel], zorder=2, edgecolor="k", linewidth=0.4)
    cbar = fig.colorbar(sc, ax=ax)
    cbar.set_label(r"$\tau$ (risk/return trade-off)")
    ax.set_xlabel(r"risk  $w^\top \Sigma w$")
    ax.set_ylabel(r"return objective  $-\mu^\top w$")
    ax.set_title("Pareto front (lower-left is better; marker size ∝ # assets)")
    ax.grid(True, alpha=0.3)

    # --- difficulty diagnostic ---
    ax2.plot(tau, hit, "o-", color="C3")
    ax2.set_xlabel(r"$\tau$")
    ax2.set_ylabel("multistart hit fraction")
    ax2.set_title("Fraction of starts reaching $f_\\mathrm{best}$")
    ax2.set_ylim(-0.05, 1.05)
    pos = [t for t in tau if t > 0]
    if pos and min(tau) >= 0:
        ax2.set_xscale("symlog", linthresh=min(pos))
        ax2.set_xlim(left=0)
    ax2.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(args.out, dpi=150)
    print(f"Wrote {args.out}  ({len(rows)} τ points)")


if __name__ == "__main__":
    main()
