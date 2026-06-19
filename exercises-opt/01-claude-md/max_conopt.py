"""Mysterious optimization problem 1.

Uses a multistart strategy to escape local minima.
No plotting; the --plot flag is not implemented here.
"""
import argparse
import io
import numpy as np
import unopy

Inf = float("inf")


def neg_area(z, nv):
    n = nv - 1
    if n < 2:
        return 0.0
    x = z[:n-1]
    x1 = z[1:n]
    y = z[n:2*n-1]
    y1 = z[n+1:2*n]
    return float(-0.5 * np.sum(x1 * x * np.sin(y1 - y)))


def grad_neg_area(z, g, nv):
    n = nv - 1
    g[:] = 0.0
    if n < 2:
        return
    x = z[:n-1]
    x1 = z[1:n]
    y = z[n:2*n-1]
    y1 = z[n+1:2*n]
    s = np.sin(y1 - y)
    c = np.cos(y1 - y)
    g[:n-1] += -0.5 * x1 * s
    g[1:n] += -0.5 * x * s
    cross = x1 * x * c
    g[n:2*n-1] += 0.5 * cross
    g[n+1:2*n] += -0.5 * cross


def _build_dia_pairs(nv):
    return [(i, j) for i in range(nv) for j in range(i + 1, nv)]


def _build_sparsity(nv, dia):
    n = nv - 1
    Ma = n
    jr, jc = [], []
    for k in range(n - 1):
        jr += [k, k]
        jc += [n + k, n + k + 1]
    jr.append(n - 1)
    jc.append(2 * n - 1)
    for q, (i, j) in enumerate(dia):
        row = Ma + q
        if j < n:
            jr += [row, row, row, row]
            jc += [i, j, n + i, n + j]
        else:
            jr.append(row)
            jc.append(i)
    return jr, jc


def solve_one(z0, nv):
    n = nv - 1
    N = 2 * n
    lb = np.concatenate([np.zeros(n), np.zeros(n)])
    ub = np.concatenate([np.ones(n), np.full(n, np.pi)])
    dia = _build_dia_pairs(nv)
    Ma = n
    Md = len(dia)
    M = Ma + Md
    cl = np.concatenate([np.zeros(Ma), np.full(Md, -Inf)])
    cu = np.concatenate([np.full(Ma, Inf), np.ones(Md)])
    jr, jc = _build_sparsity(nv, dia)

    def con(z, out):
        v = z[n:]
        for k in range(n - 1):
            out[k] = v[k + 1] - v[k]
        out[n - 1] = np.pi - v[n - 1]
        uf = np.append(z[:n], 0.0)
        vf = np.append(z[n:], np.pi)
        for q, (i, j) in enumerate(dia):
            out[Ma + q] = uf[i]**2 + uf[j]**2 - 2*uf[i]*uf[j]*np.cos(vf[j] - vf[i])

    def jac(z, vals):
        idx = 0
        for k in range(n - 1):
            vals[idx] = -1.0
            vals[idx + 1] = 1.0
            idx += 2
        vals[idx] = -1.0
        idx += 1
        xf = np.append(z[:n], 0.0)
        yf = np.append(z[n:], np.pi)
        for i, j in dia:
            xi, xj = xf[i], xf[j]
            cv = np.cos(yf[j] - yf[i])
            sv = np.sin(yf[j] - yf[i])
            if j < n:
                vals[idx] = 2*xi - 2*xj*cv
                vals[idx + 1] = 2*xj - 2*xi*cv
                vals[idx + 2] = -2*xi*xj*sv
                vals[idx + 3] = 2*xi*xj*sv
                idx += 4
            else:
                vals[idx] = 2*xi
                idx += 1

    model = unopy.Model(unopy.PROBLEM_NONLINEAR, N, unopy.ZERO_BASED_INDEXING)
    model.set_variables_lower_bounds(lb)
    model.set_variables_upper_bounds(ub)
    model.set_objective(
        unopy.MINIMIZE,
        lambda z: neg_area(z, nv),
        lambda z, g: grad_neg_area(z, g, nv),
    )
    model.set_constraints(M, con, cl, cu, len(jr), jr, jc, jac)
    model.set_initial_primal_iterate(z0)

    solver = unopy.UnoSolver()
    solver.set_logger_stream(io.StringIO())
    solver.set_preset("filtersqp")
    solver.set_option("QP_solver", "BQPD")
    result = solver.optimize(model)

    ok = int(result.optimization_status) == unopy.SUCCESS
    area = -neg_area(result.primal_solution[:N], nv)
    return ok, area, result.primal_solution[:N]


def random_start(nv, rng):
    n = nv - 1
    x0 = rng.uniform(0.1, 0.9, n)
    y0 = np.sort(rng.uniform(0.05, np.pi - 0.05, n))
    return np.concatenate([x0, y0])


def multistart(nv, nstarts, seed):
    rng = np.random.default_rng(seed)
    best_area = -1.0
    best_z = None
    history = []
    for k in range(nstarts):
        z0 = random_start(nv, rng)
        ok, area, z = solve_one(z0, nv)
        if ok and area > best_area:
            best_area = area
            best_z = z.copy()
            tag = " (new best)"
        else:
            tag = ""
        print(f"restart {k + 1:3d}/{nstarts}: obj={area:.6f}{tag}", flush=True)
        history.append(best_area)
    return best_z, best_area, history


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nv", type=int, default=8)
    ap.add_argument("--nstarts", type=int, default=10)
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    best_z, best_area, history = multistart(args.nv, args.nstarts, args.seed)
    if best_z is None:
        print("No feasible solution found.")
        return
    n = args.nv - 1
    u = np.append(best_z[:n], 0.0)
    v = np.append(best_z[n:], np.pi)
    print(f"\nBest area: {best_area:.6f}")
    print(f"u: {np.round(u, 4)}")
    print(f"v: {np.round(v, 4)}")


if __name__ == "__main__":
    main()
