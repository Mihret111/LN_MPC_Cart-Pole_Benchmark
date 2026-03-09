function run_baseline_mpc()
    % Load parameters
    % Build linear model + discretize
    % Choose MPC design values (Ts, Np, Nc, Q, R, constraints)
    % Initialize cached controller (ctrl = mpc_init(...))
    % Run a time loop:
        % call MPC each sample → get u
        % integrate nonlinear plant for one Ts
        % log everything
    % Plot results + print timing stats
% 
% close all; 
% clear all; clear

addpath('model'); addpath('mpc'); addpath('experiments');
addpath 'C:\Users\mihre\OneDrive\Desktop\SelectedTopics\Invpend_mpc_pipeline\model'
addpath 'C:\Users\mihre\OneDrive\Desktop\SelectedTopics\Invpend_mpc_pipeline\mpc'
addpath 'C:\Users\mihre\OneDrive\Desktop\SelectedTopics\Invpend_mpc_pipeline\experiments'
params = params_invpend();

% ----- Sampling and horizons -----
Ts = 0.02;           % [s] == 20ms  
Tp = 1.0;            % prediction window [s]
Np = round(Tp/Ts);   % keep time window fixed, about 50 samples ... 1 second
Nc = 10;

% ----- Linear model for MPC internal prediction -----
[A,B] = linearize_upright(params); % Creates the continuous-time linear model 
[Ad,Bd] = discretize_zoh(A,B,Ts);

% ----- Weights (baseline) -----
% State: [p v theta omega]
% clear diag
Q = [2  0  0  0;
     0  0.1  0  0;
     0  0   80  0;
     0  0   0   1];
R = 0.1;

% ----- Constraints -----
umax = params.umax;
dumax_step = params.dumax * Ts;   % convert N/s -> N per sample

% adding the state constraintsL
pmax = params.pmax;
thetamax = params.thetamax;


% ----- Simulation setup -----
Tend = 10.0;
N = round(Tend/Ts);

%% Adding terminal cost
[K,P,~] = dlqr(Ad,Bd,Q,R);  %#ok<ASGLU>

% [~,P,~] = dlqr(Ad,Bd,Q,R);

% Cached controller init
% Precompute all constant matrices needed by MPC
ctrl = mpc_init(Ad,Bd,Q,R,Np,Nc,umax,dumax_step,params.pmax,params.thetamax,P);


%%
x = [0; 0; deg2rad(8); 0];  % initial angle 8 deg
xhat = x;                   % for now: perfect state (estimation Phase 4)
u_prev = 0;

X = zeros(4,N+1); X(:,1) = x;
U = zeros(1,N);
solveT = zeros(1,N);
fallback = false(1,N);
t = (0:N)*Ts;

for k=1:N
    % --- MPC ---
    % [u,diag] = mpc_step(xhat, u_prev, Ad, Bd, Q, R, Np, Nc, umax, dumax_step);
    % [u,diag] = mpc_step(xhat, u_prev, Ad, Bd, Q, R, Np, Nc, umax, dumax_step, pmax, thetamax, P);
    [u,diag, ctrl] = mpc_step_fast(ctrl, xhat, u_prev);

    U(k) = u;
    solveT(k) = diag.solve_time;
    fallback(k) = isfield(diag,'fallback') && diag.fallback;

    % --- Nonlinear plant integration over one Ts (RK4) --- apply u to nonlinear plant
    dt = Ts/10;
    xt = x;
    for i=1:10
        % RK4 integration
        k1 = f_nl(xt, u, params);
        k2 = f_nl(xt + 0.5*dt*k1, u, params);
        k3 = f_nl(xt + 0.5*dt*k2, u, params);
        k4 = f_nl(xt + dt*k3, u, params);
        xt = xt + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    x = xt;
    X(:,k+1) = x;

    % perfect measurement for now
    xhat = x;

    u_prev = u;
end

% ----- Plots -----
figure; plot(t, X(3,:)); grid on;
xlabel('t [s]'); ylabel('\theta [rad]');
title('Baseline MPC on nonlinear plant (upright is 0)');

filename = 'baseline_MPC';
fileDir = 'C:\Users\mihre\OneDrive\Desktop\Doc\SelectedTopics\Invpend_mpc_pipeline\figures';
exportgraphics(gcf, fullfile(fileDir, filename + ".png"), 'Resolution', 300);
savefig(fullfile(fileDir, filename + ".fig"));
%%
figure; plot(t, X(1,:)); grid on;
xlabel('t [s]'); ylabel('p [m]');
title('Cart position');

filename = 'Cart_position';
fileDir = 'C:\Users\mihre\OneDrive\Desktop\Doc\SelectedTopics\Invpend_mpc_pipeline\figures';
exportgraphics(gcf, fullfile(fileDir, filename + ".png"), 'Resolution', 300);
savefig(fullfile(fileDir, filename + ".fig"));
%%
figure; stairs(t(1:end-1), U); grid on;
xlabel('t [s]'); ylabel('u [N]');
title('Control force');

filename = 'Control_force';
fileDir = 'C:\Users\mihre\OneDrive\Desktop\Doc\SelectedTopics\Invpend_mpc_pipeline\figures';
exportgraphics(gcf, fullfile(fileDir, filename + ".png"), 'Resolution', 300);
savefig(fullfile(fileDir, filename + ".fig"));
%%
figure; plot(t(1:end-1), solveT*1000); grid on;
xlabel('t [s]'); ylabel('solve time [ms]');
title('QP solve time (quadprog)');

filename = 'QP_solve_time';
fileDir = 'C:\Users\mihre\OneDrive\Desktop\Doc\SelectedTopics\Invpend_mpc_pipeline\figures';
exportgraphics(gcf, fullfile(fileDir, filename + ".png"), 'Resolution', 300);
savefig(fullfile(fileDir, filename + ".fig"));

fprintf('Fallback steps: %d / %d\n', sum(fallback), N);
fprintf('Avg solve time: %.3f ms\n', mean(solveT)*1000);
fprintf('95%% solve time: %.3f ms\n', prctile(solveT,95)*1000);
fprintf('Max solve time: %.3f ms\n', max(solveT)*1000);

% 
% if ~exist('figures', 'dir')
%     mkdir figures
% end

end
