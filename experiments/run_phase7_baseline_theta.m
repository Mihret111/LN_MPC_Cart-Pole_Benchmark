function run_phase7_baseline_theta()
% Phase 7 — baseline-theta comparison under combined mismatch
% Produces: comparison tracking plots per severity + summary table

root = setup_paths();
figDir = fullfile(root,'figures');

cfg0 = default_config();

% Nominal baseline settings
cfg0.Ts = 0.02;
cfg0.Np = 20;
cfg0.sim.Tend = 10.0;
cfg0.sim.integrator_substeps = 10;

% ---- baseline theta0 ----
% theta0 = 0.1;   % rad  (~5.7 deg). Use deg2rad(10) if you prefer 10 deg.
theta0= deg2rad(8);       %theta0 = cfg0.x0(3);
% Severity levels
sev = [0.1 0.2 0.25];

% Controllers (must match your controller_init switch)
% ctrls = ["LMPC","CasadiNMPC"];
ctrls = ["linear_mpc","casadi_nmpc"];
labels = ["LMPC","CasADi NMPC"];

% Use nominal params to build overrides
params_nom = params_invpend();

rows = [];

for is = 1:numel(sev)
    s = sev(is);

    % same plant mismatch for both controllers
    plant_ov = make_combined_plant_override(params_nom, s);

    res_nom = cell(1,numel(ctrls));
    res_mis = cell(1,numel(ctrls));
    
    for ic = 1:numel(ctrls)
    
        % ---------- NOMINAL ----------
        cfgN = cfg0;
        cfgN.controller.type = ctrls(ic);
        cfgN.x0 = [0;0;theta0;0];
        if isfield(cfgN,'plant_override'); cfgN = rmfield(cfgN,'plant_override'); end
        cfgN.meta.name = sprintf("P7_baseTheta_%s_nominal", ctrls(ic));
        cfgN.meta.save_figures = false;
        cfgN.meta.save_results = true;
    
        res_nom{ic} = run_experiment(cfgN);
    
        % ---------- MISMATCH ----------
        cfgM = cfg0;
        cfgM.controller.type = ctrls(ic);
        cfgM.x0 = [0;0;theta0;0];
        cfgM.plant_override = plant_ov;
        cfgM.meta.name = sprintf("P7_baseTheta_%s_s%.1f", ctrls(ic), s);
        cfgM.meta.save_figures = false;
        cfgM.meta.save_results = true;
    
        res_mis{ic} = run_experiment(cfgM);
    
        % ---------- log “degradation” metrics ----------
        mN = res_nom{ic}.metrics;
        mM = res_mis{ic}.metrics;
    
        rows = [rows; struct( ...
            "controller", string(ctrls(ic)), ...
            "severity", s, ...
            "theta0_rad", theta0, ...
            "p95_nom_ms", mN.solve_p95_ms, ...
            "p95_mis_ms", mM.solve_p95_ms, ...
            "p95_delta_ms", mM.solve_p95_ms - mN.solve_p95_ms, ...
            "theta_rms_nom", mN.theta_rms, ...
            "theta_rms_mis", mM.theta_rms, ...
            "theta_rms_delta", mM.theta_rms - mN.theta_rms, ...
            "label_nom", classify_label_simple(res_nom{ic}), ...
            "label_mis", classify_label_simple(res_mis{ic}) ...
        )]; %#ok<AGROW>
    
    end

    % Comparison tracking plot (LMPC vs NMPC) for this severity
% plot_compare_controllers( ...
%     {res{1}, res{2}}, ...
%     {"LMPC","CasADi NMPC"}, ...
%     fullfile(figDir, sprintf("F7_baseTheta_compare_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) ...
% );
    % plot_compare_controllers( ...
    %     {res_nom, res_mis}, ...
    %     {sprintf("%s nominal", labels(ic)), sprintf("%s mismatch s=%.1f", labels(ic), s)}, ...
    %     fullfile(figDir, sprintf("F7_nom_vs_mis_%s_s%.1f_theta%.1fdeg.png", ctrls(ic), s, rad2deg(theta0))) ...
    % );

    % (A_1) Nominal vs mismatch for LMPC
plot_compare_controllers( {res_nom{1}, res_nom{2}}, {"LMPC","CasADi NMPC"}, ...
    fullfile(figDir, sprintf("F7_compare_controllers_nominal_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) );

    % (A_2) Controller-vs-controller under mismatch (you already do this)
plot_compare_controllers( {res_mis{1}, res_mis{2}}, {"LMPC mismatch","NMPC mismatch"}, ...
    fullfile(figDir, sprintf("F7_compare_controllers_mismatch_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) );

% (B) Nominal vs mismatch for LMPC
plot_compare_controllers( {res_nom{1}, res_mis{1}}, {"LMPC nominal","LMPC mismatch"}, ...
    fullfile(figDir, sprintf("F7_LMPC_nom_vs_mis_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) );

% (C) Nominal vs mismatch for CasADi NMPC
plot_compare_controllers( {res_nom{2}, res_mis{2}}, {"NMPC nominal","NMPC mismatch"}, ...
    fullfile(figDir, sprintf("F7_NMPC_nom_vs_mis_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) );

% (D) All in one
plot_compare_nominal_vs_mismatch( res_nom{1}, res_mis{1}, res_nom{2}, res_mis{2}, ...
    fullfile(figDir, sprintf("F7_ALL_nom_vs_mis_s%.1f_theta%.1fdeg.png", s, rad2deg(theta0))) );
end

%
T = struct2table(rows);

if ~exist("results","dir"), mkdir("results"); end
save("results/phase7_baseline_theta.mat","T","theta0","sev","cfg0");

% summary plot: p95 vs severity
make_phase7_p95_vs_severity(T);

disp("Phase 7 baseline-theta suite done.");
end
    