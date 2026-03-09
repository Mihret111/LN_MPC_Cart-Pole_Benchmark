function w0 = casadi_nmpc_shift_warmstart(w_opt, ctrl)
%CASADI_NMPC_SHIFT_WARMSTART Shift (X,U) solution forward for warm-start.
%
% Simple shift:
%   X0(:,k) <- X*(k+1) for k=0..Np-1, last state repeats
%   U0(k)   <- U*(k+1), last input repeats

nx = ctrl.nx;
Np = ctrl.Np;

% reshape X and U
Xvec = w_opt(1:ctrl.nX);
Uvec = w_opt(ctrl.nX+1 : ctrl.nX+Np);

X = reshape(Xvec, nx, Np+1);
U = reshape(Uvec, 1, Np);

X0 = [X(:,2:end), X(:,end)];
U0 = [U(:,2:end), U(:,end)];

w0 = [X0(:); U0(:)];
end
