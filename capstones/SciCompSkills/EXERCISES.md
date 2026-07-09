# EXERCISES.md -- improving the scicomp-research-skills agent framework

A set of project-style exercises for graduate students in scientific
computing. You already know the mathematics (PDEs, inverse problems,
optimal experimental design, uncertainty quantification, optimisation,
scientific ML); these exercises teach you the *other* craft that this
repository embodies -- **agent-skill engineering**: how to design,
harden, and specialise the markdown "skills" that a coding agent loads
on demand.

The framework you are improving is deliberately good raw material for
this. Its own [`STATUS.md`](STATUS.md) calls it *provisional*: most
skill content is "informed prediction," it has **0 external users**, and
it openly names its "biggest current sin" as "the false confidence its
size projects." That honesty is the opening. Your job across these five
projects is to convert vague unease about an over-confident agent
framework into **evidence-graded, testable improvements** -- using, where
possible, the framework's own machinery to do so.

---

## Contents

- [How to use this file](#how-to-use-this-file)
- [Prerequisites](#prerequisites)
- [Known-limitations reference table](#known-limitations-reference-table)
- [Exercise 1 -- Red-team the skills: an empirical limitations audit](#exercise-1----red-team-the-skills-an-empirical-limitations-audit)
- [Exercise 2 -- Break the monoculture: generalise a skill beyond its base](#exercise-2----break-the-monoculture-generalise-a-skill-beyond-its-base)
- [Exercise 3 -- Make the framework enforce its own rules](#exercise-3----make-the-framework-enforce-its-own-rules)
- [Exercise 4 -- A domain-specialisation pipeline (flagship)](#exercise-4----a-domain-specialisation-pipeline-flagship)
- [Exercise 5 -- Propose and scaffold a literature-discovery skill](#exercise-5----propose-and-scaffold-a-literature-discovery-skill)
- [What to hand in](#what-to-hand-in)

---

## How to use this file

- Each exercise is a **multi-part project**, not a one-line task. Expect
  to spend real time; the sub-tasks build on each other.
- Model answers, design discussion, pitfalls, and grading rubrics live
  in [`SOLUTIONS.md`](SOLUTIONS.md). Try the exercise before reading the
  solution -- the point is the struggle, not the answer key.
- **Do all work in a fork or a scratch branch of a *dev checkout*** (any
  clone of this repo that is NOT `~/.scicomp-research-skills/`; a
  pre-commit hook refuses commits in the canonical checkout -- see
  [`AGENTS.md`](AGENTS.md) Section 2). Never edit the installed canonical
  copy.
- Before you invent any mechanism, read
  [`CONTRIBUTING.md`](CONTRIBUTING.md) and
  [`STATUS.md`](STATUS.md). The framework already has a three-tier
  feedback loop, four issue templates, an evidence-tier table, and a
  finding-ID (`F-NN`) system. Several exercises ask you to *use* that
  machinery; reinventing it is a graded pitfall.

## Prerequisites

- A coding agent that reads this repository (OpenCode, Claude Code,
  Codex, Cursor, ...). See the client-compatibility matrix in
  [`README.md`](README.md).
- The framework installed per [`README.md`](README.md) "Install once per
  machine," so skills load on demand.
- Working knowledge of at least one scientific-computing subfield you can
  use as a running example (Exercise 4 specialises the framework to *your*
  area).
- Comfort reading markdown + YAML frontmatter and running `git`,
  `shellcheck`, and basic shell tooling.

---

## Known-limitations reference table

Every exercise is anchored to a **real, verifiable** weakness in the
current framework. The table below is the shared evidence base; each row
is line-cited so you can confirm it yourself before building on it (do
that -- verifying a cited defect is the first skill this repository
teaches, per finding `F-17`). Line numbers reflect the repository state
as of the date-stamp footer of this file; if they have drifted, treat
re-locating the claim as part of the exercise.

| # | Limitation | Where to see it | Used by |
|:--|:-----------|:----------------|:--------|
| L1 | **Domain monoculture in `research-paper-writing`.** Its frontmatter declares `domain: ml-cv-nlp-research`; the Introduction "logic map" and Experiments guide hardcode an empirical deep-learning paper (task -> target metrics -> "SOTA methods fail" -> pipeline -> ablations; PSNR/LPIPS, teaser + pipeline figures, two-column layout). This narrative does not fit a numerical-analysis / theory paper (theorems, error bounds, convergence rates) -- the very papers the rest of the repo targets. The mismatch is never acknowledged in prose. | `skills/research-paper-writing/SKILL.md:7`; `skills/research-paper-writing/references/introduction.md:13-48`; `.../references/experiments.md:72,81` | Ex 1, Ex 2 |
| L2 | **Self-inconsistency (context budget).** `skills/human-facing-doc-authoring/SKILL.md` is 568 lines, over the "under 500 lines" ceiling its sibling skill preaches. That same budget file also *misreports* the agent-resource-discipline SKILL.md as "~250 lines" when it is 483. | `skills/agent-resource-discipline/references/context-window-budget.md:71,77`; `skills/human-facing-doc-authoring/SKILL.md` (line count); `skills/agent-resource-discipline/SKILL.md` (line count) | Ex 1, Ex 3 |
| L3 | **Self-inconsistency (tooling).** The `project-onboarding` audit tells the agent to run Bash `find` / `ls -la` / `grep`, exactly the pattern `agent-resource-discipline` forbids (use `Glob` / `Grep` instead). Two skills in one repo contradict each other. | `skills/project-onboarding/references/existing-project-audit.md:29,33,36,39,57,60,85,88,91,117` vs `skills/agent-resource-discipline/references/tool-selection.md:24-25` | Ex 1, Ex 3 |
| L4 | **Spec-vs-artifact gap.** `research-software-engineering` ships **4 of 12** planned references (01, 02, 11, 12); references 03-10 are spec'd with a "do NOT try to load these -- the files do not exist" warning. Three skills additionally defer all "Level 3" enforcement hooks to a future date. | `skills/research-software-engineering/SKILL.md:158-183`; `skills/agent-resource-discipline/SKILL.md:26-28`; `skills/project-onboarding/SKILL.md:24-26` | Ex 3 |
| L5 | **Over-generalisation from n=1.** Rules presented as general trace to a single project each: RSE reference 12 <- argo-anywhere; the onboarding auto-load trigger <- the AmigAI session; literature-survey / persistent-memory examples <- the rl-oed paper. | `skills/research-software-engineering/references/12-shell-and-cross-language-interop.md:9` ("6 rules surfaced by the argo-anywhere" project); `skills/project-onboarding/SKILL.md:39-57`; `skills/literature-survey/references/survey-note-template.md:96-172` | Ex 1, Ex 2 |
| L6 | **No domain-personalisation surface.** The only customisation axes are (a) per-project free-text sections in a project `AGENTS.md`, and (b) *programming language* via `MULTI-LANGUAGE.md` + `bootstrap.sh`. Scientific *domains* appear only as prose examples. The `domain:` frontmatter field exists on every skill (six distinct values) but is **read by no code**. There is no `DOMAIN-SPECIALIZATION.md`. | `templates/software-skeleton/MULTI-LANGUAGE.md`; `templates/software-skeleton/bootstrap.sh`; `domain:` in each `skills/*/SKILL.md:7` (never consumed) | Ex 4 |
| L7 | **Coverage gap: no literature *discovery* skill.** `literature-survey` begins at "add a *verified* BibTeX entry" and processes "each paper the user provides" -- it *organises* a corpus you have already assembled but has no *discovery* phase (database querying, citation-graph snowballing, relevance triage, a coverage/stopping criterion). Finding the papers you do not yet know about is unsupported. | `skills/literature-survey/SKILL.md:35-37,215` (workflow starts at verified-bibtex; input is user-provided papers) | Ex 5 |
| L8 | **Verification is manual, with no tooling.** `literature-survey`'s cardinal rule is "Never cite a paper you have not verified," but "verified" means a human hand-checks each entry -- there is no automated spurious-/hallucinated-citation detector, and no mechanism to declare or invoke an external tool that could provide one. This matters most for agent-*discovered* candidates, which can be fabricated. | `skills/literature-survey/SKILL.md:180`; no external-tool-dependency mechanism anywhere in the repo (cf. L6) | Ex 5 |
| M1 | **Existing self-improvement machinery (reuse, do not reinvent).** A three-tier feedback loop (`notes/agent_feedback.md` journal -> GitHub issue -> PR), four evidence-graded issue templates, an evidence-tier table, and the `F-NN` finding-ID system already exist. The `new-skill-proposal` template + the `append-evidence-to-skill-proposal` (F-19) mechanism handle proposing and accumulating evidence for a *new* skill. | `CONTRIBUTING.md:29-71,214-222`; `.github/ISSUE_TEMPLATE/`; `STATUS.md` | Ex 1, Ex 5, all |

---

## Exercise 1 -- Red-team the skills: an empirical limitations audit

**Theme:** *Understand* the limitations -- empirically, and by using the
framework's own feedback machinery to record them.

**Motivation.** The framework admits it is over-confident but does not
enumerate *where* that confidence is unearned. An agent framework is only
as good as the inputs it survives; the fastest way to find its edges is to
drive it slightly off-distribution and watch what breaks. You will produce
the missing map -- and, crucially, file it in the exact format the
framework consumes, so your audit could feed the real improvement loop.

**Sub-tasks.**

1.1 **Out-of-distribution stress test.** Ask your agent to load
`research-paper-writing` and draft the *introduction* of a
numerical-analysis / theory paper (e.g. a new preconditioner with a proved
condition-number bound and a convergence theorem -- no benchmark table, no
SOTA baseline, no ablation). Capture the transcript. Identify every point
where the skill's empirical-DL "logic map" (L1) is forced onto material it
does not fit. Then repeat the stress test on **one** other skill against
an input outside its comfort zone -- for example `literature-survey`'s
*mandatory* MathJax-in-every-survey-note rule applied to a
low-equation data/software paper, or `research-software-engineering`'s
MMS / convergence-rate correctness machinery applied to a combinatorial or
data-pipeline code that has no discretisation.

1.2 **Self-consistency audit.** Verify the framework against its *own*
stated rules. Confirm L2 (measure the line counts yourself), L3 (quote the
two contradicting passages), and at least one documentation-drift instance
(e.g. compare `STATUS.md`'s retirement-roadmap counts against the later
sessions recorded in `CHANGELOG.md`). For each, state which rule the
framework violates and cite both sides.

1.3 **Provenance / n=1 audit.** Pick three rules that read as general and
trace each to its single-project origin (L5). For each, judge: is the rule
plausibly general, or is it an over-fit to one codebase? What second,
*different* project would you need to see before trusting it?

1.4 **File findings correctly.** Read `CONTRIBUTING.md` and the four
templates in `.github/ISSUE_TEMPLATE/`. For your strongest three findings,
write `notes/agent_feedback.md`-format entries (the skeleton is in
`CONTRIBUTING.md` and in either template's `notes/agent_feedback.md`),
assign each a finding ID, and map each to (a) the correct issue template
and (b) the correct row of the evidence-tier table
(`CONTRIBUTING.md:214-222`).

**Reuse this existing machinery (M1).** Do not design a new bug-tracker;
the journal-entry format, issue templates, and evidence tiers already
exist. Your contribution is *evidence*, filed to spec.

**Deliverable.** `LIMITATIONS_AUDIT.md` (your findings, each with a
reproduction and citations) plus a short set of correctly-formatted
feedback entries. Do not commit these upstream -- they are your lab report.

---

## Exercise 2 -- Break the monoculture: generalise a skill beyond its base

**Theme:** *Robustness extension #1* -- remove a hardcoded narrow-domain
assumption so the skill survives a wider class of real inputs.

**Motivation.** Exercise 1 shows `research-paper-writing` assumes an
empirical deep-learning paper (L1). But scientific-computing papers come
in several shapes, and the skill silently mis-serves most of them. A
robust skill should *recognise which shape it is dealing with* and route
accordingly -- without ballooning into an unreadable monolith. This is the
core tension of skill engineering: coverage versus the context budget.

**Sub-tasks.**

2.1 **Model the hidden assumption.** Read the Introduction logic map and
Experiments guide and write down the implicit "paper archetype" they
encode. Then enumerate 3-4 archetypes that actually occur in
scientific computing -- for instance: *empirical-benchmark* (the current
default), *numerical-analysis / theory* (theorem -> proof -> corollary,
error/convergence bounds, no baselines), *methods / algorithm* (a new
solver, cost + stability analysis, illustrative not competitive
experiments), and *reproducibility / software artifact*. For each, note
how its introduction and evidence differ from the default.

2.2 **Design an archetype-routing gate.** Specify a first step the skill
takes on entry: detect or ask which archetype the paper is, then load
*only* the matching section guidance. Respect progressive disclosure --
the routing logic is small and lives in `SKILL.md`; the per-archetype
detail lives in separate `references/` files loaded on demand. Do not
inline four narratives into one file (that would reproduce L2).

2.3 **Author one new archetype branch.** Fully write the
*numerical-analysis / theory* reference: how to open (the problem and the
gap in existing guarantees, not "SOTA fails"), how to state contributions
as theorems / bounds, how to present numerical evidence that *confirms
theory* rather than beats a baseline, and what figures/tables actually
belong. Keep it within the framework's own reference budget (~150-300
lines; `context-window-budget.md`).

2.4 **Fix the frontmatter mismatch.** Reconcile the
`domain: ml-cv-nlp-research` tag (L1) with a repository whose stated scope
is scientific computing. Decide whether the field should change, become
multi-valued, or be redefined -- and justify it.

2.5 **Justify the change with evidence.** Using the evidence-tier table
(`CONTRIBUTING.md:214-222`), determine what evidence "a new rule in an
existing skill" and "a new reference file" require before they may ship.
Design the concrete validating sessions -- which papers, drafted by whom,
demonstrating what -- that would move your change from speculative to
grounded. (You are not required to run them all; you are required to
specify them.)

*Alternative track.* If your interests are more software than paper, apply
the identical five-step shape to `research-software-engineering`'s
Python/PDE monoculture: its correctness machinery (MMS, convergence rates,
finite-element condition numbers) assumes a discretised PDE and a Python
toolchain, and offers little to a non-PDE numerical code. Design the
archetype/routing analogue and author one non-PDE correctness reference.

**Reuse existing machinery.** Progressive disclosure and the
three-level skill structure are already codified
(`agent-resource-discipline/SKILL.md:13-32`); build your routing gate in
that idiom rather than inventing a new one.

**Deliverable.** A design document (archetypes + routing gate + frontmatter
decision), one complete new archetype `references/` file, and the
evidence plan from 2.5.

---

## Exercise 3 -- Make the framework enforce its own rules

**Theme:** *Robustness extension #2* -- close the gap between what the
framework *says* and what it *checks*, mechanically.

**Motivation.** The framework's quality disciplines (`F-17`
self-invalidation of drifting facts; `F-20` downstream-doc audit before
commit) currently depend on the agent *remembering* to run them, and its
own docs still drift (L2's mis-reported line count is proof). Meanwhile
three skills defer all enforcement to an unbuilt "Level 3" and one ships a
third of its references (L4). Rules a machine could check should not rely
on an agent's discipline. You will build the missing guard.

**Sub-tasks.**

3.1 **Inventory the enforceable gaps.** From Exercise 1 and L2-L4, list
the invariants the framework asserts but does not enforce. Separate the
*mechanically checkable* ones (line-count ceilings, forbidden tool
invocations in prose, references pointing at non-existent files, missing
date-stamp footers) from the ones that genuinely need human/agent judgment
(is a rule *correct*?). Only the former are in scope.

3.2 **Design the check.** Specify a lint job -- extending the existing
`.github/workflows/shellcheck.yml` continuous-integration surface -- that
mechanically enforces at least: (a) every `SKILL.md` is <= 500 lines;
(b) no skill or reference body instructs the agent to run the Bash
`find` / `grep` / `ls -R` patterns that `tool-selection.md` forbids;
(c) every referenced file that the text says to "load" actually exists (so
L4's "reference 03" cannot be cited as loadable while unshipped);
(d) every skill / plan-of-record doc ends with a date-stamp footer. Give
the check's logic precisely enough that another student could implement it;
a working prototype script is welcome but the *specification* is the graded
artifact.

3.3 **Resolve the two concrete contradictions.** Propose the actual edits
that would make L2 and L3 pass your own linter (e.g. split
`human-facing-doc-authoring` under the ceiling via progressive disclosure;
rewrite the onboarding audit to use `Glob`/`Grep`, or carve a documented
exception into `tool-selection.md`). You are designing the fix, not
necessarily landing it.

3.4 **Wire it in and document precedence.** Show where the job slots into
CI, what it runs on (paths filter), and how it interacts with the existing
`F-20` "downstream-doc audit" discipline -- which discipline is the
belt and which the suspenders. State explicitly what your linter can *not*
catch, so it does not itself project false confidence.

**Reuse existing machinery.** The repository already has a CI surface
(`shellcheck.yml`) and a self-audit doctrine (F-17/F-20 in
`CHANGELOG.md`); your job is to make the doctrine executable, not to invent
a parallel quality regime.

**Deliverable.** A design + prototype specification for the linter, the two
resolved contradictions (as proposed diffs or precise instructions), and a
short "what this cannot check" limitations note.

---

## Exercise 4 -- A domain-specialisation pipeline (flagship)

**Theme:** *The personalisation pipeline* -- build the axis the framework
is missing and use it to specialise the whole system to *your* research
area.

**Motivation.** The framework can adapt along programming *language*
(`MULTI-LANGUAGE.md` cleanly separates an agnostic core from Python-default
specifics and shows a worked Julia override) but has **no analogue for
scientific *domain*** (L6). Yet a domain is exactly where the highest-value
agent knowledge lives: the right correctness checks for a PDE-constrained
optimal-experimental-design problem (adjoint-consistent gradients,
A-/D-optimality, low-rank Hessian structure) are nothing like those for a
Monte-Carlo UQ pipeline. Worse, the framework currently only lets domain
knowledge flow *upward* as prose feedback; there is no way to push curated
domain expertise *down* into every project in that field. You will design
and prototype that missing capability, then specialise the framework to one
area you actually work in.

**Sub-tasks.**

4.1 **Design the domain layer by analogy.** Study how `MULTI-LANGUAGE.md`
structures the language axis: an explicitly language-agnostic core, a table
of adaptable defaults, and a fully worked override written into a project
`AGENTS.md`. Produce the parallel design for domains -- a
`DOMAIN-SPECIALIZATION.md` -- that names what is domain-agnostic (stays in
the shared skills) versus domain-specific (lives in a swappable "domain
pack"), and shows one worked override.

4.2 **Author a worked domain pack.** For one domain of your choice (e.g.
optimal experimental design for inverse problems), write three artifacts:
(a) a `research-software-engineering` domain reference -- e.g.
`references/domains/<domain>.md` covering the *correctness checks specific
to that domain* (for OED: adjoint-gradient verification via the
Taylor-remainder test, A-/D-optimality objective checks, posterior-
covariance / information-matrix sanity tests, low-rank Hessian
approximation error); (b) a domain-scoped literature seed for
`literature-survey` (a citekey taxonomy, the canonical venues, and a small
seed bibliography); (c) a pre-filled `PLAN.md` "Test Case Specification"
scaffold for a canonical problem in the domain (the paper-skeleton's
Section 2 is already OED-shaped -- turn its generic placeholders into a
concrete, selectable preset).

4.3 **Wire the loading mechanism.** Decide *how a project declares its
domain and how the pack gets loaded*. Weigh two options: (A) a convention
where a project `AGENTS.md` names domain reference files the same way it
already names skills to load; or (B) making the currently-dead `domain:`
frontmatter field actually dispatch (something reads it and auto-loads the
matching pack). Recommend one, specify the mechanism, and note the
migration cost.

4.4 **Build the specialisation workflow.** Mirror `project-onboarding`'s
audit -> plan -> execute -> verify -> document arc to produce a
*domain-onboarding* pipeline: given a chosen domain and a project, it
injects the pack, fills the project's "Mathematical conventions" facts
(`software-skeleton/AGENTS.md:126-128`), and records any overrides. Sketch
an optional `bin/specialize.sh` and the ready-to-paste prompt that would
drive it, in the style of the framework's existing onboarding prompts.

4.5 **Guard against over-specialisation.** Show that your design keeps the
agnostic core intact (a non-domain project loses nothing), lets a project
opt out or mix domains, and -- critically -- adds the *downward* injection
path without breaking the existing *upward* feedback channel
(`CONTRIBUTING.md` roll-up). State how a domain pack itself would be
evidence-graded before it ships, so the domain axis does not become a new
source of the "false confidence" the framework already fights.

**Reuse existing machinery.** Do not build a plugin runtime. The
`MULTI-LANGUAGE.md` pattern, the `project-onboarding` workflow, the
progressive-disclosure loader, and the evidence-tier gate are all
transplantable; your design should read as a natural fifth member of that
family.

**Deliverable.** `DOMAIN-SPECIALIZATION.md` (the design), one complete
worked domain pack (the three artifacts of 4.2), the loader + pipeline
specification, and the evidence plan for graduating a domain pack.

---

## Exercise 5 -- Propose and scaffold a literature-discovery skill

**Theme:** *New-skill engineering* -- fill a coverage gap by proposing an
entirely new skill, and make it *compose* with an existing one, using the
framework's own new-skill machinery to do it.

**Motivation.** The previous exercises harden or specialise skills that
exist. This one asks the harder question every framework maintainer faces:
*is a whole capability missing, and if so, is a new skill the right way to
add it?* The framework can *organise* a literature corpus
(`literature-survey`) but cannot *discover* one (L7): its workflow starts
at "add a verified BibTeX entry" and processes the papers the user already
hands it. The discovery phase -- deciding what to search, querying the
databases, chasing citations, triaging relevance, and knowing when you have
read enough -- is exactly the part a scicomp graduate student spends weeks
on and gets no help with here. But "add a skill" is a high bar in this
framework, and clearing it correctly is the lesson.

There is a sharper reason discovery needs care: **an agent-driven discovery
loop is a prime generator of *hallucinated* citations.** When an LLM
proposes "relevant prior work," some of what it returns is plausible-looking
but fabricated -- a risk this framework already worries about
(`literature-survey`'s first workflow rule is "Never cite a paper you have
not verified," `skills/literature-survey/SKILL.md:180`). So a discovery
skill is incomplete without a **verification gate** that confirms every
candidate is a real, findable publication before it can be cited. Sub-tasks
5.6-5.7 build that gate around an existing tool -- `ref-checker` -- rather
than reinventing it.

**Sub-tasks.**

5.1 **Establish the gap and justify a *new* skill.** Read the
`new-skill-proposal` template in `.github/ISSUE_TEMPLATE/`. It demands a
justification against **each** of the six existing skills (why this is not
a sub-case of one) and an honest prior-art search against named skill
catalogues. Do both. The sharpest part of the argument is distinguishing
*discovery* from *survey*: confirm from
`skills/literature-survey/SKILL.md` that its workflow presupposes a known
paper list, and argue why bolting discovery onto `literature-survey` would
overload a skill that is already a clean single-responsibility unit.

5.2 **Design the discovery workflow.** Specify the steps a
`literature-discovery` skill would run: turning a research question into
query strategies across sources (e.g. arXiv, Semantic Scholar / OpenAlex,
Google Scholar); **snowballing** (backward through a seed paper's
references, forward through its citations); de-duplication; relevance
triage (keep / maybe / discard with a reason); and -- the part beginners
skip -- an explicit **coverage / stopping criterion** (when is the search
"done enough"?). Each step needs a concrete output a human can inspect.

5.3 **Design the hand-off contract to `literature-survey`.** This is the
key design decision. A discovery skill should end exactly where
`literature-survey` begins: its output must be the *input*
`literature-survey` Step 1-2 expect (candidate citekeys with DOIs / source
URLs and a one-line relevance rationale), so the two skills chain -- discover,
then survey -- with no overlap and no gap. Draw the seam precisely and show
one worked example of a candidate record crossing it. **Place a
verification gate at this seam:** the contract should require that each
candidate is confirmed to exist (sub-task 5.6) before it is allowed to
cross into `literature-survey`; a candidate that cannot be verified is
*quarantined*, never silently cited.

5.4 **Write the SKILL.md sketch.** The `new-skill-proposal` template asks
for a ~50-line `SKILL.md` sketch. Produce it: frontmatter (name, a
selection-worthy `description`, and a `domain:` value appropriate to a
scientific-computing repo -- learn from L1's mis-tag), a "when to load this
skill" section, the workflow from 5.2, the hand-off contract from 5.3, and
a short `references/` plan that respects progressive disclosure. Obey the
skill-naming rules in `AGENTS.md` Section 8.

5.5 **Meet the evidence bar honestly.** The evidence-tier table
(`CONTRIBUTING.md:214-222`) sets the bar for a *new top-level skill*:
"a pattern recurring across 3+ sessions / 2+ projects + a one-page proposal
issue." Assess candidly whether the discovery gap clears that bar today or
should enter as a *below-threshold* proposal that accumulates evidence via
the `append-evidence-to-skill-proposal` (F-19) mechanism. Design the
sessions/projects that would provide the evidence, and say plainly which
state your proposal is in.

5.6 **Wire in a real verification tool: `ref-checker`.** Rather than build
a citation verifier from scratch, integrate an existing one. **ref-checker**
(`github.com/rbross-hpc/ref-checker`; R. Ross, Argonne; BSD-3) checks that
each reference in a paper corresponds to a real, findable publication,
tagging each **OK / CLOSEST / NO MATCH** by querying five bibliographic
sources (OpenAlex, CrossRef, DBLP, Semantic Scholar, arXiv) plus URL
liveness. Study its README, then design the integration:
- **Choose the right surface.** ref-checker's *native* mode takes a
  finished **PDF** and uses an LLM to extract the reference list (needs
  `OPENAI_API_KEY`). Your discovery/survey workflow has *structured
  candidate records*, not a PDF -- so use the surfaces that bypass the
  PDF+LLM path: `ref-checker check --refs-json PATH` (batch-verify a
  supplied reference list) or `ref-checker lookup <source> --doi/--title/
  --arxiv-id` (single-record JSON verifier). Justify your choice.
- **Write the adapter.** ref-checker does *not* parse BibTeX. Specify the
  small adapter that maps a discovery candidate (or a `bibliography.bib`
  entry) into ref-checker's `Reference` JSON shape (title, authors, year,
  doi, arxiv_id, venue, url).
- **Place the gate(s).** Decide where verification runs: at the discovery
  output (block NO MATCH before it enters the corpus), inside
  `literature-survey`'s Step 1 (automating the manual "verified" gate and
  writing the OK/CLOSEST/NO MATCH result into the `_collection_log.md`
  verification-status column, which already exists), and/or as a
  final-draft backstop (`ref-checker check draft.pdf` on the compiled PDF
  -- its native mode). Recommend which seam(s) and why.
- **Degrade gracefully.** The framework is plain-markdown and
  client-agnostic with zero required runtime dependencies; ref-checker is a
  Python 3.10+ CLI needing network and (for the PDF path) an API key.
  Specify how the workflow behaves when the tool or its keys are absent --
  it must fall back to the manual verification `literature-survey` already
  prescribes, never hard-fail. ref-checker is *recommended*, not required.
- **Treat the signal as triage, not an oracle.** OK/CLOSEST/NO MATCH is
  fuzzy title matching (0.80/0.90 thresholds), with real false positives
  and negatives. Define the human-in-the-loop policy: NO MATCH -> quarantine
  and investigate; CLOSEST -> a human confirms; never auto-reject on a
  CLOSEST, or you will drop real papers.

5.7 **Critique the extension.** In the framework's own honest-scoping
spirit, write a short assessment of what integrating ref-checker does *not*
solve and what it risks. At minimum address: the phase mismatch (a
PDF-oriented tool bolted onto a pre-draft workflow); the tension between an
external dependency and the framework's zero-dependency portability
promise, and the fact that the framework has *no mechanism today* to
declare an external-tool dependency; the circularity of using an
LLM-extraction tool to catch LLM hallucinations (and how the
`--refs-json`/`lookup` route sidesteps it); speed and rate-limit costs
(sequential, ~3-5 min per 60 references); ref-checker's own maturity
(v0.1.0, single-author, no releases) measured against the same evidence
bar the framework applies to itself; and coverage bias (its five sources
skew CS/physics/math, so niche scientific-computing venues, books, and
national-lab technical reports risk false NO MATCH).

**Reuse this existing machinery (M1, L7).** Do not invent a proposal
process -- the `new-skill-proposal` and `append-evidence-to-skill-proposal`
templates are the process. Do not re-solve resource discipline -- the
`agent-resource-discipline` skill already covers web-fetch caching and the
PDF lifecycle your discovery workflow will lean on; cite and reuse them.
And do not build a citation verifier -- integrate `ref-checker` (5.6).

**Deliverable.** A filled-in `new-skill-proposal` issue (with the six
per-skill justifications and prior-art search), the ~50-line `SKILL.md`
sketch, the hand-off-contract specification (with one worked candidate
record and the verification gate), the ref-checker integration design
(surface choice + adapter spec + gate placement + degradation policy), the
evidence plan from 5.5, and the critique from 5.7.

---

## What to hand in

Per exercise, submit the named deliverable plus a short (1-2 page)
reflection covering: which limitation you targeted and how you verified it
was real; the key design decision you made and the alternative you
rejected; and -- in the framework's own spirit -- an honest note on what
your improvement does *not* yet cover and what evidence would be needed to
trust it. All work stays in a dev-checkout branch or fork; nothing is
committed to the canonical checkout.

---

*Created 2026-07-08. Maintained by the scicomp-research-skills course
staff. Companion answer key: [`SOLUTIONS.md`](SOLUTIONS.md).*
