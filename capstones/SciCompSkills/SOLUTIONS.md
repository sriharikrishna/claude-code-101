# SOLUTIONS.md -- answer key for EXERCISES.md

Instructor-facing companion to [`EXERCISES.md`](EXERCISES.md). For each
exercise this file gives (1) the intended approach / model-answer sketch,
(2) the key design decisions and the trade-offs behind them, (3) common
pitfalls and traps to watch for in submissions, and (4) a grading rubric.

These are **approaches and rubrics, not full artifacts**: the students
produce the audit reports, reference files, linter, and domain packs.
What follows is what a strong submission looks like and how to score it.

A cross-cutting grading principle, drawn straight from the framework's own
[`CONTRIBUTING.md`](CONTRIBUTING.md) evidence-tier table: **reward evidence
and honest scoping over volume and confidence.** The framework's
self-diagnosed sin is "false confidence its size projects"
([`STATUS.md`](STATUS.md)); a submission that fixes less but proves it, and
names what it did not fix, should outscore a sprawling but unverified one.

---

## Contents

- [Exercise 1 -- limitations audit](#exercise-1----limitations-audit)
- [Exercise 2 -- generalise a skill](#exercise-2----generalise-a-skill)
- [Exercise 3 -- enforce the rules](#exercise-3----enforce-the-rules)
- [Exercise 4 -- domain-specialisation pipeline](#exercise-4----domain-specialisation-pipeline)
- [Exercise 5 -- literature-discovery skill](#exercise-5----literature-discovery-skill)
- [Cross-exercise grading notes](#cross-exercise-grading-notes)

---

## Exercise 1 -- limitations audit

### Intended approach

A strong submission treats this as an experiment, not an opinion piece.

- **1.1 (OOD stress test).** The student should produce an actual
  transcript of `research-paper-writing` drafting a theory-paper
  introduction, and annotate the specific failures, not just assert them.
  The tell-tale symptoms of L1 to look for: the skill pushes a
  "task -> target metric -> baselines fail" opening onto a paper whose
  contribution is a *theorem*; it asks for a teaser/pipeline figure and an
  ablation table that a convergence-bound paper does not have; it frames
  novelty as task/pipeline/module type rather than as a new guarantee. The
  second skill's stress test should surface a comparable
  mismatch -- e.g. `literature-survey`'s rule that *every* survey note carry
  MathJax equations produces empty or contrived math on a
  software/data paper, or `research-software-engineering`'s MMS /
  convergence-rate machinery has nothing to say about a code with no
  discretisation.
- **1.2 (self-consistency).** The student measures, not guesses:
  `wc -l` on the two SKILL.md files confirms 568 > 500 and the 483-vs-"250"
  mis-report (L2); the two contradicting passages for L3 are quoted
  side-by-side; a drift instance is shown by diffing a count in `STATUS.md`
  against `CHANGELOG.md`.
- **1.3 (provenance).** Three "general" rules traced to one project each
  (L5), with a judgment on each: which are plausibly general (e.g. a
  shell-portability rule) and which are over-fit to one codebase (e.g. a
  rule shaped entirely by argo-anywhere's specific stack). The key move is
  naming the *second, different* project that would be needed to trust the
  rule -- this is the same "3+ sessions / 2+ projects" bar the framework
  itself uses for new skills.
- **1.4 (file to spec).** Entries follow the `notes/agent_feedback.md`
  skeleton, carry finding IDs, and are correctly routed: a wrong/
  contradictory fact -> `skill-bug`; an insufficient rule with session
  evidence -> `skill-improvement-from-experience`; a recurring missing
  capability -> `new-skill-proposal`. Each is mapped to the right
  evidence-tier row.

### Key design decisions

- **Reproduction over assertion.** The audit's value is that someone else
  can re-run it. Every finding should carry a citation *and* a repro.
- **Using the framework's own vocabulary.** Findings expressed as
  `F-NN` entries in the existing format could actually feed the real loop;
  findings written as free-form complaints could not.

### Common pitfalls

- **Asserting L1-L5 by paraphrasing this repo instead of verifying.** The
  cited line numbers may have drifted; a student who copies them without
  re-locating the claim has missed the first lesson (`F-17`).
- **Confusing "the agent gave a mediocre answer" with "the skill is
  wrong."** A limitation must be attributable to skill *content*, not to a
  weak prompt or model.
- **Reinventing a bug tracker** instead of using the four issue templates
  and the journal format (M1).
- **Over-claiming generality of a defect** -- ironically the same sin the
  framework commits. "This one prompt failed" is n=1 too.

### Rubric (100 pts)

| Criterion | Pts | What full marks looks like |
|:----------|:----|:---------------------------|
| OOD stress tests (1.1) | 25 | Two real transcripts; failures pinpointed to specific skill passages, not vibes. |
| Self-consistency audit (1.2) | 20 | L2 + L3 confirmed by measurement/quotation; one drift instance shown by comparison. |
| Provenance / n=1 audit (1.3) | 15 | Three rules traced to origin; each judged, with the missing-evidence project named. |
| Filed to spec (1.4) | 25 | Correct journal format + IDs; each finding routed to the right template *and* evidence tier. |
| Verification discipline | 10 | Every cited defect independently re-confirmed; drifted line numbers re-located. |
| Honest scoping | 5 | States which findings are n=1 and might not generalise. |

---

## Exercise 2 -- generalise a skill

### Intended approach

The student converts an implicit single-archetype assumption into an
explicit, routed, multi-archetype design -- without violating the context
budget.

- **2.1** A clean statement of the hidden "empirical-DL paper" archetype,
  then 3-4 genuinely distinct scicomp archetypes. A strong answer notes
  *what actually differs* per archetype: the shape of the opening (gap in
  guarantees vs. gap in benchmark performance), what counts as a
  contribution (a theorem/bound vs. a new SOTA number), and what evidence
  belongs (a convergence-rate plot confirming theory vs. an ablation table).
- **2.2** A routing gate that lives in `SKILL.md` as a short decision step
  ("detect or ask the archetype, then load the matching reference"), with
  per-archetype detail deferred to `references/` files. This is the crux:
  the fix must *use* progressive disclosure, not defeat it.
- **2.3** One complete `references/` file for the numerical-analysis /
  theory archetype, within the ~150-300 line reference budget, written in
  the same telegraphic register as the existing section guides.
- **2.4** A defensible resolution of the `domain: ml-cv-nlp-research`
  frontmatter: most likely making it multi-valued or repository-appropriate
  (`scientific-computing` plus a note that the vendored examples remain
  ML-flavoured), with the reasoning stated.
- **2.5** An evidence plan keyed to the tier table: "new rule in an
  existing skill" needs ~2 sessions where it would have helped; "a new
  reference file" needs a clear on-demand scope and a parent-SKILL overflow
  justification. The student specifies the actual validating
  sessions -- which paper archetypes, drafted to demonstrate what.

### Key design decisions

- **Routing vs. rewriting.** The right design does not rewrite the existing
  DL guidance; it demotes it to *one archetype among several* behind a
  gate. This preserves the vendored upstream material (which the skill
  deliberately does not modify) while removing its false universality.
- **Where the detection happens.** Asking the user one question at entry is
  cheaper and more reliable than trying to infer the archetype from a
  half-written draft; a strong answer defends this.

### Common pitfalls

- **Inlining all archetypes into one file**, recreating L2's over-length
  problem while fixing L1.
- **Adding a rule with no evidence plan** -- shipping speculation, the exact
  behaviour the framework is trying to cure.
- **Treating the vendored upstream references as freely editable.** The
  skill flags them as not-to-be-modified (false revision history); the fix
  should route *around* them, not rewrite them.
- **Fixing only the frontmatter** (a one-line change) and calling the
  monoculture solved -- the frontmatter is a symptom, the logic map is the
  disease.

### Rubric (100 pts)

| Criterion | Pts | What full marks looks like |
|:----------|:----|:---------------------------|
| Archetype model (2.1) | 20 | 3-4 distinct archetypes with concrete per-archetype differences. |
| Routing-gate design (2.2) | 20 | Gate in SKILL.md, detail in references; progressive disclosure respected. |
| New archetype reference (2.3) | 25 | Complete, budget-compliant, in-register theory-paper guide. |
| Frontmatter resolution (2.4) | 10 | Defensible, reasoned change -- not a bare relabel. |
| Evidence plan (2.5) | 20 | Correct tier identified; concrete validating sessions specified. |
| Budget discipline | 5 | Nothing over the 500/300-line ceilings; no monolith. |

---

## Exercise 3 -- enforce the rules

### Intended approach

The student turns prose disciplines into an executable check.

- **3.1** A clean partition of the framework's assertions into
  *mechanically checkable* (line ceilings, forbidden Bash patterns in prose,
  dangling "load reference NN" pointers, missing date-stamp footers) versus
  *judgment-requiring* (is a rule correct/useful?). Only the former is in
  scope; naming the boundary is itself graded.
- **3.2** A precise specification of a CI job extending
  `.github/workflows/shellcheck.yml`. Full marks require the check logic be
  concrete enough to reimplement: e.g. "for each `skills/*/SKILL.md`, fail
  if line count > 500"; "grep skill+reference bodies for `find `, `ls -R`,
  `` `grep `` invocations *presented as agent instructions* and fail, with
  an allowlist for legitimately-quoted counterexamples"; "for every
  `references/NN-*.md` cited as loadable, assert the file exists"; "assert a
  date-stamp footer regex in every skill / plan doc." A working prototype
  is a bonus; the spec is the graded artifact.
- **3.3** Concrete resolutions of L2 and L3: split
  `human-facing-doc-authoring` under the ceiling via progressive
  disclosure, and either rewrite the onboarding audit to `Glob`/`Grep` or
  document an explicit, narrow exception in `tool-selection.md`. Either is
  acceptable if justified; a hand-wave is not.
- **3.4** Placement in CI (paths filter mirroring `shellcheck.yml`), and an
  explicit statement of the belt-and-suspenders relationship to the `F-20`
  agent-run downstream-doc audit -- plus, in the framework's own spirit, a
  "what this linter cannot catch" note (it checks form, not truth).

### Key design decisions

- **Machine-checkable subset first.** The insight worth rewarding is that
  the framework already *knows* its rules; the missing piece is
  enforcement, and only a subset is enforceable without judgment. A student
  who tries to lint "is this rule correct?" has missed the point.
- **False-positive management.** The forbidden-Bash check must not flag a
  reference that legitimately *quotes* `find` as an example of what not to
  do. A strong spec addresses this (allowlist, or a marker convention).

### Common pitfalls

- **Over-reaching the linter** into semantic territory it cannot judge,
  reintroducing false confidence at the CI layer.
- **A prototype with no spec** -- unmaintainable by the next student -- or a
  spec so vague it cannot be implemented.
- **Ignoring false positives**, so the check would fail on legitimately
  quoted counter-examples and get disabled in practice.
- **Fixing L2 by deleting content** rather than restructuring via
  progressive disclosure (the framework's own prescribed remedy).

### Rubric (100 pts)

| Criterion | Pts | What full marks looks like |
|:----------|:----|:---------------------------|
| Gap inventory + checkable/judgment split (3.1) | 20 | Clear, correct boundary; only enforceable items taken in scope. |
| Check specification (3.2) | 30 | Four checks specified reimplementably; false positives handled. |
| Contradiction resolutions (3.3) | 25 | L2 + L3 concretely fixed to pass the student's own linter. |
| CI wiring + precedence (3.4) | 15 | Correct placement; F-20 relationship and blind spots stated. |
| Honest limitations note | 10 | Explicit "what this cannot check" -- no false confidence. |

---

## Exercise 4 -- domain-specialisation pipeline

### Intended approach

This is the flagship; a strong submission reads as a natural fifth member
of the framework's existing customisation family, not a bolt-on.

- **4.1** A `DOMAIN-SPECIALIZATION.md` design that faithfully mirrors
  `MULTI-LANGUAGE.md`'s structure: an explicit agnostic-core vs.
  domain-specific split, an adaptable-defaults table, and one fully worked
  override written into a project `AGENTS.md`. The transplant of the
  *language* pattern to the *domain* axis is the central idea; grade how
  cleanly it is carried over.
- **4.2** Three coherent, genuinely domain-specific artifacts. For OED /
  inverse problems, the correctness reference is the discriminating piece:
  a good one covers checks that *only* make sense in that domain
  -- adjoint-gradient verification via a Taylor-remainder convergence test,
  A-/D-optimality objective sanity checks, posterior-covariance /
  information-matrix structure tests, low-rank Hessian approximation error.
  A weak one just re-states generic MMS advice with the word "OED" pasted
  in. The literature seed and the pre-filled `PLAN.md` test-case scaffold
  should be specific enough to save a real project a day of setup.
- **4.3** A clear recommendation between the naming-convention loader
  (option A) and activating the dead `domain:` frontmatter field
  (option B), with trade-offs: A is simpler and needs no new mechanism but
  is manual; B makes `domain:` finally do something but requires a loader
  that reads frontmatter and a migration. A strong answer picks one and
  owns the cost.
- **4.4** A domain-onboarding workflow that reuses
  `project-onboarding`'s audit -> plan -> execute -> verify -> document arc,
  including where it writes the project's "Mathematical conventions" facts
  and how it records overrides, plus a `bin/specialize.sh` sketch and a
  ready-to-paste prompt in the framework's established style.
- **4.5** Explicit safeguards: the agnostic core stays intact for non-domain
  projects; projects can opt out or mix domains; and the *downward*
  injection path is added *without* severing the existing *upward*
  feedback roll-up. Critically, the student states how a domain pack is
  itself evidence-graded before shipping -- otherwise the domain axis becomes
  a new false-confidence generator, defeating the purpose.

### Key design decisions

- **Analogy is the method.** The framework already solved this shape once,
  for language. The best answers explicitly reason "language is to
  `MULTI-LANGUAGE.md` as domain is to `DOMAIN-SPECIALIZATION.md`" and reuse
  every transferable part.
- **Direction of knowledge flow.** The current framework only moves domain
  knowledge *up* (feedback). The new capability is *downward* injection;
  the design must add it without breaking the upward channel. Recognising
  this asymmetry is the deepest point of the exercise.
- **Evidence-grading the pack.** A domain pack is a large, confident-looking
  artifact -- exactly the kind the framework warns about. Gating it behind
  the evidence tiers is what keeps the solution honest.

### Common pitfalls

- **A domain pack that is generic advice with domain nouns sprinkled in.**
  The correctness reference in particular must contain checks that are
  *wrong or meaningless* outside the domain, or it has not specialised
  anything.
- **Building a plugin runtime / config engine** far beyond the framework's
  markdown-and-symlinks idiom.
- **Ignoring opt-out and mixing**, producing a design that helps
  single-domain projects and breaks everything else.
- **Shipping the pack with no evidence gate**, recreating the framework's
  core sin at a new layer.
- **Over-fitting to one worked domain (n=1 again)** without noting that the
  *mechanism* must be validated on a second, different domain before trust.

### Rubric (100 pts)

| Criterion | Pts | What full marks looks like |
|:----------|:----|:---------------------------|
| `DOMAIN-SPECIALIZATION.md` design (4.1) | 20 | Faithful, clean transplant of the language-axis pattern; core/specific split explicit. |
| Worked domain pack (4.2) | 30 | Three artifacts; the correctness reference contains genuinely domain-only checks. |
| Loader mechanism (4.3) | 15 | Reasoned A/B choice with owned trade-offs and migration cost. |
| Specialisation workflow (4.4) | 20 | Reuses onboarding arc; concrete prompt + `bin/specialize.sh` sketch. |
| Safeguards + evidence gate (4.5) | 10 | Opt-out/mixing preserved; upward channel intact; pack evidence-graded. |
| Idiomatic fit | 5 | Reads as a fifth member of the customisation family, not a bolt-on. |

---

## Exercise 5 -- literature-discovery skill

### Intended approach

The student demonstrates new-skill judgment: that a capability is missing,
that a *new* skill (not an extension) is the right vehicle, and that it
composes cleanly with what exists.

- **5.1** A rigorous gap argument. The strong version confirms from
  `literature-survey/SKILL.md` that the workflow presupposes a known paper
  list (Step 1 is "verified BibTeX entry," the input is "each paper the
  user provides") and then argues *discovery* is a genuinely different
  responsibility -- open-ended search and triage versus closed-set
  verification and note-taking. The per-skill justification (why not fold it
  into `literature-survey`, `research-paper-writing`, etc.) and the honest
  prior-art search are both present, per the `new-skill-proposal` template.
- **5.2** A discovery workflow with all the non-obvious pieces: query
  strategy across multiple sources, **both** snowballing directions
  (backward via references, forward via citations), de-duplication, triage
  with recorded reasons, and -- the discriminator between a strong and a
  weak answer -- an explicit **coverage / stopping criterion**. Beginners
  produce an open-ended "keep searching" loop; a strong answer defines when
  the search is done (e.g. new queries and snowball hops stop surfacing
  keep-worthy papers).
- **5.3** A precise hand-off contract. The best answers make the discovery
  skill's output *identical* to `literature-survey`'s expected input
  (candidate citekey + DOI/URL + one-line relevance), so the pair chains
  with no overlap and no gap, and show one worked candidate record crossing
  the seam. This "clean seam" is the single most important design idea in
  the exercise.
- **5.4** A ~50-line `SKILL.md` sketch that is actually loadable-looking:
  valid frontmatter with a *selection-worthy* description, a correct
  scientific-computing `domain:` value (not repeating L1's mis-tag),
  when-to-load, the workflow, the hand-off contract, and a
  progressive-disclosure `references/` plan. Skill-name rules from
  `AGENTS.md` Section 8 are obeyed.
- **5.5** An honest evidence assessment. The mature answer recognises that a
  brand-new top-level skill needs "3+ sessions / 2+ projects," concludes
  the proposal most likely enters *below threshold*, and routes it through
  the `append-evidence-to-skill-proposal` (F-19) mechanism -- rather than
  asserting the skill is ready. Designing the evidence-gathering path is the
  point; claiming premature readiness is the failure mode.
- **5.6** A sound ref-checker integration. The discriminating moves:
  (i) picking the `--refs-json` / `lookup` surfaces over the native
  `check PDF` path, because the workflow holds structured records, not a
  finished PDF, and those surfaces avoid the LLM-extraction step and its
  `OPENAI_API_KEY`; (ii) a concrete adapter from a candidate record or
  `.bib` entry into ref-checker's `Reference` shape (ref-checker does not
  read BibTeX); (iii) putting the gate at the discovery -> survey seam as
  the primary location, with `_collection_log.md`'s existing
  verification-status column as the natural home for the OK/CLOSEST/
  NO MATCH result, and the native `check draft.pdf` as an optional
  final-draft backstop; (iv) graceful degradation to manual verification
  when the tool/keys are absent -- ref-checker is *recommended, not
  required*, preserving the framework's zero-dependency portability;
  (v) a human-in-the-loop triage policy that never auto-rejects a CLOSEST.
  A weak answer wires the PDF+LLM path into a pre-draft loop, hard-depends
  on the tool, or treats NO MATCH as ground truth.
- **5.7** A critique that reads like the framework's own STATUS.md: it
  names the phase mismatch, the external-dependency-vs-portability tension
  (and that the framework has no external-tool-declaration mechanism), the
  LLM-catches-LLM circularity and how `--refs-json`/`lookup` sidesteps it,
  the speed/rate-limit cost, ref-checker's v0.1.0 maturity judged against
  the framework's *own* evidence bar, and the CS/physics/math coverage bias
  that threatens niche scientific-computing references. Full marks require
  the student to connect at least one of these back to a limitation the
  framework already diagnoses in itself (L5 n=1, L6 no-tool-mechanism, or
  the "false confidence" theme).

### Key design decisions

- **New skill vs. extension.** The defensible call is a *separate* skill:
  `literature-survey` is a clean single-responsibility unit, and adding
  open-ended discovery would overload it (and inflate it toward the L2
  length problem). Rewarding this judgment -- and a coherent argument for
  it -- matters more than the specific verdict.
- **Composition over a monolith.** Two small skills that chain via a
  specified contract beat one large skill that does both. This mirrors the
  framework's whole progressive-disclosure philosophy.
- **Reusing resource discipline.** Discovery is web- and PDF-heavy; the
  right design *cites* `agent-resource-discipline`'s web-fetch-caching and
  PDF-lifecycle references rather than re-specifying them.
- **Buy vs. build for verification.** The right call is to integrate the
  existing ref-checker rather than write a citation verifier; the value the
  student adds is the *glue* (adapter, gate placement, degradation policy),
  not a reimplementation of multi-source lookup.
- **Optional, not required.** Making ref-checker a hard dependency would
  break the framework's central portability promise ("any agent that reads
  markdown"). The defensible design keeps it a recommended enhancement with
  a manual fallback -- the same posture `agent-resource-discipline` already
  takes for tool-availability assumptions.

### Common pitfalls

- **Folding discovery into `literature-survey`** and calling it done --
  overloading a clean skill and dodging the new-skill judgment the exercise
  is about.
- **No stopping criterion**, so the workflow is an unbounded search with no
  definition of "enough" -- the most common weak answer.
- **A fuzzy hand-off**, where the discovery output does not match
  `literature-survey`'s input, so the two skills do not actually compose.
- **Claiming the skill clears the evidence bar** on the strength of one
  session -- the exact n=1 over-confidence (L5) the framework fights.
- **Re-specifying web-fetch / PDF handling** that `agent-resource-discipline`
  already provides (reinvention, M1).
- **Wiring ref-checker's PDF+LLM path into a pre-draft loop** -- forcing an
  `OPENAI_API_KEY` and an LLM extraction step the workflow does not need,
  and reintroducing the very hallucination risk being hunted, when
  `--refs-json`/`lookup` sidestep it.
- **Hard-depending on ref-checker** with no manual fallback, breaking
  portability.
- **Auto-rejecting on CLOSEST / treating NO MATCH as ground truth** --
  dropping real papers on a fuzzy title-similarity signal, a fresh instance
  of the false confidence the framework fights.
- **Calling ref-checker per-candidate in a tight loop** -- ignoring its
  sequential rate limits (~3-5 min / 60 refs); the right design batches.
- **A critique (5.7) that lists only ref-checker's bugs** and misses the
  structural issues (phase mismatch, dependency-vs-portability, no
  tool-declaration mechanism, maturity vs. the framework's own evidence bar).

### Rubric (100 pts)

| Criterion | Pts | What full marks looks like |
|:----------|:----|:---------------------------|
| Gap + new-skill justification (5.1) | 15 | Discovery-vs-survey distinction is sharp; all six per-skill justifications + prior-art search present. |
| Discovery workflow (5.2) | 15 | All steps, both snowball directions, and an explicit stopping criterion. |
| Hand-off contract + verification gate (5.3) | 20 | Output = `literature-survey` input; clean seam; one worked record; gate quarantines unverifiable candidates. |
| SKILL.md sketch (5.4) | 10 | Loadable-looking; valid frontmatter + correct `domain:`; naming rules obeyed; progressive disclosure. |
| Evidence assessment (5.5) | 10 | Honest below/above-threshold verdict; F-19 path designed. |
| ref-checker integration (5.6) | 20 | Right surface (`--refs-json`/`lookup`); adapter specified; gate placed; graceful degradation; triage-not-oracle policy. |
| Critique of the extension (5.7) | 10 | Names the structural issues, not just bugs; links at least one to a limitation the framework already admits. |

*(Weights rebalanced from the discovery-only version to make room for the
ref-checker integration; the total remains 100.)*

---

## Cross-exercise grading notes

- **Verification is the through-line.** Every exercise rewards the student
  who *confirms* a cited defect (and re-locates drifted line numbers)
  over one who trusts `EXERCISES.md`. This mirrors the framework's `F-17`
  self-invalidation discipline and is the single most important habit the
  course teaches.
- **Reuse beats reinvention.** Exercises 1, 3, and 4 each contain a trap
  where a student builds new machinery (a bug tracker, a quality regime, a
  plugin system) the framework already provides in simpler form. Dock
  reinvention; reward idiomatic extension.
- **Honest scoping is graded, not optional.** In line with `STATUS.md`,
  every deliverable's reflection must state what it does *not* cover and
  what evidence would earn trust. A confident submission with no such note
  should lose the "honest scoping" points even if technically strong.
- **The context budget is a real constraint.** Any fix that balloons a file
  past the framework's own ceilings (500 lines for `SKILL.md`, ~150-300 for
  references) is self-defeating and should be marked down, in every
  exercise where it applies.

---

*Created 2026-07-08. Maintained by the scicomp-research-skills course
staff. Companion exercises: [`EXERCISES.md`](EXERCISES.md).*
