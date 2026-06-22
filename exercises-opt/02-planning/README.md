# Exercise 2 — Plan a small NLP (15 min)

**Goal.** Use plan mode to lay out the structure of a small NLP project before any code is written.

## The problem

Sparse mean-variance portfolio selection with cardinality constraint,
modeled as complementarity $w^\top (\mathbf{1} - z) \le 0$.

$$
\begin{aligned}
\min_{w, z} \quad & w^\top \Sigma w - \tau \mu^\top w \\
\text{s.t.} \quad & \mathbf{1}^\top w = 1 \\
& \mathbf{1}^\top z \le K \\
& w^\top (\mathbf{1} - z) \le 0 \\
& w \ge 0 \\
& z \in [0, 1]^n
\end{aligned}
$$

with $n = 50$ assets and cardinality $K = 8$. Data is in `nlp_seed.py`.

## Steps

1. `cd exercises/02-planning && claude`
2. Press `Shift+Tab` twice to enter plan mode (look for the `plan mode` indicator at the bottom of the screen).
3. Ask:

   ```
   plan a Python/unopy formulation for the cardinality-constrained portfolio
   problem in nlp_seed.py, plus a strategy for exploring the Pareto
   front with UNO for different \tau. Include a benchmarking harness 
   that records 'tau', the two objectives (risk: 'mu^\top w', and return: 
   '-mu^\top w'), solve time, optimality gap, and selected assets 
   to a CSV. Plot the trade-off between risk ('w^\top \Sigma w') and
   return ('-\mu^\top w') for different values of '\tau'.
   ```

4. Read the plan critically. Don't approve it yet. Look for:

   - Does it specify how `Sigma` is loaded (and validated to be PSD)?
   - Does it parameterize `tau` and `K`, or hardcode them?
   - Does it allow different parameterizations of 'tau'
   - Where will it write the CSV? Is the path configurable?
   - Does it describe how to select UNO's solvers?

5. Save the plan: ask Claude to write it to `plan.md`. Discuss with your neighbor: 
   - What one assumption would you have made wrong without the plan?
   - Does the plan provide a reasonable strategy for the plot?

## Discussion prompts

- Compare with how you'd write pseudocode before implementing this method.
- What types of mistake does the plan catch *before* compute time is spent?

## Stretch

Re-ask the same prompt but add: `our benchmarking harness must follow the conventions in CLAUDE.md` 
(write a short CLAUDE.md first specifying figure size, log format, and CSV layout). Compare the two plans.
