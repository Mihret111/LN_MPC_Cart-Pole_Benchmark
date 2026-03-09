function run_phase7_2_force_disturbance()
root = setup_paths();
figDir = fullfile(root,'figures');

cfg0 = default_config();
cfg0.Ts = 0.02;
cfg0.Np = 20;
cfg0.sim.Tend = 40.0;
cfg0.sim.integrator_substeps = 40;

theta0 = deg2rad(8);

ctrls  = ["linear_mpc","casadi_nmpc"];
labels = ["LMPC","CasADi NMPC"];

% Disturbance type: FORCE PULSE (recommended)
cfg0.disturb = struct();
cfg0.disturb.enabled = true;
cfg0.disturb.type = "sine";
cfg0.disturb.t0 = 7.0;     % seconds
cfg0.disturb.T  = 0.10;    % 100 ms pulse
cfg0.disturb.f  = 0.10;    % 
% Sweep amplitudes [N] (tune as needed)
% Agrid = [0 1 2 3 4 5 6];
% Agrid = [0 5 10 15];
Agrid = [0 1 1.5 1.8 1.9 2 ];
% Agrid = [0 1.8 1.9] ;
rows = [];

% choose a few amplitudes for detailed tracking plots (sweet spots)
% A_plot = [5 10 15];
A_plot = [0 1 1.5 1.8  1.9  2];
% A_plot = [1.9]  ;

for ia = 1:numel(Agrid)
    A = Agrid(ia);

    cfg0.disturb.A = A;

    res = cell(1,numel(ctrls));
    for ic = 1:numel(ctrls)
        cfg = cfg0;
        cfg.controller.type = ctrls(ic);
        cfg.x0 = [0;0;theta0;0];

        cfg.meta.save_figures = false;
        cfg.meta.save_results = true;
        cfg.meta.name = sprintf("P7_2_force_%s_A%.1f", ctrls(ic), A);

        res{ic} = run_experiment(cfg);

        m = res{ic}.metrics;
        rows = [rows; struct( ...
            "controller", string(ctrls(ic)), ...
            "A", A, ...
            "theta0_rad", theta0, ...
            "solve_p95_ms", m.solve_p95_ms, ...
            "solve_max_ms", m.solve_max_ms, ...
            "theta_rms", m.theta_rms, ...
            "theta_maxabs", m.theta_maxabs, ...
            "p_maxabs", m.p_maxabs, ...
            "label", classify_label_simple(res{ic}) ...
        )]; %#ok<AGROW>
    end

    % Tracking comparison plots only for selected amplitudes
    if any(abs(A - A_plot) < 1e-9)
        plot_compare_controllers( ...
            {res{1}, res{2}}, ...
            {"LMPC","CasADi NMPC"}, ...
            fullfile(figDir, sprintf("F7_2_compare_A%.1f_theta%.1fdeg.png", A, rad2deg(theta0))) ...
        );
    end
end

T = struct2table(rows);
if ~exist(fullfile(root,'results'),"dir"), mkdir(fullfile(root,'results')); end
save(fullfile(root,'results',"phase7_2_force_disturbance.mat"),"T","Agrid","A_plot","cfg0","theta0");

make_phase7_2_summary_plots(T, figDir);

disp("Phase 7.2 force disturbance done.");
end