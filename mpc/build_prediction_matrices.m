function [Phi,Gamma] = build_prediction_matrices(Ad,Bd,Np,Nc)
%BUILD_PREDICTION_MATRICES  X = Phi*x0 + Gamma*U
% X stacks states x1..xNp, U stacks inputs u0..uNc-1
%
% Ad: nxn, Bd: nx1 (single input assumed here)
% Phi: (Np*nx) x nx
% Gamma: (Np*nx) x Nc

nx = size(Ad,1);

Phi   = zeros(Np*nx, nx);
Gamma = zeros(Np*nx, Nc);

A_pow = eye(nx);

for i = 1:Np
    A_pow = Ad * A_pow;  % Ad^i
    Phi((i-1)*nx+1:i*nx,:) = A_pow;

    for j = 1:min(i,Nc)
        % contribution of u_{j-1} to x_i is Ad^(i-j)*Bd
        A_ij = Ad^(i-j);
        Gamma((i-1)*nx+1:i*nx, j) = A_ij * Bd;
    end
end
end
