function cls = classify_run_phase7(res, cfg, rt_budget_ms)

X = res.X;
p     = X(1,:);
theta = X(3,:);

tol = 1e-4;

pmax = res.params.ctrl.pmax;
track_ok = all(abs(p) <= pmax + tol);

env_ok   = all(abs(theta) <= res.params.ctrl.thetamax + tol);

% use your computed settling time or final error
final_ok = abs(theta(end)) < deg2rad(2);

is_stabilized = track_ok && env_ok && final_ok;

p95_ms = res.metrics.solve_p95_ms;
is_deployable = is_stabilized && (p95_ms <= rt_budget_ms);

cls.is_stabilized = is_stabilized;
cls.is_deployable = is_deployable;
end
