function [Aineq,bineq] = build_constraints_u_du(Nc, umax, dumax, u_prev)
%BUILD_CONSTRAINTS_U_DU  Inequalities Aineq*U <= bineq
%
% U = [u0; u1; ...; uNc-1]
% Creates inequality constraints for:
%   -umax <= uk <= umax
%   -dumax <= (u0-u_prev) <= dumax
%   -dumax <= (u1-u0) <= dumax, ...

% 1) magnitude bounds: -umax <= U <= umax
A_u = [ eye(Nc); -eye(Nc) ];
b_u = [ umax*ones(Nc,1); umax*ones(Nc,1) ];

% 2) rate bounds: -dumax <= D*U + d0 <= dumax
% where D*U approximates [u0; u1-u0; u2-u1; ...]
D = zeros(Nc,Nc);
D(1,1) = 1;
for k=2:Nc
    D(k,k)   = 1;
    D(k,k-1) = -1;
end

d0 = zeros(Nc,1);
d0(1) = -u_prev;   % because first difference is u0 - u_prev

% -dumax <= D*U + d0 <= dumax
A_du = [ D; -D ];
b_du = [ dumax*ones(Nc,1) - d0;
         dumax*ones(Nc,1) + d0 ];

% Combine
Aineq = [A_u; A_du];
bineq = [b_u; b_du];
end
