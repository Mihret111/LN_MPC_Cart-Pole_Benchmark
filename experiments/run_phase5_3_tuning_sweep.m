function out = run_phase5_3_tuning_sweep()
%  tuning sweep (Q/R scaling) for LMPC vs CasADi NMPC
% Outputs:
%   figures/F15_pareto_thetaRMS_uRMS.png
%   figures/F16_constraint_activity.png
%   figures/F17_p95_vs_tuning.png
%   figures/F18_theta0_boundary_vs_tuning.png   (optional but recommended)
%   paper/tables/T05_tuning_sweep.tex
root = setup_paths();
figDir = fullfile(root,'figures');
%  fullfile(figDir, "  ->  fullfile(figDir, "
%   .png"   ->  .png")
% exportgraphics(gcf, fullfile(figDir, "F07_success_vs_theta0.png"), 'Resolution', 250);
% exportgraphics(gcf, fullfile(figDir, "F11_Jcl_vs_Np.png"), 'Resolution', 250);
% exportgraphics(gcf, fullfile(figDir, "F15_pareto_thetaRMS_uRMS.png"), 'Resolution', 250);

cfg0 = default_config();
cfg0.Ts = 0.02;
cfg0.Np = 20;
cfg0.N_steps = 200;                 % 4 seconds
cfg0.x0 = [0;0;0.12;0];

Q0 = cfg0.Q;
R0 = cfg0.R;



% Tuning regimes: [alpha beta]
regimes = struct( ...
    'name',  {"Aggressive","Balanced","Smooth"}, ...
    'alpha', {3.0,         1.0,       0.5}, ...
    'beta',  {0.3,         1.0,       3.0} ...
);

controllers = ["linear_mpc","casadi_nmpc"];
labels      = ["LMPC","CasADi NMPC"];

% Optional: boundary sweep (coarse)
do_boundary = true;
theta_grid = 0.02:0.02:0.30;

% Output dirs
if ~exist("figures","dir"), mkdir("figures"); end
if ~exist(fullfile("paper","tables"),"dir"), mkdir(fullfile("paper","tables")); end

rows = [];
r = 0;

for c = 1:numel(controllers)
    for i = 1:numel(regimes)

        cfg = cfg0;

        % Apply tuning
        cfg.Q = regimes(i).alpha * Q0;
        cfg.R = regimes(i).beta  * R0;

        cfg.controller.type = controllers(c);

        % --- run baseline ---
        res = run_experiment(cfg);

        % closed-loop cost
        Jcl = compute_closedloop_cost(res);

        % constraint activity
        act = compute_constraint_activity(res);

        % optional boundaries
        theta_stab = NaN; theta_rt = NaN;
        if do_boundary
            bnd = find_theta0_boundary_fast(cfg, controllers(c), theta_grid);
            theta_stab = bnd.theta_stab_max;
            theta_rt   = bnd.theta_rt_max;
        end

        r = r + 1;
        rows(r).controller = char(labels(c));
        rows(r).tuning = regimes(i).name;
        rows(r).alpha = regimes(i).alpha;
        rows(r).beta  = regimes(i).beta;

        % performance
        rows(r).theta_rms = res.metrics.theta_rms;
        rows(r).theta_settle_s = res.metrics.theta_settle_s;
        rows(r).p_rms = res.metrics.p_rms;

        % effort
        rows(r).u_rms = res.metrics.u_rms;
        rows(r).u_maxabs = res.metrics.u_maxabs;

        % timing
        rows(r).solve_p95_ms = res.metrics.solve_p95_ms;
        rows(r).solve_max_ms = res.metrics.solve_max_ms;

        % costs & constraint activity
        rows(r).Jcl = Jcl;
        rows(r).frac_u_sat = act.frac_u_sat;
        rows(r).frac_du_sat = act.frac_du_sat;

        % boundaries (if enabled)
        rows(r).theta0_stab_max = theta_stab;
        rows(r).theta0_rt_max   = theta_rt;
    end
end

T = struct2table(rows);
out.table = T;

% ------------------- FIGURES -------------------

% F15: Pareto scatter theta_rms vs u_rms
figure('Color','w'); hold on; grid on;
mk = ["o","s"]; % markers per controller
for c = 1:numel(labels)
    mask = strcmp(T.controller, labels(c));
    sub = T(mask,:);
    scatter(sub.u_rms, sub.theta_rms, 60, mk(c), 'filled');
    % annotate tuning
    for k = 1:height(sub)
        text(sub.u_rms(k)*1.01, sub.theta_rms(k), sub.tuning{k}, 'FontSize', 9);
    end
end
xlabel('u_{rms} [N]'); ylabel('\theta_{rms} [rad]');
title(' Pareto trade-off (performance vs effort)');
legend(labels,'Location','best');
exportgraphics(gcf, fullfile(figDir, "F15_pareto_thetaRMS_uRMS.png"), 'Resolution', 250);

% F16: Constraint activity (stacked-ish via grouped bars)
figure('Color','w'); hold on; grid on;
cats = strcat(T.controller, " | ", T.tuning);
bar(categorical(cats), [T.frac_u_sat, T.frac_du_sat]);
ylabel('fraction of steps');
title(' Constraint activity (saturation and rate limiting)');
legend({'u saturation','\Delta u saturation'},'Location','best');
xtickangle(30);
exportgraphics(gcf, fullfile(figDir, "F16_constraint_activity.png"), 'Resolution', 250);

% F17: p95 solve time by tuning
figure('Color','w'); hold on; grid on;
bar(categorical(cats), T.solve_p95_ms);
yline(20,'--','20 ms budget');
ylabel('p95 solve time [ms]');
title(' Real-time feasibility vs tuning');
xtickangle(30);
exportgraphics(gcf, fullfile(figDir, "F17_p95_vs_tuning.png"), 'Resolution', 250);

% F18: boundaries vs tuning (if enabled)
if do_boundary
    figure('Color','w'); hold on; grid on;
    bar(categorical(cats), [T.theta0_stab_max, T.theta0_rt_max]);
    ylabel('\theta_{0,max} [rad]');
    title(' Stabilizable vs deployable boundary vs tuning');
    legend({'\theta_{0,max}^{stab}','\theta_{0,max}^{rt}'},'Location','best');
    xtickangle(30);
    exportgraphics(gcf, fullfile(figDir, "F18_theta0_boundary_vs_tuning.png"), 'Resolution', 250);
end

% ------------------- LaTeX table export -------------------
export_table_tuning(T, fullfile("paper","tables","T05_tuning_sweep.tex"));

disp("Phase 5.3 outputs:");
disp(" - figures/F15_pareto_thetaRMS_uRMS.png");
disp(" - figures/F16_constraint_activity.png");
disp(" - figures/F17_p95_vs_tuning.png");
if do_boundary
    disp(" - figures/F18_theta0_boundary_vs_tuning.png");
end
disp(" - paper/tables/T05_tuning_sweep.tex");

end

function export_table_tuning(T, out_tex_path)
fid = fopen(out_tex_path,'w');
assert(fid>0, "Could not open %s", out_tex_path);

fprintf(fid, "%% Auto-generated by run_phase5_3_tuning_sweep.m\n");
fprintf(fid, "\\begin{table}[t]\\centering\n");
fprintf(fid, "\\caption{ tuning regimes via $(\\alpha,\\beta)$ scaling of $(Q,R)$ at $T_s=20$ ms, $N_p=20$.}\\label{tab:tuningsweep}\n");
fprintf(fid, "\\begin{tabular}{llcccccccc}\\toprule\n");
fprintf(fid, "Controller & Regime & $\\alpha$ & $\\beta$ & $\\theta_{rms}$ & $u_{rms}$ & p95 [ms] & $J_{cl}$ & $f_{sat}$ & $f_{\\Delta u}$\\\\\\midrule\n");

for i=1:height(T)
    fprintf(fid, "%s & %s & %.2g & %.2g & %.4f & %.3f & %.2f & %.3g & %.2f & %.2f\\\\\n", ...
        T.controller{i}, T.tuning{i}, T.alpha(i), T.beta(i), ...
        T.theta_rms(i), T.u_rms(i), T.solve_p95_ms(i), T.Jcl(i), ...
        T.frac_u_sat(i), T.frac_du_sat(i));
end

fprintf(fid, "\\bottomrule\\end{tabular}\\end{table}\n");
fclose(fid);
end
