function b = find_theta0_boundary(cfg0, controller_type, theta_grid)
% Returns struct b with:
%  b.theta_stabilizable_max
%  b.theta_deployable_max  (stable AND p95<=budget)
%  b.records table-like struct array (for debugging)

cfg = cfg0;
cfg.controller.type = controller_type;

budget_ms = 1000*cfg.Ts;

b.theta_stabilizable_max = NaN;
b.theta_deployable_max   = NaN;

rec = struct([]);
k = 0;

for th0 = theta_grid
    cfg.x0 = [0;0;th0;0];

    res = run_experiment(cfg);

    % success definition (same as Phase 4-lite)
    ok_stable = isfinite(res.metrics.theta_settle_s) && (res.metrics.theta_settle_s <= 0.95*res.t(end)) ...
                && abs(res.X(end,3)) < 0.08;

    ok_constraints = (res.metrics.fallback_steps == 0);  % you can strengthen later if you want

    ok = ok_stable && ok_constraints;

    ok_rt = ok && (res.metrics.solve_p95_ms <= budget_ms);

    if ok
        b.theta_stabilizable_max = th0;
    end
    if ok_rt
        b.theta_deployable_max = th0;
    end

    k = k + 1;
    rec(k).theta0 = th0;
    rec(k).stable = ok;
    rec(k).deployable = ok_rt;
    rec(k).solve_p95_ms = res.metrics.solve_p95_ms;
    rec(k).theta_settle_s = res.metrics.theta_settle_s;
end

b.records = rec;
end
