function [u,diag] = mpc_step(xhat, u_prev, Ad, Bd, Q, R, Np, Nc, umax, dumax_step, pmax, thetamax, P)

[Phi,Gamma] = build_prediction_matrices(Ad,Bd,Np,Nc);

[H,f] = build_qp_cost(Phi,Gamma,xhat,Q,R,Np,Nc, P);       % modified to use P from the lqr calculation

[A_ud, b_ud] = build_constraints_u_du(Nc, umax, dumax_step, u_prev);
[A_xs, b_xs] = build_constraints_state(Phi, Gamma, xhat, Np, pmax, thetamax);

Aineq = [A_ud; A_xs];
bineq = [b_ud; b_xs];

[u,info] = solve_mpc_quadprog(H,f,Aineq,bineq);
diag = info;
end
