# Workshop Solutions — overview

These are walkthroughs of the six exercises with the math explained gently for non-mathematicians. Each exercise has its own `SOLUTION.md` inside its folder; this file is the index plus the running themes.

| # | Exercise | Solution file |
|---|---|---|
| 1 | Write a CLAUDE.md | [exercises/01-claude-md/SOLUTION.md](exercises/01-claude-md/SOLUTION.md) |
| 2 | Plan a small MINLP | [exercises/02-planning/SOLUTION.md](exercises/02-planning/SOLUTION.md) |
| 3 | Verify a KKT point | [exercises/03-skills/SOLUTION.md](exercises/03-skills/SOLUTION.md) |
| 4 | Bootstrap MEMORY.md | [exercises/04-memory/SOLUTION.md](exercises/04-memory/SOLUTION.md) |
| 5 | Wrap a solver as MCP | [exercises/05-mcp/SOLUTION.md](exercises/05-mcp/SOLUTION.md) |
| 6 | Capstone (PDE) | [exercises/06-capstone/SOLUTION.md](exercises/06-capstone/SOLUTION.md) |

## A glossary for non-mathematicians

The exercises sit on top of a few math terms. You don't need to be fluent — these short translations are enough to follow what's happening.

- **Optimization problem.** Find the inputs that minimize (or maximize) some quantity, possibly subject to rules called *constraints*. "Find the cheapest portfolio that returns at least 5%" is one.
- **Nonlinear / convex / nonconvex.** A problem is nonlinear if its math involves products or powers of variables. Convex problems have a single bottom; nonconvex ones can have multiple local bottoms.
- **MINLP.** Mixed-integer nonlinear program. Some variables must be whole numbers (e.g., "buy a stock or don't"); the rest are real-valued; the objective or constraints are nonlinear. These are usually hard.
- **PDE-constrained optimization.** The constraint isn't an equation, it's a *partial differential equation* — the kind that describes heat flow, fluids, or electromagnetic fields. Capstone uses this.
- **KKT conditions.** First-order optimality conditions for constrained problems — basically: "is this point actually a candidate solution?" Exercise 3 verifies them.
- **Multiplier (Lagrange / dual variable).** An auxiliary variable that captures how much a constraint "matters" at the optimum. Multipliers come along with primal solutions; KKT conditions tie them together.
- **Adjoint method.** A clever way to compute gradients of objectives that involve solving a PDE. Capstone uses this; the gradient check in exercise 6 verifies it.
- **CUTEst.** A standard test set of optimization problems researchers use to compare solvers — like a benchmark suite for compilers.

## Common themes across the solutions

1. **Claude Code amplifies what you put into it.** A blank session asking for "a convergence plot" gives you a generic answer; the same prompt with a CLAUDE.md gives you what you wanted. Every exercise is a variant of this lesson.
2. **The plan is the deliverable.** Especially in exercise 2 and the capstone — what Claude writes into `plan.md` is often more valuable than the code that follows.
3. **Friction kills the loop.** If summarizing into MEMORY.md takes ten minutes, you won't do it. The exercises pick conventions short enough that the ritual fits in two minutes.
4. **MCP at the seams, skills inside the project.** Recurring domain logic (KKT check) goes in a skill. External systems (databases, custom solvers) go behind an MCP. Don't mix the two.
