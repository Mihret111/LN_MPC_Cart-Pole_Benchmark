function m = compute_metrics(res)
%COMPUTE_METRICS Compute standard performance + timing metrics.

t = res.t;
X = res.X;
U = res.U;
solveT = res.solveT;

theta = X(3,:);
p = X(1,:);

m = struct();

% Tracking / regulation quality
m.theta_maxabs = max(abs(theta));
m.theta_rms = sqrt(mean(theta.^2));

m.p_maxabs = max(abs(p));
m.p_rms = sqrt(mean(p.^2));

% Control effort
m.u_maxabs = max(abs(U));
m.u_rms = sqrt(mean(U.^2));
% m.du_maxabs = max(abs(diff([0 U]))); % simple approx
%
du = diff([res.U(1) res.U]);  % per-step delta, same unit as u
m.du_step_maxabs = max(abs(du));
m.du_rate_maxabs = max(abs(du)) / res.cfg.Ts;  % N/s (optional)


% Timing
m.fallback_steps = sum(res.fallback);
m.N_steps = numel(U);
m.solve_avg_ms = 1e3*mean(solveT);
m.solve_p95_ms = 1e3*prctile(solveT,95);
m.solve_max_ms = 1e3*max(solveT);

% Settling time for theta into band (example: ±0.01 rad)
% became NAN. So this was later changed to have theta settle at least for 1
% sec
% band = 0.01;
% idx = find(abs(theta) <= band, 1, 'first');
% if isempty(idx)
%     m.theta_settle_s = NaN;
% else
%     % stricter: must stay within band for the rest of simulation
%     ok = all(abs(theta(idx:end)) <= band);
%     if ok
%         m.theta_settle_s = t(idx);
%     else
%         m.theta_settle_s = NaN;
%     end
% end

band = 0.01;        % rad
Thold = 1.0;        % must stay in band for last 1 second
Ts = res.cfg.Ts;

Nh = round(Thold/Ts);
theta = res.X(3,:);

m.theta_settle_s = NaN;
for i = 1:(numel(theta)-Nh)
    if all(abs(theta(i:i+Nh)) <= band)
        m.theta_settle_s = res.t(i);
        break;
    end
end

end
