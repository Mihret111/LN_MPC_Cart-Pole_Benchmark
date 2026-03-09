function [Ad,Bd] = discretize_zoh(A,B,Ts)
%DISCRETIZE_ZOH  ZOH discretization using ss/c2d.

C = eye(size(A,1));
D = zeros(size(A,1), size(B,2));

sysc = ss(A,B,C,D);
sysd = c2d(sysc, Ts, 'zoh');

Ad = sysd.A;
Bd = sysd.B;
end
