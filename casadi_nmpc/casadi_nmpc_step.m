function [u0, diag, ctrl] = casadi_nmpc_step(ctrl, xhat, u_prev)
%CASADI_NMPC_STEP  One NMPC step using pre-built CasADi solver.
%
% Parameters:
%   xhat   - current state estimate (4x1)
%   u_prev - previously applied input (scalar)
%
% Outputs:
%   u0     - first optimal input
%   diag   - diagnostic struct
%
import casadi.*

t0 = tic;

% Parameter vector
p = [xhat; u_prev];

% Solve NLP
sol = ctrl.solver('x0', ctrl.w0, ...
                  'lbx', ctrl.lbw, 'ubx', ctrl.ubw, ...
                  'lbg', ctrl.lbg, 'ubg', ctrl.ubg, ...
                  'p', p);

solve_time = toc(t0);

w_opt = full(sol.x);
stats = ctrl.solver.stats();

status = string(stats.return_status);
ok = stats.success && (status=="Solve_Succeeded" || status=="Solved_To_Acceptable_Level");

% Extract first input u0
Np = ctrl.Np;

if ok
    u_seq = w_opt(ctrl.nX+1 : ctrl.nX+Np);
    u0 = u_seq(1);
    ctrl.w0 = casadi_nmpc_shift_warmstart(w_opt, ctrl);
    diag.fallback = false;
else
    % fallback: hold previous input (or call LQR if you want)
    u0 = u_prev;
    diag.fallback = true;
end

% % ALWAYS enforce safety clamp at the plant input
% u0 = min(max(u0, -ctrl.umax), ctrl.umax);
% 
% % optional: rate clamp too
% du_max = ctrl.dumax_step;
% u0 = min(max(u0, u_prev - du_max), u_prev + du_max);


% Update warm start guess by shifting
ctrl.w0 = casadi_nmpc_shift_warmstart(w_opt, ctrl);

diag = struct();
diag.solve_time = solve_time;
diag.status = string(stats.return_status);
diag.iterations = stats.iter_count;
diag.success = stats.success;
end
