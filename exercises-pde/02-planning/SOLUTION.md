# Solution — Exercise 01-alt (CLAUDE.md, FEM Laplace on L-shape)

## What this exercise is doing

We start with a tiny script (`laplace_lshape.py`) that uses Firedrake to solve `-Δu = f` on an L-shaped domain — the unit square with one quadrant cut out, a classic test geometry in finite-element analysis. The right-hand side `f` is chosen so that the exact solution is `u_exact(x, y) = sin(πx) sin(πy)`; this is called a *manufactured solution* and means we always know what the answer should be. The script is deliberately bare: a single coarse mesh, a single solve, a plot, and that's it. No convergence study, no measurement of error against `u_exact`.

The exercise asks Claude Code the same question (*"add a convergence study"*) twice: once with no instructions, once with a CLAUDE.md. The point is to see how much the briefing matters.

## A worked CLAUDE.md

This is what your CLAUDE.md should look like after editing. Every line earns its place.

```markdown
# Project: L-shape Laplace playground

## Goal
Toy FEM problem for the workshop. We use it to demonstrate convergence
studies and our standard figure conventions for numerical PDEs.

## Stack
- Firedrake (run inside the firedrakeproject/firedrake-jupyter container)
- matplotlib for figures (semilog or log-log by default)
- The mesh ships as lshape.msh — read once with Mesh("lshape.msh")

## Commands
- `python laplace_lshape.py`                # solve once and save solution.png
- `python laplace_lshape.py --convergence`  # write figures/convergence.pdf

## Conventions
- The L-shape mesh on disk (lshape.msh) is the *base* mesh. For
  h-refinement studies, build a MeshHierarchy from it; never modify or
  replace the .msh file itself.
- Polynomial order is a parameter (default P1). Convergence studies
  should sweep h at fixed order, not the other way around.
- Error against the manufactured solution is reported as L2 norm,
  computed with assemble(inner(u_h - u_exact, u_h - u_exact) * dx)**0.5.
- Figures go to figures/ as PDF, 4 inches wide. Convergence plots are
  log-log, with h on the x-axis and L2 error on the y-axis.

## Don'ts
- No GUI plotting (no plt.show()); always save to figures/ or to
  solution.png in the working directory.
- Never pass a .geo file into Firedrake's Mesh() constructor. The .msh
  on disk is already compiled; that is the only supported path.
- Don't pip install new packages without asking — the container already
  has what's needed.
```

## What Claude should produce after reading it

A reasonable response — the kind you can accept without rewriting — looks like this. The key signals are: it builds a `MeshHierarchy` from the supplied `lshape.msh` (no new mesh files, no `.geo`), it computes the L² error against the manufactured solution at each level, it saves the figure as `figures/convergence.pdf` on log-log axes, and it leaves the original single-solve path alone behind a `--convergence` CLI arg.

```python
"""laplace_lshape.py — solve and (optionally) run a convergence study."""
import argparse
from pathlib import Path

import matplotlib.pyplot as plt
from firedrake import *


def manufactured(mesh):
    x, y = SpatialCoordinate(mesh)
    u_exact = sin(pi * x) * sin(pi * y)
    f = 2 * pi**2 * sin(pi * x) * sin(pi * y)
    return u_exact, f


def solve_lshape(mesh, degree=1):
    V = FunctionSpace(mesh, "CG", degree)
    u = TrialFunction(V)
    v = TestFunction(V)
    u_exact, f = manufactured(mesh)
    a = inner(grad(u), grad(v)) * dx
    L = f * v * dx
    bc = DirichletBC(V, u_exact, 1)
    u_h = Function(V, name="u")
    solve(a == L, u_h, bcs=bc)
    return u_h, u_exact


def convergence_study(base_mesh, levels=4, degree=1):
    hierarchy = MeshHierarchy(base_mesh, levels)
    hs, errs = [], []
    for k, mesh in enumerate(hierarchy):
        u_h, u_exact = solve_lshape(mesh, degree=degree)
        err = sqrt(assemble(inner(u_h - u_exact, u_h - u_exact) * dx))
        hs.append(0.5 / 2**k)        # base mesh has h = 0.5; each level halves it
        errs.append(float(err))
        print(f"level {k}: h={hs[-1]:.4f}  L2 error={errs[-1]:.3e}")
    return hs, errs


def plot_convergence(hs, errs, out=Path("figures/convergence.pdf")):
    out.parent.mkdir(exist_ok=True)
    fig, ax = plt.subplots(figsize=(4, 2.6))
    ax.loglog(hs, errs, "o-")
    ax.set_xlabel("h")
    ax.set_ylabel(r"$\|u_h - u_{\mathrm{exact}}\|_{L^2}$")
    ax.invert_xaxis()
    fig.tight_layout()
    fig.savefig(out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--convergence", action="store_true")
    args = ap.parse_args()

    base = Mesh("lshape.msh")

    if args.convergence:
        hs, errs = convergence_study(base, levels=4)
        plot_convergence(hs, errs)
        print("wrote figures/convergence.pdf")
    else:
        u_h, _ = solve_lshape(base)
        fig, ax = plt.subplots()
        c = tripcolor(u_h, axes=ax)
        fig.colorbar(c)
        ax.set_aspect("equal")
        ax.set_title("Laplace solution on L-shape")
        plt.savefig("solution.png", dpi=120, bbox_inches="tight")
        print("Saved solution.png")
```

## What you'd expect to see

```
$ python laplace_lshape.py --convergence
level 0: h=0.5000  L2 error=2.4e-01
level 1: h=0.2500  L2 error=6.5e-02
level 2: h=0.1250  L2 error=1.7e-02
level 3: h=0.0625  L2 error=4.2e-03
level 4: h=0.0313  L2 error=1.0e-03
wrote figures/convergence.pdf
```

The figure is a straight line on log-log axes with slope ~2 — each halving of `h` cuts the L² error by ~4. That's the standard `O(h²)` convergence of P1 finite elements on a smooth manufactured solution, and it's the shape of plot you should look for to know your solver is correct.

(Numbers above are illustrative; expect the same shape, not exactly these values.)

## Where it usually goes wrong on the first try

- Claude tries to "refine the mesh" by writing a new `.geo` or `.msh` file. **Forbid it explicitly: only `MeshHierarchy` from the existing `lshape.msh`.**
- Claude saves the figure to `convergence.png` in the working directory instead of `figures/convergence.pdf`. **Add the rule.**
- Claude uses linear axes. **Specify "log-log by default" for convergence plots.**
- Claude uses a different error norm (max-norm, H¹) without saying so. **Pin L² in the conventions.**
- Claude calls `plt.show()`. **Forbid it explicitly.**

The loop is the same every time: try → notice what's wrong → put the fix into CLAUDE.md → try again. After two iterations the assistant matches your house style.
