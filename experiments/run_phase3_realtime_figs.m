function out = run_phase3_realtime_figs()
cfg = default_config();
cfg.Ts = 0.02;
cfg.Np = 20;

% Run controllers
cfg.controller.type = "linear_mpc";
res_lin = run_experiment(cfg);

% cfg.controller.type = "nmpc";
% res_fmin = run_experiment(cfg);

cfg.controller.type = "nmpc";
res_cas = run_experiment(cfg);
% results = {res_lin, res_fmin, res_cas};
% labels  = {'LMPC','NMPC fmincon','NMPC CasADi'};

results = {res_lin, res_cas};
labels  = {'LMPC','NMPC'};

% Ensure folders
if ~exist("figures","dir"), mkdir("figures"); end
if ~exist(fullfile("paper","tables"),"dir"), mkdir(fullfile("paper","tables")); end

% Plots
plot_solvetime_cdf(results, labels, cfg.Ts, "figures/F05_solvetime_cdf_Ts20ms.png");
plot_solvetime_timeseries(results, labels, cfg.Ts, "figures/F06_solvetime_timeseries_Ts20ms.png");

% Table export
export_baseline_table_latex(results, labels, fullfile("paper","tables","T01_baseline.tex"));

% Return for interactive use
out.results = results;
out.labels  = labels;
out.cfg     = cfg;
end
