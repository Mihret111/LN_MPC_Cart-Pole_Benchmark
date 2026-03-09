function bxs = build_state_rhs_fast(ctrl, x0)
%BUILD_STATE_RHS_FAST Build RHS for state constraints using cached ctrl.
% Constraints at each k:
    %   -pmax <= p_k <= pmax
    %   -thetamax <= theta_k <= thetamax

% Computes only the RHS of state constraints, because the matrix part was cached
nx = 4;
Np = ctrl.Np;

pmax = ctrl.pmax;
thetamax = ctrl.thetamax;

Phi = ctrl.Phi;
Sp = ctrl.Sp;
St = ctrl.St;

bxs = zeros(4*Np,1);

for k = 1:Np
    rows = (k-1)*nx + (1:nx);
    Phi_k = Phi(rows,:);

    pk     = Sp*Phi_k*x0;
    thetak = St*Phi_k*x0;

    % For each k we stack:
    % p:   Sp*Gamma U <= pmax - pk
    %      -Sp*Gamma U <= pmax + pk
    % theta similarly
    idx = (k-1)*4 + (1:4);

    bxs(idx) = [ pmax - pk;
                 pmax + pk;
                 thetamax - thetak;
                 thetamax + thetak ];
end
end
