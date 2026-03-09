function [u,diag, ctrl] = mpc_step_fast(ctrl, xhat, u_prev)
%MPC_STEP_FAST Fast MPC step using cached matrices.
        % Given current estimated state xhat and previous 
        % input u_prev, compute the next control input u.
        % returns u= uo

% Linear term
f = ctrl.Mf * xhat;

% Input magnitude + delta constraints 
% (depends on u_prev, thus must be computed each time step)
[A_ud, b_ud] = build_constraints_u_du(ctrl.Nc, ctrl.umax, ctrl.dumax_step, u_prev);

% State constraints: A part is constant, RHS depends on xhat
A_xs = ctrl.Axs;
b_xs = build_state_rhs_fast(ctrl, xhat);

Aineq = [A_ud; A_xs];
bineq = [b_ud; b_xs];

% Warm start init
if isfield(ctrl,'Uprev')
    Uinit = shift_warm_start(ctrl.Uprev);
else
    Uinit = [];  % if empty is passed, the solver will fill.
end

% Call QP solver and solve
[u,info, Usol] = solve_mpc_quadprog(ctrl.H, f, Aineq, bineq, Uinit, u_prev);

% Store solution for next step warm start
if ~isempty(Usol)
    ctrl.Uprev = Usol;
end

diag = info;
end
