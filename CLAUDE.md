# Repository conventions — claude-code-101

## Git workflow: always use a feature branch

**Never commit or push directly to `main`.** For every change:

1. Branch off up-to-date `main`:
   ```bash
   git fetch origin
   git checkout -b <descriptive-branch> origin/main
   ```
   Use a short, descriptive name, optionally prefixed by type — e.g.
   `docs/…`, `fix/…`, `feat/…`, `chore/…`.
2. Commit your work on that branch and push it:
   ```bash
   git push -u origin <descriptive-branch>
   ```
3. Open a pull request for review — do not merge to `main` without one:
   ```bash
   gh pr create --fill
   ```
4. Merge only via the PR once reviewed.

This applies to everything, including edits to the slides (`slides.html`,
`slides-supplemental/`), docs, and exercises.
