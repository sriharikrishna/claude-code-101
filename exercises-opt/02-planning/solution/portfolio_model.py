"""unopy (UNO) formulation of the cardinality-constrained portfolio problem.

Continuous relaxation of the sparse mean-variance MINLP from ``nlp_seed.py``::

    min_{w,z}  wᵀΣw − τ·μᵀw                       (MINIMIZE)
    s.t.       1ᵀw         = 1                     c0   bounds [1, 1]
               1ᵀz        ≤ K                      c1   bounds [-inf, K]
               wᵀ(1 − z)  ≤ 0                      c2   bounds [-inf, 0]  (bilinear)
               w ∈ [0, 1],  z ∈ [0, 1]

Decision vector ``x ∈ R^{2n}`` with ``x[:n] = w`` and ``x[n:] = z``.

The constraint ``c2`` is bilinear, so the model is *nonconvex*: UNO returns a
local KKT point, not a global optimum (see ``benchmark.py`` / ``plan.md``).

Derivatives are analytic (the model is quadratic + bilinear):
  * ∇f       : grad_w = 2Σw − τμ,  grad_z = 0
  * Jacobian : c0 → ∂/∂wᵢ = 1; c1 → ∂/∂zᵢ = 1; c2 → ∂/∂wᵢ = 1−zᵢ, ∂/∂zᵢ = −wᵢ
  * Hessian of the Lagrangian, under UNO's ``MULTIPLIER_NEGATIVE`` convention
    (L = σ₀·f − Σⱼ λⱼ·cⱼ), only the objective and c2 contribute:
        w-block (i,j) = 2·σ₀·Σ[i,j]      (lower triangle)
        cross  (n+i,i) = +λ₂             (since ∂²c2/∂wᵢ∂zᵢ = −1)
"""
import numpy as np
import unopy

INF = float("inf")

# UNO's Lagrangian sign convention used throughout: L = σ₀·f − Σⱼ λⱼ·cⱼ
SIGN_CONVENTION = unopy.MULTIPLIER_NEGATIVE


def load_data():
    """Load problem data from ``nlp_seed.py``, symmetrize and PSD-validate Σ."""
    import nlp_seed as seed

    Sigma = 0.5 * (np.asarray(seed.Sigma, float) + np.asarray(seed.Sigma, float).T)
    mu = np.ascontiguousarray(seed.mu, float)
    n = int(seed.n)
    min_eig = float(np.linalg.eigvalsh(Sigma).min())
    if min_eig <= 0.0:
        raise ValueError(f"Sigma is not positive definite (min eig = {min_eig:.3e})")
    return Sigma, mu, n, min_eig


# ---------------------------------------------------------------------------
# Post-processing helpers (pure, no solver involved)
# ---------------------------------------------------------------------------
def split(x, n):
    """Split a decision vector into (w, z) numpy arrays."""
    x = np.asarray(x, float)
    return x[:n], x[n:]


def risk(Sigma, w):
    """Portfolio variance wᵀΣw."""
    w = np.asarray(w, float)
    return float(w @ Sigma @ w)


def expected_return(mu, w):
    """Return objective −μᵀw (a minimization objective)."""
    return float(-(np.asarray(mu, float) @ np.asarray(w, float)))


def mu_dot_w(mu, w):
    """Raw linear term μᵀw (logged alongside the two objectives)."""
    return float(np.asarray(mu, float) @ np.asarray(w, float))


def objective_value(Sigma, mu, tau, w):
    """Scalarized objective wᵀΣw − τ·μᵀw."""
    return risk(Sigma, w) - tau * mu_dot_w(mu, w)


def selected_assets(w, tol=1e-5):
    """Indices of assets with weight above ``tol``."""
    return [int(i) for i in np.where(np.asarray(w, float) > tol)[0]]


# ---------------------------------------------------------------------------
# Callbacks + sparse structure
# ---------------------------------------------------------------------------
def make_callbacks(Sigma, mu, tau, K):
    """Build the analytic callbacks and sparse COO index arrays for the model.

    Returned dict is consumed both by :func:`build_model` and by the
    finite-difference checker in ``solve.py``.
    """
    Sigma = np.ascontiguousarray(Sigma, float)
    mu = np.ascontiguousarray(mu, float)
    n = len(mu)
    nx = 2 * n
    m = 3

    # ---- objective ----
    def objective(x):
        w = np.asarray(x, float)[:n]
        return float(w @ Sigma @ w - tau * (mu @ w))

    def objective_gradient(x, g):
        w = np.asarray(x, float)[:n]
        g[:n] = 2.0 * (Sigma @ w) - tau * mu
        g[n:] = 0.0

    # ---- constraints ----
    cl = [1.0, -INF, -INF]
    cu = [1.0, float(K), 0.0]

    def constraints(x, c):
        x = np.asarray(x, float)
        w, z = x[:n], x[n:]
        c[0] = float(w.sum())
        c[1] = float(z.sum())
        c[2] = float(w @ (1.0 - z))

    # ---- Jacobian (COO, zero-based) ----
    # order: [c0 wrt w (n)] [c1 wrt z (n)] [c2: (∂wᵢ, ∂zᵢ) interleaved (2n)]
    jac_rows = ([0] * n) + ([1] * n)
    jac_cols = list(range(n)) + list(range(n, 2 * n))
    for i in range(n):
        jac_rows += [2, 2]
        jac_cols += [i, n + i]
    nnz_jac = len(jac_rows)

    def jacobian(x, vals):
        x = np.asarray(x, float)
        w, z = x[:n], x[n:]
        vals[:n] = 1.0           # c0 wrt w
        vals[n:2 * n] = 1.0      # c1 wrt z
        vals[2 * n::2] = 1.0 - z  # c2 wrt wᵢ
        vals[2 * n + 1::2] = -w   # c2 wrt zᵢ

    # ---- Lagrangian Hessian (lower triangle, COO) ----
    # block 1: dense lower triangle of the w-block (row-major, j <= i)
    tri_i, tri_j = np.tril_indices(n)
    sigma_tri = Sigma[tri_i, tri_j]
    n_tri = tri_i.size
    hess_rows = list(tri_i) + [n + i for i in range(n)]
    hess_cols = list(tri_j) + [i for i in range(n)]
    nnz_hess = len(hess_rows)

    def lagrangian_hessian(x, objective_multiplier, multipliers, hv):
        # L = σ₀·f − Σⱼ λⱼ·cⱼ  (MULTIPLIER_NEGATIVE)
        hv[:n_tri] = 2.0 * objective_multiplier * sigma_tri          # w-block: 2σ₀Σ
        hv[n_tri:] = multipliers[2]                                  # cross: −λ₂·(−1) = +λ₂

    return {
        "n": n, "m": m, "nx": nx,
        "objective": objective, "objective_gradient": objective_gradient,
        "constraints": constraints, "cl": cl, "cu": cu,
        "jacobian": jacobian, "jac_rows": jac_rows, "jac_cols": jac_cols, "nnz_jac": nnz_jac,
        "hessian": lagrangian_hessian, "hess_rows": hess_rows, "hess_cols": hess_cols,
        "nnz_hess": nnz_hess,
    }


def build_model(Sigma, mu, tau, K, x0):
    """Assemble a ready-to-solve :class:`unopy.Model` for given (τ, K, x0)."""
    cb = make_callbacks(Sigma, mu, tau, K)
    model = unopy.Model(unopy.PROBLEM_NONLINEAR, cb["nx"], unopy.ZERO_BASED_INDEXING)
    model.set_variables_lower_bounds([0.0] * cb["nx"])
    model.set_variables_upper_bounds([1.0] * cb["nx"])
    model.set_objective(unopy.MINIMIZE, cb["objective"], cb["objective_gradient"])
    model.set_constraints(
        cb["m"], cb["constraints"], cb["cl"], cb["cu"],
        cb["nnz_jac"], cb["jac_rows"], cb["jac_cols"], cb["jacobian"],
    )
    model.set_lagrangian_hessian(
        cb["nnz_hess"], unopy.LOWER_TRIANGLE,
        cb["hess_rows"], cb["hess_cols"], cb["hessian"],
    )
    model.set_lagrangian_sign_convention(SIGN_CONVENTION)
    model.set_initial_primal_iterate([float(v) for v in x0])
    return model
