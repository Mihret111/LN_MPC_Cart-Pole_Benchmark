function xdot = invpend_f_casadi(x, u, params)
%INVPEND_F_CASADI  CasADi version of model/f_nl.m (upright theta=0).
%
% State x = [p; v; theta; omega]
% Input u = force [N]
%
% Uses same equations as f_nl.m:
%   A_dyn * [pdd; thetadd] = rhs

p     = x(1); %#ok<NASGU>
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

A_dyn = [ M + m,     -m*l*c;
         -m*l*c,      I + m*l^2];

rhs = [ u - bx*v - m*l*(omega^2)*s;
        m*g*l*s - ct*omega ];

acc = A_dyn \ rhs;

pdd     = acc(1);
thetadd = acc(2);

xdot = [ v;
         pdd;
         omega;
         thetadd ];
end
