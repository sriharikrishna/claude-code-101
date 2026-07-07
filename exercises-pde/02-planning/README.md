# Exercise 02 — Plan a fix for a broken convergence test (15 min)

**Goal.** Use plan mode to design the fix for a convergence test that visibly fails, then have Claude implement the plan and re-run. The deliverable is working code with the optimal P1 convergence rate restored — not just a `plan.md`. The lesson is plan mode as a *design step you control*: it surfaces the questions ("which error indicator?", "which refinement mechanism?", "what counts as *near* the corner, and *how much* finer?") that you'd otherwise discover only after writing the wrong implementation.

**Setup.** Same containerized Firedrake as the first exercise. If you haven't done the Docker + Firedrake setup yet, follow [`../01-claude-md/INSTALL.md`](../01-claude-md/INSTALL.md) first. The pattern is the same: `claude` runs on your host (this folder is bind-mounted into the container); `python3 laplace_lshape.py` runs inside the container. **Keep the `CLAUDE.md` you wrote for Exercise 01** — you'll continue using and extending it here. Plan mode reads `CLAUDE.md` like any other session, so you can also add conventions there about *how plans should be presented* (level of detail, required sections, what counts as "done planning").

## The problem

The L-shaped domain has a *reentrant corner* — an interior angle larger than 180°. Solutions of `-Δu = f` lose regularity at such a corner, no matter how smooth `f` is, so the standard `O(h^(p+1))` finite element convergence rates are not what you actually observe in practice. The starter script makes this concrete: the manufactured solution is the canonical L-shape singular function `u(r, φ) = r^(2/3) sin(2φ/3)` in polar coordinates centered at the corner, and the convergence study refines the mesh *uniformly*. Running it shows the L² error rate plateauing around `4/3` instead of the expected `2`, and the H¹ rate around `2/3` instead of `1`. Uniform refinement spends most of its DOFs where the solution is already well-resolved; the cure is to refine the mesh more densely near the corner, where the regularity is lost.

## Why this problem (read before you start)

The L-shape corner singularity is one of the most-taught problems in finite element analysis. Every introductory FEM course covers it; every textbook on adaptive methods uses it as the opening example. Claude has seen the canonical solution — graded refinement around the reentrant corner — *many* times. That cuts both ways:

- The upside: Claude will not flounder. It will produce a reasonable-sounding plan quickly.
- The downside: Claude is drafting from a well-rehearsed answer template, not reasoning fresh about *your* code, *your* mesh, *your* boundary condition. It may try to skip or compress the error-diagnosis step ("we know it's the corner, let's just grade the mesh"). It may volunteer a refinement strategy that wasn't quite the one you asked for — or quietly *substitute* a different one mid-plan. It may rewrite parts of the harness because the textbook version uses a different structure.

**Claude is a tool. You are the scientist.** Your job is not to read the plan and accept it — it's to decide *how much structure you need to impose* so the plan matches the problem in front of you. We've done some of that for you: the prompt's "only the mesh is in scope" clause closes off two common drifts (changing polynomial order or the manufactured solution) — an example of the structure you impose to keep the plan honest. This exercise builds intuition for when more is needed; your `CLAUDE.md` from Exercise 01 is where to record the conventions worth carrying forward.

## Steps

1. Open this folder in a Claude Code session on your host:

   ```bash
   cd exercises-pde/02-planning
   claude
   ```

   Then start the Firedrake container (see [`../01-claude-md/INSTALL.md`](../01-claude-md/INSTALL.md) for the full command) with this folder bind-mounted at `/home/firedrake/work`.

2. Inside the container, run the starter:

   ```bash
   python3 laplace_lshape.py
   ```

   Read the table it prints. The L² rate column should sit around `4/3` and the H¹ rate around `2/3`, well below the `Expected rates for P1 on a smooth problem: L2 = 2.0, H1 = 1.0` footer line. This is real, not a bug — it is what uniform refinement on a domain with a reentrant corner buys you.

3. **Enter plan mode.** Press `Shift+Tab` twice; look for the plan-mode indicator at the bottom of the Claude Code screen. In plan mode, Claude will write a plan and stop — it will not edit files until you approve.

4. **Paste this prompt** verbatim and submit. Do not approve the plan yet.

   ```
   The convergence in this code is suboptimal. Create a plan to
   identify where the error is concentrated, then construct an a
   priori mesh refinement strategy in the problem regions.

   The polynomial order is fixed at P1; only the mesh is in scope.
   ```

   The two-step prompt and the "only the mesh is in scope" clause are deliberate scaffolding: they tell Claude *not* to compress diagnosis into refinement and *not* to wander out of mesh territory.

5. **Read the plan critically. Don't approve it yet.** Use the checklist below, watching for the two failure modes the framing warned about: Claude *skipping* the error-diagnosis step ("we know it's the corner — straight to refinement"), or *substituting* a strategy you didn't ask for (an a posteriori loop instead of a priori grading, or a recipe that assumes a different element family or mesh than yours). Either is pattern-matching on a familiar problem, not misbehavior — the check is on you.

6. **Decide what structure the plan needs, then push back.** Pick at least one vague checklist item and ask Claude to revise it — pin a specific Firedrake refinement primitive, fix the grading radius and depth, or require an element-wise error indicator before any refinement. If you find yourself making the same pushback every session, promote it to your `CLAUDE.md`. Iterate until you'd be comfortable approving; one round is the minimum, and the point is deciding *what's missing*, not the number of rounds.

7. **Approve.** Claude exits plan mode and implements. Watch the file changes — it should add graded refinement around the corner while leaving the convergence-study harness, the manufactured solution, the boundary condition, and the polynomial order untouched. It will most likely edit `laplace_lshape.py` in place; if you'd rather keep the original for a clean before/after, ask it to write the graded version into a sibling file (e.g. `laplace_lshape_graded.py`).

8. Re-run `python3 laplace_lshape.py` in the container. The L² rate should now climb *toward* `2.0` and H¹ *toward* `1.0` across the levels — not necessarily reach them. **You're done as soon as the rates visibly improve in the right direction** (e.g. L² climbing `1.3` → `1.7` → `1.85`). Closing the last of the gap is FEM-tuning craft — grading exponent, cell-shape behavior of the primitive, level count — and is *out of scope* here; don't spend workshop time on it. If the rates didn't move *at all*, the plan was wrong somewhere — return to plan mode and ask Claude to diagnose before changing anything. (Resist fix-by-poking; that defeats the lesson.)

## Critical-reading checklist

Read Claude's plan against this checklist before you respond. Each row is a place where, on a familiar problem, Claude tends to fill in a textbook default that may or may not be what you want for *this* code.

| Look for | Why it matters |
|----------|----------------|
| Does the plan name *how* it will identify where the error is concentrated, as a distinct step before refinement? | The most commonly skipped step — Claude already "knows" it's the corner. A concrete plan computes an element-wise diagnostic (`\|u_h − u_exact\|` per cell; `u_exact` is in the script) and *looks at it* before setting refinement parameters. Without this, step 1 of your prompt was elided. |
| Does the plan specify the refinement *mechanism* in Firedrake terms? | "Refine the mesh" is too vague. The plan should commit to a specific mechanism for in-memory graded refinement — `NetgenHierarchy` with a marker function, PETSc-level refinement of marked cells, or comparable. If the plan proposes writing a new `.msh` or `.geo` file on disk, push back: the existing `lshape.msh` is the base and stays as-is. |
| Did Claude substitute a different *strategy* than the one you asked for? | You asked for a priori graded refinement. If the plan describes an adaptive loop (compute indicator → mark → refine → re-solve → repeat), that's an a posteriori strategy in disguise — different machinery, different lesson. Either accept the substitution explicitly (and update your prompt to match) or push back. |
| Does the plan say how *near the corner* is defined? | A grading scheme needs concrete parameters — a radius from the reentrant corner (the origin), a refinement depth as a function of distance, or an equivalent. "Refine near the corner" without saying *how near* and *how much* will be ad-hoc when implemented. |
| Does the plan keep the existing convergence-study harness in place? | The diagnostic value of the rates table depends on running the *same* harness before and after. If the plan rewrites the harness while it's in there, you lose the comparison. |
| Does the plan touch the polynomial order? | It shouldn't. The prompt fixes P1. If Claude proposes "switch to P2," push back — that defeats the lesson. |
| Does the plan touch `lshape.msh` or propose a new `.geo`? | It shouldn't write or modify any mesh file on disk. Graded refinement happens in memory on the loaded base mesh. |
| Does the plan carry forward the `dx(degree=4)` quadrature setting on every integral? | The manufactured solution `r^(2/3) sin(2φ/3)` is non-polynomial. Firedrake's automatic quadrature-degree estimator over-estimates the required degree for integrands like this and assembly hangs. The starter pins `dx(degree=4)` on every integral for that reason; any new assembly Claude writes (for an element-wise error indicator, for example) needs the same treatment. |
| Does the plan say what's out of scope? | Good plans bound themselves. An honest plan names what it isn't doing (a posteriori adaptive marking, hp-refinement, alternative element families) so scope doesn't quietly grow during implementation. |

## Discussion prompts

- The framing here is that Claude is a tool and *you* are the scientist. What did you have to decide in this exercise that Claude could not have decided for you — and what did Claude decide *for you* without asking? Are you comfortable with the latter set?
- This exercise is on a problem Claude has seen many times before. How would your approach change on a problem Claude has *not* seen — say, a custom mixed formulation or a non-standard element pair? Where do you tighten the scaffolding, and where do you let Claude propose?
- Plan mode produces text, not code. After doing this exercise, what was the value really — the text Claude wrote, or the questions the *act* of planning forced you to answer for yourself? When would you skip plan mode?

## Stretch (optional, for experienced learners)

If you have FEM and Firedrake experience, or you want an extra challenge, try the *a posteriori* version in a fresh Claude Code session.
