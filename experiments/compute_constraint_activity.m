function act = compute_constraint_activity(res)
% How "hard" the controller is pushing constraints

u = res.U(:);
Ts = res.cfg.Ts;

umax = res.params.umax;
du_step_max = res.params.dumax * Ts;

du = [0; diff(u)];

act = struct();
act.frac_u_sat = mean(abs(u) >= 0.99*umax);           % saturation fraction
act.frac_du_sat = mean(abs(du) >= 0.99*du_step_max); % rate-limit fraction
act.u_maxabs = max(abs(u));
act.du_step_maxabs = max(abs(du));
end
