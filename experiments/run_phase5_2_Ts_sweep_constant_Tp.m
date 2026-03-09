function out = run_phase5_2_Ts_sweep_constant_Tp()
%  Sweep Ts while keeping prediction time Tp constant.
% Outputs:
%  figures/F12_p95_vs_Ts.png
%  figures/F13_theta0_stable_vs_Ts.png
%  figures/F13b_theta0_deployable_vs_Ts.png
%  figures/F14_Jcl_vs_Ts.png
%  paper/tables/T04_Ts_sweep_constantTp.tex

root = setup_paths();
figDir = fullfile(root,'figures');
%  "figures/  ->  fullfile(figDir, "
%   .png"   ->  .png")
% exportgraphics(gcf, fullfile(figDir, "F07_success_vs_theta0.png"), 'Resolution', 250);
% exportgraphics(gcf, fullfile(figDir, "F11_Jcl_vs_Np.png"), 'Resolution', 250);
 
cfg0 = default_config();

Ts_list = [0.01 0.015 0.02 0.04 0.06];

Tp = 0.40;        % constant prediction horizon time [s]
Tsim = 4.0;       % constant simulation time window [s]

% Boundary grid over theta0
theta_grid = 0.02:0.02:0.30;

controllers = ["linear_mpc","casadi_nmpc"];
labels = ["LMPC","CasADi NMPC"];

% Baseline IC (moderate perturbation)
x0_baseline = [0;0;0.12;0];

% Ensure output folders
if ~exist("figures","dir"), mkdir("figures"); end
if ~exist(fullfile("paper","tables"),"dir"), mkdir(fullfile("paper","tables")); end

rows = [];
r = 0;

for Ts = Ts_list
    Np = max(5, round(Tp / Ts));           % guard against too small horizon
    N_steps = max(50, round(Tsim / Ts));   % guard against too short sim

    for c = 1:numel(controllers)
        cfg = cfg0;
        cfg.Ts = Ts;
        cfg.Np = Np;
        cfg.N_steps = N_steps;
        cfg.controller.type = controllers(c);
        cfg.x0 = x0_baseline;

        % baseline run
        res = run_experiment(cfg);

        % closed-loop cost
        Jcl = compute_closedloop_cost(res);

        % boundary run (use same physical sim time)
        cfgB = cfg;
        bnd = find_theta0_boundary_fast(cfgB, controllers(c), theta_grid);

        r = r + 1;
        rows(r).controller = char(labels(c));
        rows(r).Ts = Ts;
        rows(r).Np = Np;
        rows(r).Tp = Np*Ts;

        rows(r).solve_p95_ms = res.metrics.solve_p95_ms;
        rows(r).solve_max_ms = res.metrics.solve_max_ms;

        rows(r).theta_rms = res.metrics.theta_rms;
        rows(r).theta_settle_s = res.metrics.theta_settle_s;

        rows(r).Jcl = Jcl;

        rows(r).theta0_stab_max = bnd.theta_stab_max;
        rows(r).theta0_rt_max   = bnd.theta_rt_max;
    end
end

T = struct2table(rows);
out.table = T;

% ---------- Plots ----------
% F12: p95 solve time vs Ts
figure('Color','w'); hold on; grid on;
for c = 1:numel(labels)
    mask = strcmp(T.controller, labels(c));
    plot(T.Ts(mask), T.solve_p95_ms(mask), '-o', 'LineWidth', 1.2);
end
% budget is Ts*1000 in ms (varies with Ts), so plot budget line as function
ts_sorted = sort(unique(T.Ts));
plot(ts_sorted, 1000*ts_sorted, '--', 'LineWidth', 1.2); % budget = Ts
xlabel('T_s [s]'); ylabel('p95 solve time [ms]');
title(sprintf(' Real-time feasibility vs sampling time (T_p \\approx %.2fs)', Tp)); 

legend([labels, "budget (=T_s)"], 'Location','best');
set(gca,'XScale','log');
exportgraphics(gcf,  fullfile(figDir, "F12_p95_vs_Ts.png"), 'Resolution', 250);

% F13: stabilizable boundary vs Ts
figure('Color','w'); hold on; grid on;
for c = 1:numel(labels)
    mask = strcmp(T.controller, labels(c));
    plot(T.Ts(mask), T.theta0_stab_max(mask), '-o', 'LineWidth', 1.2);
end
xlabel('T_s [s]'); ylabel('\theta_{0,max} (stabilizable) [rad]');
title(sprintf(' Stabilizable boundary vs sampling time (T_p \\approx %.2fs)', Tp));
legend(labels,'Location','best');
set(gca,'XScale','log');
exportgraphics(gcf,  fullfile(figDir, "F13_theta0_stable_vs_Ts.png"), 'Resolution', 250);

% F13b: deployable boundary vs Ts
figure('Color','w'); hold on; grid on;
for c = 1:numel(labels)
    mask = strcmp(T.controller, labels(c));
    plot(T.Ts(mask), T.theta0_rt_max(mask), '-o', 'LineWidth', 1.2);
end
xlabel('T_s [s]'); ylabel('\theta_{0,\max}^{rt} [rad]');
title(sprintf(' Deployable boundary vs sampling time (p95\\le budget, T_p \\approx %.2fs)', Tp));
legend(labels,'Location','best');
set(gca,'XScale','log');
exportgraphics(gcf,  fullfile(figDir, "F13b_theta0_deployable_vs_Ts.png"), 'Resolution', 250);

% F14: Jcl vs Ts
figure('Color','w'); hold on; grid on;
for c = 1:numel(labels)
    mask = strcmp(T.controller, labels(c));
    plot(T.Ts(mask), T.Jcl(mask), '-o', 'LineWidth', 1.2);
end
xlabel('T_s [s]'); ylabel('J_{cl}');
title(sprintf(' Closed-loop cost vs sampling time (T_p \\approx %.2fs)', Tp));
legend(labels,'Location','best');
set(gca,'XScale','log');
exportgraphics(gcf,  fullfile(figDir, "F14_Jcl_vs_Ts.png"), 'Resolution', 250);

% ---------- LaTeX Table ----------
export_table_Ts(T, fullfile("paper","tables","T04_Ts_sweep_constantTp.tex"));

disp("Phase 5.2 outputs:");
disp(" - figures/F12_p95_vs_Ts.png");
disp(" - figures/F13_theta0_stable_vs_Ts.png");
disp(" - figures/F13b_theta0_deployable_vs_Ts.png");
disp(" - figures/F14_Jcl_vs_Ts.png");
disp(" - paper/tables/T04_Ts_sweep_constantTp.tex");

end

function export_table_Ts(T, out_tex_path)
fid = fopen(out_tex_path,'w');
assert(fid>0, "Could not open %s", out_tex_path);

fprintf(fid, "%% Auto-generated by run_phase5_2_Ts_sweep_constant_Tp.m\n");
fprintf(fid, "\\begin{table}[t]\\centering\n");
fprintf(fid, "\\caption{ sampling-time sweep with approximately constant prediction time $T_p=N_pT_s$.}\\label{tab:tssweep}\n");
fprintf(fid, "\\begin{tabular}{lcccccccc}\\toprule\n");
fprintf(fid, "Controller & $T_s$ [s] & $N_p$ & $T_p$ [s] & p95 [ms] & max [ms] & $\\theta_{0,\\max}^{stab}$ & $\\theta_{0,\\max}^{rt}$ & $J_{cl}$\\\\\\midrule\n");

for i=1:height(T)
    fprintf(fid, "%s & %.3f & %d & %.3f & %.2f & %.2f & %.2f & %.2f & %.3g\\\\\n", ...
        T.controller{i}, T.Ts(i), T.Np(i), T.Tp(i), ...
        T.solve_p95_ms(i), T.solve_max_ms(i), ...
        T.theta0_stab_max(i), T.theta0_rt_max(i), ...
        T.Jcl(i));
end

fprintf(fid, "\\bottomrule\\end{tabular}\\end{table}\n");
fclose(fid);
end
