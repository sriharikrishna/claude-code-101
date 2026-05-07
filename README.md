# Files, not chats

**Claude Code as a co-scientist — a workshop for mathematicians.**

A two-hour, hands-on workshop for researchers in nonlinear, discrete, and PDE-constrained optimization. The central insight: durable AI collaboration is built from files, not chat history. The workshop is a tour of which files to keep and how they fit together.

Open `slides.html` in any modern browser. Use ← / → arrow keys (or Space) to navigate. The exercises live in `exercises/` and are referenced from the slides.

## Quick setup

```bash
# Node 18+ required
npm install -g @anthropic-ai/claude-code

# Authenticate (opens a browser)
claude

# Python deps used across exercises
python -m pip install --user numpy scipy matplotlib pyomo cvxpy
# Optional, used in the capstone:
# python -m pip install --user petsc petsc4py
```

## Layout

```
.
├── slides.html               # the workshop deck (~54 slides)
├── README.md                 # this file
├── SOLUTIONS.md              # walkthroughs for the six exercises
├── WORKFLOW.md               # session, version-control, testing, and loop-recovery guide
├── LITERATURE.md             # addendum on literature research, RAG, and wiki-rag integration
└── exercises/
    ├── 01-claude-md/         # Write a CLAUDE.md for a SciPy Rosenbrock solve
    ├── 02-planning/          # Use plan mode on a small MINLP
    ├── 03-skills/            # Use a KKT-checker skill on a QP
    ├── 04-memory/            # Bootstrap MEMORY.md from lab notebook entries
    ├── 05-mcp/               # Wrap a toy QP solver as an MCP
    └── 06-capstone/          # Inverse Poisson with PETSc/TAO
```

## How to use the exercises

Each exercise folder is meant to be opened on its own. From the workshop root:

```bash
cd exercises/01-claude-md
claude
```

Inside Claude Code, follow the steps in that exercise's `README.md`.

## Speaker notes

- The deck is designed for ~2 hours including exercises. The longest single block is the capstone (30 min) — skip it for a 90-minute slot and assign it as homework.
- Section dividers introduce each part; use them to take questions.
- Stretch goals appear in callout boxes labeled "Stretch".
- The *Session basics* and *Working sustainably* sections (context window, Code-vs-Cowork, version control, loop detection) are short and rely on `WORKFLOW.md` for the full reference.

## Audience

Mathematicians working on:

- Efficient and reliable methods for large-scale nonlinear optimization
- Applications of nonlinear and discrete optimization
- MINLP, optimization with PDE constraints, optimization with complementarity constraints

No AI background is assumed. Comfort with Python and the command line is.
