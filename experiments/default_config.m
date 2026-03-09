function cfg = default_config()
%DEFAULT_CONFIG Baseline experiment configuration.

cfg = struct();

% --- Sampling and horizons ---
cfg.Ts = 0.02;     % 20 ms    50 Hz sampling
cfg.Tp = 1.0;      % prediction window [s] (kept fixed)   50 samples
% cfg.Np = round(cfg.Tp/cfg.Ts);
cfg.Np = 20;      %% Tp = 0.4s or 20 samples taken as the prediction window
cfg.Nc = 10;

% --- Weights ---
% State order: [p v theta omega]
cfg.Q = diag([2, 0.1, 80, 1]);
cfg.R = 0.1;

% --- Controller selection ---
cfg.controller = struct();
cfg.controller.type = "linear_mpc";        % "linear_mpc" or "nmpc"
cfg.controller.use_terminal_cost = true;   % adds x_N' P x_N
cfg.controller.use_du_constraint = true;   % enforces |du| <= dumax_step

% for practical lqr
cfg.lqr.use_rate_limiter = true;
cfg.lqr.use_saturation   = true;

% --- NMPC solver settings (only used if type="nmpc") ---
cfg.nmpc = struct();
cfg.nmpc.solver = "fmincon_sqp";
% cfg.nmpc.max_iter = 60;
% cfg.nmpc.tol = 1e-3;
% cfg.nmpc.rollout_substeps = 5;   % RK4 substeps inside NMPC prediction

% --- Casadi NMPC
% cfg.controller.type = "casadi_nmpc";
% cfg.controller.use_terminal_cost = true;
% cfg.controller.use_du_constraint = true;

cfg.nmpc.max_iter = 15;   % cap for speed
cfg.nmpc.tol = 1e-3;
% cfg.nmpc.rollout_substeps = 1;

% --- Simulation setup ---
cfg.sim.Tend = 10.0;
cfg.x0 = [0; 0; deg2rad(8); 0];    % 0.1396 close to 0.14rad
% cfg.sim.x0 = [0; 0; deg2rad(8); 0];
cfg.sim.integrator_substeps = 10;  % RK4 substeps per Ts

cfg.nmpc.rollout_substeps= cfg.sim.integrator_substeps;

% --- Estimation mode ---
cfg.est.mode = "perfect"; % later: "KF", etc.

% --- Metadata for filenames ---
cfg.meta.name = "baseline_active_set";
cfg.meta.save_results = true;
cfg.meta.save_figures = true;
end
