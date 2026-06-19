# max_conopt.py

Mysterious optimization problem 1. 

The problem has many local minima. A multistart strategy is used to
improve the chance of finding a good solution.

## Variables

The optimization variable is z of length 2*(nv-1), split into two blocks:

- x: first nv-1 entries of z
- y: last nv-1 entries of z

The last (x,y) pair is fixed and not part of z.

## Usage

    python max_conopt.py [--nv N] [--nstarts K] [--seed S]

Defaults: nv=8, nstarts=10, seed=0.

## Output

Prints one line per restart showing objective value and a flag for
improvements. On completion prints the best objective found and the
corresponding x and y arrays (including the fixed pair appended).
