function run_phase7_1_combined_mismatch()


setup_paths();
cfg0 = default_config();

cfg0.Ts = 0.02;
cfg0.Np = 20;
cfg0.sim.Tend = 4.0;
cfg0.sim.integrator_substeps = 10;

% optional: ensure NMPC rollout matches plant substeps (if your NMPC uses it)
if isfield(cfg0,'nmpc')
    cfg0.nmpc.rollout_substeps = cfg0.sim.integrator_substeps;
end

rt_budget_ms = 1000*cfg0.Ts;

sev = [0.0 0.1 0.2 0.3];
theta_grid = deg2rad([4 6 8 10 12 14 16 18 20 22 24]);

% controllers = ["LMPC","CasadiNMPC"]; % must match how controller_init selects
controllers = ["linear_mpc","casadi_nmpc"];
labels = ["LMPC","CasADi NMPC"];

rows = [];

for c = 1:numel(controllers)
    for is = 1:numel(sev)
        s = sev(is);

        cfg = cfg0;
        cfg.controller.type = controllers(c);

        % Controller uses nominal params; plant uses perturbed params
        params_nom = params_invpend();
        cfg.plant_override = make_combined_plant_override(params_nom, s);

        out = find_boundaries_theta0(cfg, theta_grid, rt_budget_ms);

        rows = [rows; struct( ...
            "controller", string(controllers(c)), ...
            "severity", s, ...
            "theta0_max_stab", out.theta0_max_stab, ...
            "theta0_max_rt", out.theta0_max_rt, ...
            "p95_ms", out.p95_ms, ...
            "Jcl", out.Jcl, ...
            "label", string(out.label) ...
        )]; %#ok<AGROW>

        % Representative tracking plots (auto):
        % plot the boundary run + first failing run right above it
        % if ~isempty(out.rep_res_ok)
        %     plot_and_export_tracking(out.rep_res_ok, sprintf("F21_rep_%s_s%.1f_OK",controllers(c),s));
        % end
        % if ~isempty(out.rep_res_fail)
        %     plot_and_export_tracking(out.rep_res_fail, sprintf("F21_rep_%s_s%.1f_FAIL",controllers(c),s));
        % end
    end
end

T = struct2table(rows);

if ~exist("results","dir"), mkdir("results"); end
save("results/phase7_1_combined_mismatch.mat","T","cfg0","sev","theta_grid");

make_phase7_boundary_plots(T, rt_budget_ms);
% export_phase7_table_tex(T, "paper/tables/T07_phase7_combined_mismatch.tex", rt_budget_ms);
export_table_Ts(T, fullfile("paper","tables","T04_Ts_sweep_constantTp.tex"));

disp("Phase 7.1C complete.");
end
    