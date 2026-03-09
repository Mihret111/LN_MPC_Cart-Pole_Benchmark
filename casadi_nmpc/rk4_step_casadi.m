function xnext = rk4_step_casadi(f, x, u, Ts, substeps)
%RK4_STEP_CASADI  RK4 integration for CasADi Function f(x,u)->xdot.
%
% substeps=1 gives one RK4 step over Ts.
% substeps>1 splits Ts into smaller dt (more accurate, slower).

dt = Ts / substeps;
xt = x;

for i = 1:substeps
    k1 = f(xt, u);
    k2 = f(xt + 0.5*dt*k1, u);
    k3 = f(xt + 0.5*dt*k2, u);
    k4 = f(xt + dt*k3, u);
    xt = xt + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
end

xnext = xt;
end
