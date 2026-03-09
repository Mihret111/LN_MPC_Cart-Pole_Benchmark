function xdot = f_nl(x, u, params)
%F_NL Nonlinear dynamics for cart-pendulum (upright angle = 0).
%
% State: x = [p; v; theta; omega]
% Input: u = force F [N]

p     = x(1);
v     = x(2);
theta = x(3);
omega = x(4);

M  = params.M;
m  = params.m;
l  = params.l;
g  = params.g;
bx = params.bx;
ct = params.ct;
I  = params.I;

s = sin(theta);
c = cos(theta);

% 2x2 system: A_dyn * [pdd; thetadd] = rhs
A_dyn = [ M + m,      -m*l*c;
         -m*l*c,       I + m*l^2];

rhs = [ u - bx*v - m*l*(omega^2)*s;
        m*g*l*s - ct*omega ];

acc = A_dyn \ rhs;      % robust solve

pdd     = acc(1);
thetadd = acc(2);

xdot = [ v;
         pdd;
         omega;
         thetadd ];
end
