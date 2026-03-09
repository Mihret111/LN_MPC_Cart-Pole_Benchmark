function M = run_budget_map_casadi()
cfg0 = default_config();
cfg0.Ts = 0.02;
cfg0.controller.type = "casadi_nmpc";

theta0_list = [0.05 0.10 0.15 0.20 0.25];
Np_list = [10 15 20 30 40];

p95 = nan(numel(theta0_list), numel(Np_list));
settle = nan(size(p95));

for i=1:numel(theta0_list)
    th0 = theta0_list(i);
    x0 = [0;0;th0;0];

    for j=1:numel(Np_list)
        cfg = cfg0;
        cfg.Np = Np_list(j);
        cfg = set_init_state(cfg, x0);

        res = run_experiment(cfg);

        p95(i,j) = res.metrics.solve_p95_ms;
        settle(i,j) = res.metrics.theta_settle_s;
    end
end

% Heatmap: p95 solve time
figure('Color','w');
imagesc(Np_list, theta0_list, p95);
set(gca,'YDir','normal');
colorbar;
hold on;
contour(Np_list, theta0_list, p95, [20 20], 'LineWidth', 1.6); % 20ms contour
xlabel('N_p'); ylabel('\theta_0 [rad]');
title('CasADi NMPC: p95 solve time [ms] (contour = 20 ms budget)');

M.theta0_list = theta0_list;
M.Np_list = Np_list;
M.p95_ms = p95;
M.settle_s = settle;
end
