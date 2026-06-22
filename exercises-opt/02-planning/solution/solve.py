"""Single-solve wrapper around UNO plus a finite-difference derivative check.

``solve_once`` builds the model for one (τ, K, x0), runs UNO, and returns a flat
result dict (objectives, KKT residuals, timing, selected assets, status).

``check_derivatives`` validates the analytic gradient, Jacobian and *Lagrangian
Hessian* against finite differences. The Hessian check is what catches a wrong
``set_lagrangian_sign_convention`` — it reconstructs the Lagrangian using the same
convention the callback assumes (L = σ₀·f − Σⱼ λⱼ·cⱼ).
"""
import time

import numpy as np
import unopy

import portfolio_model as pm

# Human-readable names for UNO's status enums (built from the constants so the
# mapping survives library updates).
OPT_STATUS = {
    int(getattr(unopy, k)): k
    for k in ["SUCCESS", "ITERATION_LIMIT", "TIME_LIMIT",
              "EVALUATION_ERROR", "ALGORITHMIC_ERROR"]
    if hasattr(unopy, k)
}
SOL_STATUS = {
    int(getattr(unopy, k)): k
    for k in ["NOT_OPTIMAL", "FEASIBLE_KKT_POINT", "FEASIBLE_FJ_POINT",
              "INFEASIBLE_STATIONARY_POINT", "FEASIBLE_SMALL_STEP",
              "INFEASIBLE_SMALL_STEP", "UNBOUNDED"]
    if hasattr(unopy, k)
}
# Solution statuses we accept as a usable local solution.
_FEASIBLE_SOL = {
    int(getattr(unopy, k))
    for k in ["FEASIBLE_KKT_POINT", "FEASIBLE_FJ_POINT", "FEASIBLE_SMALL_STEP"]
    if hasattr(unopy, k)
}

# set_option keys we *try* to use to quiet UNO's per-iteration logging; unknown
# keys are simply ignored.
_QUIET_OPTIONS = [("print_solution", "no"), ("logger", "SILENT"),
                  ("statistics_print_header_every_iterations", "0")]


def _make_solver(preset, exact_hessian, quiet):
    solver = unopy.UnoSolver()
    solver.set_preset(preset)
    if exact_hessian:
        try:
            solver.set_option("hessian_model", "exact")
        except Exception:
            pass
    if quiet:
        for key, val in _QUIET_OPTIONS:
            try:
                solver.set_option(key, val)
            except Exception:
                pass
    return solver


def solve_once(Sigma, mu, tau, K, x0, preset="filtersqp",
               exact_hessian=True, quiet=True):
    """Solve one portfolio instance. Returns a flat result dict."""
    n = len(mu)
    model = pm.build_model(Sigma, mu, tau, K, x0)
    solver = _make_solver(preset, exact_hessian, quiet)

    t0 = time.perf_counter()
    res = solver.optimize(model)
    solve_time = time.perf_counter() - t0

    w, z = pm.split(res.primal_solution, n)
    opt_code = int(res.optimization_status)
    sol_code = int(res.solution_status)
    ok = (opt_code == int(unopy.SUCCESS)) and (sol_code in _FEASIBLE_SOL)
    sel = pm.selected_assets(w)

    return {
        "tau": float(tau),
        "ok": ok,
        "optimization_status": OPT_STATUS.get(opt_code, str(opt_code)),
        "solution_status": SOL_STATUS.get(sol_code, str(sol_code)),
        "objective": float(res.solution_objective),
        "risk": pm.risk(Sigma, w),
        "return": pm.expected_return(mu, w),
        "mu_w": pm.mu_dot_w(mu, w),
        "kkt_stationarity": float(res.solution_stationarity),
        "kkt_feasibility": float(res.solution_primal_feasibility),
        "kkt_complementarity": float(res.solution_complementarity),
        "solve_time_s": float(solve_time),
        "n_iterations": int(res.number_iterations),
        "n_selected": len(sel),
        "selected_assets": sel,
        "w": w,
        "z": z,
        "x": np.concatenate([w, z]),
    }


# ---------------------------------------------------------------------------
# Derivative validation
# ---------------------------------------------------------------------------
def _fd_gradient(f, x, h=1e-6):
    g = np.zeros_like(x)
    for i in range(x.size):
        xp = x.copy(); xp[i] += h
        xm = x.copy(); xm[i] -= h
        g[i] = (f(xp) - f(xm)) / (2 * h)
    return g


def _dense_jacobian(cb, x):
    vals = np.zeros(cb["nnz_jac"])
    cb["jacobian"](x, vals)
    J = np.zeros((cb["m"], cb["nx"]))
    J[cb["jac_rows"], cb["jac_cols"]] = vals
    return J


def _constraint_vec(cb, x):
    c = np.zeros(cb["m"])
    cb["constraints"](x, c)
    return c


def check_derivatives(Sigma, mu, tau, K, seed=0, h=1e-6, tol=1e-4):
    """Finite-difference check of gradient, Jacobian and Lagrangian Hessian.

    Returns a dict of max absolute errors and raises ``AssertionError`` if any
    exceeds ``tol``.
    """
    cb = pm.make_callbacks(Sigma, mu, tau, K)
    n, nx, m = cb["n"], cb["nx"], cb["m"]
    rng = np.random.default_rng(seed)
    x = rng.random(nx)  # arbitrary point in [0,1]^{2n}

    # objective gradient
    g = np.zeros(nx)
    cb["objective_gradient"](x, g)
    g_fd = _fd_gradient(cb["objective"], x, h)
    err_grad = float(np.max(np.abs(g - g_fd)))

    # constraint Jacobian
    J = _dense_jacobian(cb, x)
    J_fd = np.zeros((m, nx))
    for i in range(nx):
        xp = x.copy(); xp[i] += h
        xm = x.copy(); xm[i] -= h
        J_fd[:, i] = (_constraint_vec(cb, xp) - _constraint_vec(cb, xm)) / (2 * h)
    err_jac = float(np.max(np.abs(J - J_fd)))

    # Lagrangian Hessian under L = σ₀·f − Σⱼ λⱼ·cⱼ
    obj_mult = float(rng.uniform(0.5, 1.5))
    mult = rng.standard_normal(m)

    def lag_grad(xx):
        gg = np.zeros(nx)
        cb["objective_gradient"](xx, gg)
        return obj_mult * gg - _dense_jacobian(cb, xx).T @ mult

    H_fd = np.zeros((nx, nx))
    for i in range(nx):
        xp = x.copy(); xp[i] += h
        xm = x.copy(); xm[i] -= h
        H_fd[:, i] = (lag_grad(xp) - lag_grad(xm)) / (2 * h)

    hv = np.zeros(cb["nnz_hess"])
    cb["hessian"](x, obj_mult, mult, hv)
    H = np.zeros((nx, nx))
    H[cb["hess_rows"], cb["hess_cols"]] = hv  # lower triangle
    H = H + H.T - np.diag(np.diag(H))         # mirror to full symmetric
    err_hess = float(np.max(np.abs(H - H_fd)))

    errors = {"gradient": err_grad, "jacobian": err_jac, "hessian": err_hess}
    worst = max(errors.values())
    assert worst <= tol, f"derivative check failed: {errors} (tol={tol})"
    return errors


if __name__ == "__main__":
    Sigma, mu, n, min_eig = pm.load_data()
    print(f"n = {n}, min eig(Sigma) = {min_eig:.4e}")

    print("\n[1] finite-difference derivative check ...")
    errs = check_derivatives(Sigma, mu, tau=0.5, K=8)
    print("    max abs errors:", {k: f"{v:.2e}" for k, v in errs.items()})

    print("\n[2] single solve at tau = 0.5 ...")
    rng = np.random.default_rng(0)
    x0 = np.concatenate([rng.dirichlet(np.ones(n)), rng.random(n)])
    r = solve_once(Sigma, mu, tau=0.5, K=8, x0=x0)
    print(f"    status            : {r['optimization_status']} / {r['solution_status']} (ok={r['ok']})")
    print(f"    objective         : {r['objective']:.6f}")
    print(f"    risk (wᵀΣw)       : {r['risk']:.6f}")
    print(f"    return (−μᵀw)     : {r['return']:.6f}")
    print(f"    KKT stationarity  : {r['kkt_stationarity']:.2e}")
    print(f"    iterations / time : {r['n_iterations']} / {r['solve_time_s']:.3f}s")
    print(f"    selected ({r['n_selected']}): {r['selected_assets']}")
