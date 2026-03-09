function T = run_phase6_stress_suite()
%  Stress suite (12 scenarios x 2 controllers)
% Outputs:
%   figures/F19_phase6_failure_counts.png
%   figures/F20_phase6_success_matrix.png
%   paper/tables/T06_phase6_stress_suite.tex
%
% Requires:
%   - run_experiment supports cfg.params_override (patch)
%   - classify_run.m in path
root = setup_paths();
figDir = fullfile(root,'figures');
%  fullfile(figDir, "  ->  fullfile(figDir, "
%   .png"   ->  .png")
% exportgraphics(gcf, fullfile(figDir, "F19_phase6_failure_counts.png"), 'Resolution', 250);

% exportgraphics(gcf, fullfile(figDir, "F07_success_vs_theta0.png"), 'Resolution', 250);

cfg0 = default_config();
cfg0.sim.integrator_substeps = 10;

% Make NMPC prediction match plant fidelity (super important for constraints)
cfg0.nmpc.rollout_substeps = cfg0.sim.integrator_substeps;

% Keep Phase 6 consistent and fast
cfg0.Ts = 0.02;
cfg0.Np = 20;
cfg0.sim.Tend = 4.0;
cfg0.meta.save_figures = false;  % too many runs otherwise
cfg0.meta.save_results = true;

% Use Balanced tuning (your default Q,R)
% cfg0.Q and cfg0.R already set in default_config.

controllers = struct( ...
    'type',  {"linear_mpc","casadi_nmpc"}, ...
    'name',  {"LMPC","CasADi NMPC"} ...
);

% 12-scenario core suite:
theta_list = [0.12 0.22 0.35 0.40];

suite = [];
idx = 0;

% Block A: baseline constraints
for th = theta_list
    idx = idx+1;
    suite(idx).tag  = sprintf("BASE_th%.2f", th);
    suite(idx).pmax = 0.50;
    suite(idx).umax = 10;
    suite(idx).th0  = th;
end

% Block B: tight track
for th = theta_list
    idx = idx+1;
    suite(idx).tag  = sprintf("TIGHTP_th%.2f", th);
    suite(idx).pmax = 0.40;    % 0.1
    suite(idx).umax = 10;
    suite(idx).th0  = th;
end

% Block C: weak actuator
for th = theta_list
    idx = idx+1;
    suite(idx).tag  = sprintf("WEAKU_th%.2f", th);
    suite(idx).pmax = 0.50;
    suite(idx).umax = 5;    % 2
    suite(idx).th0  = th;
end

% Ensure output dirs exist
if ~exist("figures","dir"), mkdir("figures"); end
if ~exist(fullfile("paper","tables"),"dir"), mkdir(fullfile("paper","tables")); end

rows = [];
r = 0;

for c = 1:numel(controllers)
    for s = 1:numel(suite)

        cfg = cfg0;
        cfg.controller.type = controllers(c).type;

        % initial condition
        cfg.x0 = [0; 0; suite(s).th0; 0];

        % parameter overrides
        cfg.params_override = struct();
        cfg.params_override.pmax = suite(s).pmax;
        cfg.params_override.umax = suite(s).umax;

        % unique run name
        cfg.meta.name = sprintf("P6_%s_%s", controllers(c).name, suite(s).tag);

        % run
        res = run_experiment(cfg);

        % classify
        cls = classify_run(res);

        % store
        r = r+1;
        rows(r).controller = controllers(c).name;
        rows(r).scenario   = suite(s).tag;
        rows(r).pmax       = suite(s).pmax;
        rows(r).umax       = suite(s).umax;
        rows(r).theta0     = suite(s).th0;

        rows(r).label      = cls.label;

        % key metrics (if stabilized they make sense; otherwise still useful)
        rows(r).theta_rms      = res.metrics.theta_rms;
        rows(r).theta_settle_s = res.metrics.theta_settle_s;
        rows(r).p_maxabs       = res.metrics.p_maxabs;
        rows(r).u_maxabs       = res.metrics.u_maxabs;

        rows(r).solve_p95_ms   = res.metrics.solve_p95_ms;
        rows(r).solve_max_ms   = res.metrics.solve_max_ms;

        rows(r).fallback_steps = sum(res.fallback);

    end
end

T = struct2table(rows);

% --------- Make summary plots ----------
make_phase6_failure_counts(T);
make_phase6_success_matrix(T)
% make_phase6_success_matrix(T, suite.tag, {controllers.name}); % WRONG
% -> change to:
% make_phase6_success_matrix(T, {suite.tag{:}}, {controllers.name{:}}); % if you really want braces

% --------- Export LaTeX table ----------
export_phase6_table(T, fullfile("paper","tables","T06_phase6_stress_suite.tex"));

disp("Phase 6 completed:");
disp(" - figures/F19_phase6_failure_counts.png");
disp(" - figures/F20_phase6_success_matrix.png");
disp(" - paper/tables/T06_phase6_stress_suite.tex");

end


function make_phase6_failure_counts(T)
root = setup_paths();
figDir = fullfile(root,'figures');

% Bar plot: counts per label, grouped by controller
figure('Color','w'); hold on; grid on;

labels = unique(T.label);
controllers = unique(T.controller);

C = zeros(numel(labels), numel(controllers));
for i=1:numel(labels)
    for j=1:numel(controllers)
        C(i,j) = sum(strcmp(T.label, labels{i}) & strcmp(T.controller, controllers{j}));
    end
end

bar(categorical(labels), C);
ylabel('count');
title(' Failure taxonomy counts');
legend(controllers,'Location','best');
exportgraphics(gcf, fullfile(figDir, "F19_phase6_failure_counts.png"), 'Resolution', 250);
end


% function make_phase6_success_matrix(T, scenario_order, controller_order)
% % Heatmap-like matrix: 1 if OK, 0 otherwise
% root = setup_paths();
% figDir = fullfile(root,'figures');

function make_phase6_success_matrix(T)

root = setup_paths();
figDir = fullfile(root,'figures');
% preserve order as they appear in the table
sc = unique(T.scenario, 'stable');
ct = unique(T.controller,'stable');

M = zeros(numel(ct), numel(sc));

for i = 1:numel(ct)
    for j = 1:numel(sc)
        mask = strcmp(T.controller, ct{i}) & strcmp(T.scenario, sc{j});
        if any(mask)
            lab = string(T.label(mask));
            M(i,j) = any(lab == "OK");   % binary 0/1
        else
            M(i,j) = 0;
        end
    end
end

figure('Color','w');
imagesc(M);
colormap(gray);
caxis([0 1]);           % force binary scaling
colorbar;

set(gca,'XTick',1:numel(sc),'XTickLabel',sc,'XTickLabelRotation',35);
set(gca,'YTick',1:numel(ct),'YTickLabel',ct);

title('Success matrix (OK=1, otherwise=0)');
exportgraphics(gcf, fullfile(figDir, "F20_phase6_success_matrix.png"), 'Resolution', 250);
end



function export_phase6_table(T, outpath)
root = setup_paths();
figDir = fullfile(root,'figures');

fid = fopen(outpath,'w');
assert(fid>0, "Could not open %s", outpath);

fprintf(fid,"%% Auto-generated by run_phase6_stress_suite.m\n");
fprintf(fid,"\\begin{table}[t]\\centering\n");
fprintf(fid,"\\caption{Phase 6 stress suite (12 scenarios) with failure taxonomy and key metrics at $T_s=20$ ms, $N_p=20$.}\\label{tab:phase6suite}\n");
fprintf(fid,"\\begin{tabular}{llccccccc}\\toprule\n");
fprintf(fid,"Controller & Scenario & $p_{\\max}$ & $u_{\\max}$ & $\\theta_0$ & label & p95 [ms] & $\\theta_{rms}$ & fallback\\\\\\midrule\n");

for i=1:height(T)
    fprintf(fid,"%s & %s & %.2f & %.0f & %.2f & %s & %.1f & %.4f & %d\\\\\n", ...
        T.controller{i}, T.scenario{i}, T.pmax(i), T.umax(i), T.theta0(i), ...
        string(T.label{i}), T.solve_p95_ms(i), T.theta_rms(i), T.fallback_steps(i));
end

fprintf(fid,"\\bottomrule\\end{tabular}\\end{table}\n");
fclose(fid);
end
