function cls = classify_run_success_v2(res)
% 0 fail, 1 stable but not RT, 2 stable+RT

cfg = res.cfg;
params = res.params;
m = res.metrics;

budget_ms = 1000*cfg.Ts;

% --- Constraint satisfaction (use metrics, no guessing about u_prev) ---
dumax_step = params.dumax * cfg.Ts;

constraints_ok = ...
    (m.u_maxabs <= params.umax + 1e-6) && ...
    (m.du_step_maxabs <= dumax_step + 1e-6) && ...
    (m.p_maxabs <= params.pmax + 1e-6) && ...
    (m.theta_maxabs <= params.thetamax + 1e-6);

% --- Stabilization criteria (define these in your paper!) ---
% We call it stabilized if settling time exists and is not crazy.
Tend = res.t(end);
stable = isfinite(m.theta_settle_s) && (m.theta_settle_s <= 0.9*Tend);

% Optional extra: require small final error (not too strict)
theta_final = abs(res.X(end,3));
p_final = abs(res.X(end,1));
stable = stable && (theta_final < 0.05) && (p_final < 0.20);  % 0.05 rad ≈ 2.9°

% --- Real-time deployability criterion ---
deployable = (m.solve_p95_ms <= budget_ms);

cls = struct();
cls.budget_ms = budget_ms;
cls.solve_p95_ms = m.solve_p95_ms;
cls.constraints_ok = constraints_ok;
cls.stable = stable;
cls.deployable = deployable;

if ~constraints_ok
    cls.code = 0; cls.reason = "constraint_violation";
elseif ~stable
    cls.code = 0; cls.reason = "not_stabilized";
elseif stable && ~deployable
    cls.code = 1; cls.reason = "stable_but_budget_miss";
else
    cls.code = 2; cls.reason = "stable_and_deployable";
end
end
