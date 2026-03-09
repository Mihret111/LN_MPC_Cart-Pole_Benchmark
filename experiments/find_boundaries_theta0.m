function out = find_boundaries_theta0(cfg, theta_grid, rt_budget_ms)

best_stab = NaN; best_rt = NaN;
best_res_stab = struct([]);
best_res_rt   = struct([]);
first_fail_after_rt = struct([]);


for th = theta_grid
    cfg_i = cfg;
    cfg_i.x0 = [0;0;th;0];

    res = run_experiment(cfg_i);

    cls = classify_run_phase7(res, cfg_i, rt_budget_ms);

    if cls.is_stabilized
        best_stab = th;
        best_res_stab = res;
    end
    if cls.is_deployable
        best_rt = th;
        best_res_rt = res;
    elseif ~isnan(best_rt) && isempty(first_fail_after_rt)
        % first failure right above deployable boundary
        first_fail_after_rt = res;
    end
end
disp(fieldnames(best_res_rt))

% headline: use deployable boundary if exists else stabilizable
if ~isnan(best_rt)
    m = best_res_rt.metrics;
    out.theta0_max_stab = best_stab;
    out.theta0_max_rt   = best_rt;
    out.p95_ms = m.solve_p95_ms;
    % out.Jcl    = m.Jcl;
    out.Jcl = compute_closedloop_cost(best_res_rt);
    out.label  = "OK_or_RTboundary";
    out.rep_res_ok = best_res_rt;
    out.rep_res_fail = first_fail_after_rt;
else
    m = best_res_stab.metrics;
    out.theta0_max_stab = best_stab;
    out.theta0_max_rt   = NaN;
    out.p95_ms = m.solve_p95_ms;
    % out.Jcl    = m.Jcl;
    out.Jcl = compute_closedloop_cost(best_res_stab);   % or best_res_stab
    out.label  = "NO_DEPLOYABLE";
    out.rep_res_ok = best_res_stab;
    out.rep_res_fail = [];
end
end
