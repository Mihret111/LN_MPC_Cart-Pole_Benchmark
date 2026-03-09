function ctrl = controller_init(cfg, params)
%CONTROLLER_INIT Initialize chosen controller backend.
%
% Provides a unified interface so experiments can switch between:
%   - Linear MPC (QP via quadprog)
%   - NMPC (NLP via fmincon)

% --- Constraints ---
umax = params.umax;
dumax_step = params.dumax * cfg.Ts;   % N/s -> N per sample
pmax = params.pmax;
thetamax = params.thetamax;

% --- Linear model (for linear MPC, and for terminal P) ---
[A,B] = linearize_upright(params);
[Ad,Bd] = discretize_zoh(A,B,cfg.Ts);

% --- Terminal cost (LQR Riccati) ---
[~,P,~] = dlqr(Ad,Bd,cfg.Q,cfg.R);

% --- Select controller ---
% type = string(cfg.controller.type);
% --- Select controller ---
if isstruct(cfg.controller) && isfield(cfg.controller,'type')
    type = string(cfg.controller.type);
elseif isstring(cfg.controller) || ischar(cfg.controller)
    type = string(cfg.controller);
else
    error("controller_init: cfg.controller must be a struct with field 'type' or a string/char.");
end

type = lower(strtrim(type));


switch type
    case "linear_mpc"
        ctrl = mpc_init(Ad,Bd,cfg.Q,cfg.R,cfg.Np,cfg.Nc,umax,dumax_step,pmax,thetamax,P);
        ctrl.type = "linear_mpc";

    case "nmpc"
        ctrl = nmpc_init(cfg, params, P);
        ctrl.type = "nmpc";
        
    case "casadi_nmpc"
        [A,B] = linearize_upright(params);
        [Ad,Bd] = discretize_zoh(A,B,cfg.Ts);
        [~,P,~] = dlqr(Ad,Bd,cfg.Q,cfg.R);
        ctrl = casadi_nmpc_init(cfg, params, P);

    case "lqr"
        % Linearize around upright equilibrium (theta=0)
        [A,B] = linearize_upright(params);      % you already have something like this
        [Ad,Bd] = discretize_zoh(A,B,cfg.Ts);   % you already have discretization for MPC
    
        % Discrete LQR gain
        [K,P,~] = dlqr(Ad,Bd,cfg.Q,cfg.R);
    
        ctrl.type = "lqr";
        ctrl.K = K;
        ctrl.P = P;
        ctrl.u_prev = 0;
    
        % constraints for limiter/sat
        ctrl.umax = params.umax;
        ctrl.dumax_step = params.dumax * cfg.Ts;
    
        % options
        if isfield(cfg,'lqr') && isfield(cfg.lqr,'use_rate_limiter')
            ctrl.use_rate_limiter = cfg.lqr.use_rate_limiter;
        else
            ctrl.use_rate_limiter = true;
        end
        
        if isfield(cfg,'lqr') && isfield(cfg.lqr,'use_saturation')
            ctrl.use_saturation = cfg.lqr.use_saturation;
        else
            ctrl.use_saturation = true;
        end

    otherwise
        error("Unknown cfg.controller.type: %s", type);
end
end
