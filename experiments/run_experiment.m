function res = run_experiment(cfg)
%RUN_EXPERIMENT Runs one MPC experiment with given cfg.
%
% Output res contains trajectories, timing, metrics, and saved file paths.

root = setup_paths();

% --- Load parameters ---
% --- Load nominal parameters (controller model) ---
params_ctrl = params_invpend();

% Optional: overrides for controller model (if ever want)
if isfield(cfg,'params_override') && ~isempty(cfg.params_override)
    fn = fieldnames(cfg.params_override);
    for i = 1:numel(fn)
        params_ctrl.(fn{i}) = cfg.params_override.(fn{i});
    end
end

% --- Plant parameters (true) ---
params_plant = params_ctrl;

% NEW: plant-only mismatch override (Phase 7)
if isfield(cfg,'plant_override') && ~isempty(cfg.plant_override)
    fn = fieldnames(cfg.plant_override);
    for i = 1:numel(fn)
        params_plant.(fn{i}) = cfg.plant_override.(fn{i});
    end
end

% --- Constraints (from params unless overridden later) ---
% umax = params.umax;
% dumax_step = params.dumax * cfg.Ts;  % N/s -> N per sample  % where should this stem from?
% pmax = params.pmax;
% thetamax = params.thetamax;
umax = params_ctrl.umax;
dumax_step = params_ctrl.dumax * cfg.Ts;
pmax = params_ctrl.pmax;
thetamax = params_ctrl.thetamax;


% --- Linear model for MPC ---
[A,B] = linearize_upright(params_ctrl);  % distinction between plant and controller parameters

[Ad,Bd] = discretize_zoh(A,B,cfg.Ts);

% --- Terminal cost from LQR ---
[~,P,~] = dlqr(Ad,Bd,cfg.Q,cfg.R);

% --- Initialize controller backend ---
ctrl = controller_init(cfg, params_ctrl);

% % initialize from cfg   --- redundunt
% if isfield(cfg,'x0')
%     x0 = cfg.x0;
% elseif isfield(cfg,'init') && isfield(cfg.init,'x0')
%     x0 = cfg.init.x0;
% else
%     x0 = [0;0;0.1;0]; % default
% end



% --- Simulation allocation ---
Ts = cfg.Ts;
N = round(cfg.sim.Tend/Ts);

% x = cfg.sim.x0;
x = cfg.x0;

xhat = x;         % perfect state for now
u_prev = 0;

X = zeros(4,N+1); X(:,1) = x;
U = zeros(1,N);
D = zeros(1,N);          % <-- ADDED disturbance
solveT = zeros(1,N);
fallback = false(1,N);
t = (0:N)*Ts;

sub = cfg.sim.integrator_substeps;
dt = Ts/sub;

% --- Main loop ---
for k=1:N
    % controller step
    [u,diag,ctrl] = controller_step(ctrl, xhat, u_prev);

    % --- External force disturbance (Phase 7.2) ---
    tk = (k-1)*Ts;                    % current time [s]
    d  = disturb_force(tk, cfg);      % disturbance force [N]
    u_plant = u + d;                  % plant input
    D(k) = d;                         % log disturbance
    %

    U(k) = u;
    solveT(k) = diag.solve_time;
    fallback(k) = isfield(diag,'fallback') && diag.fallback;

    % Nonlinear plant integration (RK4)
    xt = x;
    for i=1:sub
        k1 = f_nl(xt, u_plant, params_plant);
        k2 = f_nl(xt + 0.5*dt*k1, u_plant, params_plant);
        k3 = f_nl(xt + 0.5*dt*k2, u_plant, params_plant);
        k4 = f_nl(xt + dt*k3, u_plant, params_plant);
        xt = xt + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    x = xt;
    X(:,k+1) = x;

    % Estimation (currently perfect)
    xhat = x;

    u_prev = u;
end

% --- Pack results ---
res = struct();
res.cfg = cfg;
% res.params = params;
res.params = struct();
res.params.ctrl  = params_ctrl;
res.params.plant = params_plant;


res.t = t;
res.X = X;
% size(x0)    %4     1
% size(X)     %4     501
res.U = U;
res.solveT = solveT;
res.fallback = fallback;
res.D = D;   % disturbance force history

% --- Metrics ---
res.metrics = compute_metrics(res);

% --- Save results ---
timestamp = datestr(now,'yyyy-mm-dd_HH-MM-SS');
base = cfg.meta.name + "_" + string(timestamp);

res.files = struct();
if cfg.meta.save_results
    outMat = fullfile(root,'results', base + ".mat");
    save(outMat,'res');
    res.files.mat = outMat;
end

% --- Plots ---
if cfg.meta.save_figures
    res.files.fig = plot_experiment(res, base);
end
end
