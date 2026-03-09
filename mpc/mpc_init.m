function ctrl = mpc_init(Ad,Bd,Q,R,Np,Nc,umax,dumax_step,pmax,thetamax,Pterm)
%MPC_INIT Precompute constant matrices for fast MPC.
%
% ctrl stores all constant matrices so each MPC step is cheap.
%
% Inputs:
%   Ad,Bd : discrete model
%   Q,R   : stage weights
%   Np,Nc : horizons
%   umax  : input magnitude bound
%   dumax_step : per-sample delta-u bound
%   pmax, thetamax : state bounds over prediction horizon
%   Pterm : terminal weight (optional). If empty -> uses Q on all stages

nx = size(Ad,1);

ctrl.Ad = Ad; ctrl.Bd = Bd;
ctrl.Np = Np; ctrl.Nc = Nc;
ctrl.umax = umax;
ctrl.dumax_step = dumax_step;
ctrl.pmax = pmax;
ctrl.thetamax = thetamax;

% ---- Prediction matrices
[Phi,Gamma] = build_prediction_matrices(Ad,Bd,Np,Nc);    % Prediction matrices Φ and Γ (constant)
ctrl.Phi = Phi;
ctrl.Gamma = Gamma;

% Qbar and terminal cost
if nargin < 11 || isempty(Pterm)
    Qbar = kron(eye(Np), Q);
else
    Qbar = blkdiag(kron(eye(Np-1), Q), Pterm);
end
Rbar = kron(eye(Nc), R);

% ---- Big cost matrices
ctrl.Qbar = Qbar;
ctrl.Rbar = Rbar;

% ---- Constant Hessian H
H = 2*(Gamma' * Qbar * Gamma + Rbar);
ctrl.H = H;

% ---- Precompute constant multiplier for f(x) = Mf * x
% f = 2*Gamma'*Qbar*Phi*x
ctrl.Mf = 2*(Gamma' * Qbar * Phi);

% ---- Precompute constant part of state constraint matrix A_xs ----
% We constrain p and theta at each predicted step k=1..Np:
% x_k = Phi_k*x0 + Gamma_k*U
% so constraints become:  S*Gamma_k*U <= bound - S*Phi_k*x0

Sp = [1 0 0 0];   % selects p
St = [0 0 1 0];   % selects theta

Axs_blocks = cell(Np,1); % Constant part of state constraints matrix

for k = 1:Np
    rows = (k-1)*nx + (1:nx);
    Gamma_k = Gamma(rows,:);

    % two-sided constraints for p and theta
    A_p = [  Sp*Gamma_k;
            -Sp*Gamma_k ];
    A_t = [  St*Gamma_k;
            -St*Gamma_k ];

    Axs_blocks{k} = [A_p; A_t];  % (4 x Nc)
end

ctrl.Axs = vertcat(Axs_blocks{:});   % (4*Np x Nc)

% Precompute selector applied to Phi*x0 for RHS updates:
% b depends on -S*Phi_k*x0 or +S*Phi_k*x0. We'll compute it quickly each step.
ctrl.Sp = Sp;
ctrl.St = St;

end
