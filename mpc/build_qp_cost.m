function [H,f,Qbar,Rbar] = build_qp_cost(Phi,Gamma,x0,Q,R,Np,Nc, P)
%BUILD_QP_COST  Builds H and f for quadprog:
%   0.5*U'*H*U + f'*U
%
% Q: nxn, R: 1x1 or scalar
% Qbar: blockdiag(Q,...,Q) size (Np*nx)
% Rbar: blockdiag(R,...,R) size (Nc)

nx = size(Q,1);

%% For the added terminal constraint
Qbar = kron(eye(Np), Q);
%%

% Qbar = kron(eye(Np), Q);
Qbar = blkdiag(kron(eye(Np-1), Q), P);    % For the added terminal constraint

Rbar = kron(eye(Nc), R);

% X = Phi*x0 + Gamma*U
% Cost = (Phi*x0 + Gamma*U)' Qbar (Phi*x0 + Gamma*U) + U' Rbar U
% => U' (Gamma'QbarGamma + Rbar) U + 2*(Phi*x0)'QbarGamma U + const
H = 2*(Gamma' * Qbar * Gamma + Rbar);
f = 2*(Gamma' * Qbar * Phi * x0);
end
