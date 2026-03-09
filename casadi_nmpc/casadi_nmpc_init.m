function ctrl = casadi_nmpc_init(cfg, params, P)
%CASADI_NMPC_INIT  Build a stabilizing NMPC (upright theta=0) using CasADi+IPOPT.
%
% Decision variables (multiple shooting):
%   X(:,k), k=0..Np    (4 x (Np+1))
%   U(:,k), k=0..Np-1  (1 x Np)
%
% Parameters:
%   p = [x0; u_prev]
%
% Constraints:
%   X(:,1) = x0
%   X(:,k+1) = F(X(:,k), U(k))   (discrete dynamics via RK4)
%   |u| <= umax (bounds)
%   |p| <= pmax, |theta| <= thetamax (variable bounds)
%   |du| <= dumax_step (optional inequality constraints)
%
% Cost:
%   sum x'Qx + u'Ru + terminal x'Px
%
% NOTE: Requires CasADi on path:
%   addpath('<casadi>/')
%   import casadi.*
%
import casadi.*

ctrl = struct();
ctrl.type = "casadi_nmpc";

% -------- copy config --------
ctrl.cfg = cfg;
ctrl.params = params;

Ts = cfg.Ts;
Np = cfg.Np;

ctrl.Ts = Ts;
ctrl.Np = Np;

Q = cfg.Q;
R = cfg.R;

ctrl.Q = Q;
ctrl.R = R;
ctrl.P = P;

ctrl.use_terminal_cost = cfg.controller.use_terminal_cost;
ctrl.use_du_constraint = cfg.controller.use_du_constraint;

% -------- limits --------
ctrl.umax = params.umax;
ctrl.dumax_step = params.dumax * Ts;
ctrl.pmax = params.pmax;
ctrl.thetamax = params.thetamax;

% Optional velocity bound (your params has vmax)
if isfield(params,"vmax")
    ctrl.vmax = params.vmax;
else
    ctrl.vmax = inf;
end

% Keep omega bounded for numerical sanity (not a "physical" constraint)
ctrl.omegamax = 50;   % rad/s

% -------- RK4 substeps inside the optimizer --------
if isfield(cfg,"nmpc") && isfield(cfg.nmpc,"rollout_substeps")
    sub = cfg.nmpc.rollout_substeps;
else
    sub = 1;
end
ctrl.rollout_substeps = sub;

% -------- build CasADi symbols --------
nx = 4; nu = 1;

X = SX.sym('X', nx, Np+1);
U = SX.sym('U', nu, Np);

% Parameters: x0 (4) + u_prev (1)
Ppar = SX.sym('P', 5, 1);
x0 = Ppar(1:4);
u_prev = Ppar(5);

% Dynamics function in CasADi form
x = SX.sym('x', nx);
u = SX.sym('u', nu);
xdot = invpend_f_casadi(x, u, params);
f = Function('f', {x,u}, {xdot});

% RK4 discrete step
xk = SX.sym('xk', nx);
uk = SX.sym('uk', nu);
xkp1 = rk4_step_casadi(f, xk, uk, Ts, sub);
F = Function('F', {xk,uk}, {xkp1});

% -------- NLP cost + constraints --------
J = 0;
g = [];

% 1) initial condition equality: X(:,1) - x0 = 0
g = [g; X(:,1) - x0];

% 2) dynamics equalities
for k = 1:Np
    xk = X(:,k);
    uk = U(:,k);
    g = [g; X(:,k+1) - F(xk, uk)];

    J = J + xk.'*Q*xk + (uk.'*R*uk);
end

% terminal cost
if ctrl.use_terminal_cost
    xN = X(:,Np+1);
    J = J + xN.'*P*xN;
end

% 3) delta-u inequality constraints (optional)
if ctrl.use_du_constraint
    du = SX.zeros(Np,1);
    du(1) = U(:,1) - u_prev;
    for k=2:Np
        du(k) = U(:,k) - U(:,k-1);
    end
    g = [g; du];
end

% decision vector
w = [X(:); U(:)];

% -------- bounds on variables (state/input box constraints) --------
% lbw/ubw are numeric vectors same length as w
lbw = -inf*ones(size(w));
ubw =  inf*ones(size(w));

% helper: linear indices for X and U inside w
nX = nx*(Np+1);
% X is first nX entries in column-major

% bounds for each state at each stage
for k=0:Np
    % index base for X(:,k)
    % Column-major: X(:,k+1) occupies entries (k*nx+1 : (k+1)*nx) within X(:)
    i0 = k*nx + 1;

    % p
    lbw(i0+0) = -ctrl.pmax;
    ubw(i0+0) =  ctrl.pmax;

    % v
    if isfinite(ctrl.vmax)
        lbw(i0+1) = -ctrl.vmax;
        ubw(i0+1) =  ctrl.vmax;
    end

    % theta
    lbw(i0+2) = -ctrl.thetamax;
    ubw(i0+2) =  ctrl.thetamax;

    % omega
    lbw(i0+3) = -ctrl.omegamax;
    ubw(i0+3) =  ctrl.omegamax;
end

% bounds for U after X(:)
for k=1:Np
    idxU = nX + k;  % U is 1xNp, so U(:) length Np
    lbw(idxU) = -ctrl.umax;
    ubw(idxU) =  ctrl.umax;
end

% -------- bounds on constraints g --------
ng_eq = nx + nx*Np;   % x0 constraint + dynamics constraints
lbg = zeros(ng_eq,1);
ubg = zeros(ng_eq,1);

if ctrl.use_du_constraint
    % append du bounds
    lbg = [lbg; -ctrl.dumax_step*ones(Np,1)];
    ubg = [ubg;  ctrl.dumax_step*ones(Np,1)];
end

% -------- solver options --------
opts = struct();
opts.ipopt.print_level = 0;
opts.print_time = false;

%% Hard caps for real-time-ish behavior (tune later)
if isfield(cfg,"nmpc") && isfield(cfg.nmpc,"max_iter")
    opts.ipopt.max_iter = cfg.nmpc.max_iter;
else
    opts.ipopt.max_iter = 15;
    % added to reduce max solve time
    opts.ipopt.max_cpu_time = 0.02;  % 20 ms cap (try 0.018 if you want tighter)
end

%% added to reduce max solve time
opts.ipopt.warm_start_init_point = 'yes';
opts.ipopt.mu_strategy = 'adaptive';
% These reduce weird “jump” behavior at the start
opts.ipopt.warm_start_bound_push = 1e-8;
opts.ipopt.warm_start_slack_bound_push = 1e-8;
opts.ipopt.warm_start_mult_bound_push = 1e-8;

%%
% tolerances
if isfield(cfg,"nmpc") && isfield(cfg.nmpc,"tol")
    opts.ipopt.tol = cfg.nmpc.tol;
      
    opts.ipopt.acceptable_tol = max(10*cfg.nmpc.tol, 1e-2);  % Risky, but to make it hard, set it to 2(% stop early if acceptable for 2 iterations)
else
    opts.ipopt.tol = 1e-3;
    opts.ipopt.acceptable_tol = 1e-2;
end

% JIT can help a lot on repeated solves (needs a compiler available)
opts.jit = true;
opts.jit_options = struct('flags', '-O2');

% build solver ONCE
nlp = struct('x', w, 'f', J, 'g', g, 'p', Ppar);
solver = nlpsol('solver', 'ipopt', nlp, opts);

% -------- store in ctrl --------
ctrl.solver = solver;
ctrl.lbw = lbw;
ctrl.ubw = ubw;
ctrl.lbg = lbg;
ctrl.ubg = ubg;

% indices to extract U and X from solution
ctrl.nx = nx;
ctrl.nX = nX;

% warm start memory (initial guess)
ctrl.w0 = zeros(size(w));
end
