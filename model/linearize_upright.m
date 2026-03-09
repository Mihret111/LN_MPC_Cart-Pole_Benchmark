function [A,B] = linearize_upright(params)
%LINEARIZE_UPRIGHT  Continuous-time linearization about upright (theta=0).

M  = params.M;
m  = params.m;
l  = params.l;
g  = params.g;
bx = params.bx;
ct = params.ct;
I  = params.I;

D = (M + m)*(I + m*l^2) - (m*l)^2;

alpha = (I + m*l^2) / D;   % multiplies (F - bx*v) in vdot
beta  = (m*l)        / D;  % coupling term
gamma = (M + m)      / D;  % multiplies (mgl*theta - ct*omega) in omegadot

A = zeros(4,4);
B = zeros(4,1);

% p_dot = v
A(1,2) = 1;

% theta_dot = omega
A(3,4) = 1;

% v_dot = -alpha*bx*v + beta*mgl*theta - beta*ct*omega + alpha*F
A(2,2) = -alpha*bx;
A(2,3) =  beta*m*g*l;
A(2,4) = -beta*ct;
B(2)   =  alpha;

% omega_dot = -beta*bx*v + gamma*mgl*theta - gamma*ct*omega + beta*F
A(4,2) = -beta*bx;
A(4,3) =  gamma*m*g*l;
A(4,4) = -gamma*ct;
B(4)   =  beta;
end
