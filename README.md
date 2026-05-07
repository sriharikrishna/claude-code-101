# Files, not chats

**Claude Code as a co-scientist — a workshop for mathematicians.**

A hands-on workshop for researchers in nonlinear, discrete, and PDE-constrained optimization. The central insight: durable AI collaboration is built from files, not chat history. The workshop is a tour of which files to keep and how they fit together.

Open `slides.html` in any modern browser.

- ← / → / Space — navigate
- type a number, then Enter — jump to slide
- `t` — toggle auto-advance (5-second timer)
- the nav bar at the bottom right has the same controls as buttons

The exercises live in `exercises/` and are referenced from the slides.

## How long does this take?

The full deck is **58 slides** with ~95 minutes of exercises (10+15+15+10+15+30). Three honest pacings:

| Format | Total time | What you do |
|---|---|---|
| **Talk only** (~75 min) | ~75 min | All 58 slides; exercises assigned as homework. |
| **2-hour workshop** (~2 h) | ~115 min | Slides + exercises 1–5; capstone as homework. |
| **Half-day workshop** (recommended) (~3 h) | ~150 min | Everything in-room, including the capstone. |

If you have only 90 minutes and want it hands-on, run exercises 1 and 3 only (CLAUDE.md and the kkt-checker skill). Everything else takes one paragraph to motivate and stays as a take-home.

## Quick setup

```bash
# Node 18+ required
npm install -g @anthropic-ai/claude-code

# Authenticate (opens a browser)
claude

# Minimum Python deps for exercises 1–5
python -m pip install --user numpy scipy matplotlib pytest

# Exercise 5 (MCP) additionally needs:
python -m pip install --user mcp cvxpy

# Capstone has its own install paths — see exercises/06-capstone/INSTALL.md
```

## Layout

```
.
├── slides.html               # the workshop deck (58 slides)
├── README.md                 # this file
├── SOLUTIONS.md              # walkthroughs for the six exercises
├── WORKFLOW.md               # sessions, version control, testing, plans, loops, literature
├── LITERATURE.md             # addendum: literature research, RAG, wiki-rag integration
└── exercises/
    ├── 01-claude-md/         # Write a CLAUDE.md for a SciPy Rosenbrock solve
    ├── 02-planning/          # Use plan mode on a small MINLP
    ├── 03-skills/            # KKT-checker skill on a QP (+ paper-summary skill)
    ├── 04-memory/            # Bootstrap MEMORY.md from lab notebook entries
    ├── 05-mcp/               # Wrap a toy QP solver as an MCP
    └── 06-capstone/          # Inverse Poisson with PETSc/TAO
        ├── INSTALL.md        # three install paths (pip / conda / docker)
        ├── plans/            # active plan file (TAO implementation)
        ├── CLAUDE.md
        ├── MEMORY.md
        ├── STATUS.md
        ├── requirements.txt
        └── environment.yml
```

## How to use the exercises

Each exercise folder is meant to be opened on its own. From the workshop root:

```bash
cd exercises/01-claude-md
claude
```

Inside Claude Code, follow the steps in that exercise's `README.md`.

## Speaker notes

- **Pacing.** Pick the table row above that fits your slot. The deck is dense and growing; you'll need to pick what to cut, not what to add. See "What to cut for a shorter slot" below.
- **Section dividers** (Parts 1 through 8) introduce each section; use them to take questions.
- **Stretch goals** appear in callout boxes labeled "Stretch" — skip them under time pressure.
- **Power features (Part 6)** is short and reference-y — checkpoints, subagents, hooks, headless mode. If you're tight on time, summarize verbally and point at `WORKFLOW.md`.
- **WORKFLOW.md and LITERATURE.md** are deeper companions to the deck. Don't try to cover them in slides; assign as reading.

### What to cut for a shorter slot

- **Below 90 min:** Drop Part 6 (Power features) and Part 7 (Working sustainably) entirely; turn them into reading. Keep CLAUDE.md, planning, skills, MEMORY.md, MCP, capstone-as-demo.
- **Below 60 min:** Drop the literature/RAG slides (Part 4 tail), Power features (Part 6), and Working sustainably (Part 7). Run only one exercise (Exercise 1 — CLAUDE.md). Treat the rest as a guided tour.

### What never to cut

- Slide 3 (Roadmap with the central insight).
- Slide 4 (Concept — introduces the co-scientist framing).
- The Plans-as-artifacts slide and prompt cookbook in Part 2.
- The STATUS.md handoff slides in Part 4.
- The verification/tests slide in Part 7.

## Audience

Mathematicians working on:

- Efficient and reliable methods for large-scale nonlinear optimization
- Applications of nonlinear and discrete optimization
- MINLP, optimization with PDE constraints, optimization with complementarity constraints

No AI background is assumed. Comfort with Python and the command line is.
