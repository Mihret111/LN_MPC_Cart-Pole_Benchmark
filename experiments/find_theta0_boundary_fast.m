function b = find_theta0_boundary_fast(cfg_base, controller_type, theta_grid)
% b.theta_stab_max: largest theta0 that stabilizes
% b.theta_rt_max: largest theta0 that stabilizes and meets RT (p95 <= budget)

cfg = cfg_base;
cfg.controller.type = controller_type;

budget_ms = 1000*cfg.Ts;

b.theta_stab_max = NaN;
b.theta_rt_max   = NaN;

for th0 = theta_grid
    cfg.x0 = [0;0;th0;0];
    res = run_experiment(cfg);

    % "stable enough" criterion (consistent with Phase 4-lite)
    ok_stable = isfinite(res.metrics.theta_settle_s) && (res.metrics.theta_settle_s <= 0.95*res.t(end)) ...
                && abs(res.X(end,3)) < 0.08;

    ok_constraints = (res.metrics.fallback_steps == 0);

    ok = ok_stable && ok_constraints;
    ok_rt = ok && (res.metrics.solve_p95_ms <= budget_ms);

    if ok
        b.theta_stab_max = th0;
    end
    if ok_rt
        b.theta_rt_max = th0;
    end
end
end
