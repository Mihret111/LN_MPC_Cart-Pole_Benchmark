function Jcl = compute_closedloop_cost(res)
if ~isstruct(res) || ~isfield(res,'cfg')
    error("compute_closedloop_cost: input must be a result struct with field res.cfg");
end

Q = res.cfg.Q;
R = res.cfg.R;
Ts = res.cfg.Ts;

X = res.X;          % 4 x (N+1)
U = res.U(:);       % N x 1

N = min(size(X,2)-1, numel(U));
Xk = X(:,1:N);
Uk = U(1:N);

J = 0;
for k = 1:N
    x = Xk(:,k);
    u = Uk(k);
    J = J + (x'*Q*x + (u'*R*u));
end

Jcl = J * Ts;
end
