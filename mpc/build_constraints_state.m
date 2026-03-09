function [Axs, bxs] = build_constraints_state(Phi, Gamma, x0, Np, pmax, thetamax)
%BUILD_CONSTRAINTS_STATE  Constrain predicted states:
%   |p_k| <= pmax, |theta_k| <= thetamax for k=1..Np
% Uses X = Phi*x0 + Gamma*U, where X stacks x1..xNp (each is 4x1)

nx = 4;

% Selection rows to pick p and theta from each state vector
Sp = [1 0 0 0];      % picks p
St = [0 0 1 0];      % picks theta

A_list = {};
b_list = {};

for k = 1:Np
    rows = (k-1)*nx + (1:nx);

    Phi_k   = Phi(rows,:);
    Gamma_k = Gamma(rows,:);

    % p constraint: -pmax <= Sp*xk <= pmax
    A_p  = [  Sp*Gamma_k;
             -Sp*Gamma_k ];
    b_p  = [  pmax - Sp*Phi_k*x0;
              pmax + Sp*Phi_k*x0 ];

    % theta constraint: -thetamax <= St*xk <= thetamax
    A_t  = [  St*Gamma_k;
             -St*Gamma_k ];
    b_t  = [  thetamax - St*Phi_k*x0;
              thetamax + St*Phi_k*x0 ];

    A_list{end+1} = A_p;  b_list{end+1} = b_p; %#ok<AGROW>
    A_list{end+1} = A_t;  b_list{end+1} = b_t; %#ok<AGROW>
end

Axs = vertcat(A_list{:});
bxs = vertcat(b_list{:});
end
