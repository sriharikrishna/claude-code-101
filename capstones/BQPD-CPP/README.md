# BQPD-Cpp - Create a threat-safe C++ version of Roger Fletchers robust QP solver

## Background

BQPD is a `fortran77` solver for quadratic programs of the form

$$ \min_x g^T x + \frac{1}{2} x^T G x, ~~ AL \leq A^T x \leq AU, xL \leq z \leq xU $$

where $g, xL, xU \in \R^n$ are constant vectorss, $A \in R^{n \times m}, G \in R^{n\times n}$ are matrices, and $AL, AU \in R^m$ are constant bound vectors.

The solver uses `common` blocks to pass information, which means it is **not threat-safe**. Despite the fact that it is written in `fortran77`, the solver uses *object-oriented-like* ideas to allow any combinations of dense/sparse matrix representation/factorization (see `sparseA.f` and `denseA.f` for example).

**References:**
* R. Fletcher. [Resolving degeneracy in quadratic programming](https://link.springer.com/article/10.1007/BF02023102). Ann Oper Res 46, 307–334 (1993).
* R. Fletcher. [Stable reduced Hessian updates for indefinite quadratic programming](https://link.springer.com/article/10.1007/s101070050113). Math. Program. 87, 251–264 (2000). 

## Goal

Develop a thread-safe `c++` implemenatation of `bqpd` and test it on the examples (`avgasa.s` and `avgasa.d`). As **stretch goal** consider addding BQPD-Cpp to [UNO, our unified nonlinear optimizer](https://github.com/cvanaret/Uno)

