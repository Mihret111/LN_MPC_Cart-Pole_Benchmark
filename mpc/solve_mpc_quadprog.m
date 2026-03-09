function [u0,info, Usol] = solve_mpc_quadprog(H,f,Aineq,bineq, Uinit, u_prev)
%SOLVE_MPC_QUADPROG Solve QP with quadprog.

if nargin < 5
    Uinit = [];
end

Nc = size(H,1);

if nargin < 5 || isempty(Uinit)
    Uinit = zeros(Nc,1);   % <-- REQUIRED for active-set
end

% opts = optimoptions('quadprog', ...
%     'Display','off', ...
%     'Algorithm','interior-point-convex');

opts = optimoptions('quadprog', ...
    'Display','off', ...
    'Algorithm','active-set', ...
    'MaxIterations', 200);                  % keep reasonable
t0 = tic;
% [U,~,exitflag,output] = quadprog(H,f,Aineq,bineq,[],[],[],[],[],opts);
try
    [U,~,exitflag,output] = quadprog(H,f,Aineq,bineq,[],[],[],[],Uinit,opts);
catch ME
    % hard fallback if quadprog errors
    U = [];
    exitflag = -999;
    output.message = ME.message;
end

solve_time = toc(t0);

info.exitflag = exitflag;
info.output   = output;
info.solve_time = solve_time;

if exitflag <= 0 || isempty(U)
    % fallback: if infeasible, return zero input
    % Fall back basically is when the algorithm reverts to a simpler, 
    % safer, or alternative mode of operation if the primary
    % method fail

    % so, this catches failure
    u0 = u_prev;
    % new
    % u0 = Uinit(1);   % or u_prev passed in, but you don't have it here
    Usol=[];
    info.fallback = true;
    disp(output.message);
else
    u0 = U(1);
    Usol= U;
    info.fallback = false;
end
end
