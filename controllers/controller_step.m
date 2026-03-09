function [u, diag, ctrl] = controller_step(ctrl, xhat, u_prev)
%CONTROLLER_STEP One control step using whichever backend was initialized.

switch string(ctrl.type)
    case "linear_mpc"
        [u, diag, ctrl] = mpc_step_fast(ctrl, xhat, u_prev);

    case "nmpc"
        [u, diag, ctrl] = nmpc_step_fmincon(ctrl, xhat, u_prev);
    
    case "casadi_nmpc"
        [u,diag,ctrl] = casadi_nmpc_step(ctrl, xhat, u_prev);

    case "lqr"
        x = xhat(:);
        u = -ctrl.K * x;   % regulation to 0
    
        % --- rate limiter: |Δu| <= dumax_step
        if ctrl.use_rate_limiter
            du = u - u_prev;
            du = max(min(du, ctrl.dumax_step), -ctrl.dumax_step);
            u = u_prev + du;
        end
    
        % --- saturation: |u| <= umax
        if ctrl.use_saturation
            u = max(min(u, ctrl.umax), -ctrl.umax);
        end
    
        diag.solve_time = 0;      % essentially zero cost
        diag.fallback = false;
    
        ctrl.u_prev = u;

    otherwise
        error("Unknown controller type in ctrl.type");
end
end
