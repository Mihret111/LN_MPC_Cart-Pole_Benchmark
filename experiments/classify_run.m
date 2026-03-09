function cls = classify_run(res)
%CLASSIFY_RUN Classify run outcome for Phase 6 stress testing.

params = res.params;
cfg    = res.cfg;
size(res.X)
% theta = res.X(:,3);      %% X: 4 501
% p     = res.X(:,1);
theta = res.X(3,:);   % theta over time
p     = res.X(1,:);   % position over time

u     = res.U(:);

cls = struct();
cls.label = "OK";

% --- numeric divergence ---
if any(~isfinite(res.X(:))) || any(~isfinite(res.U(:)))
    cls.label = "DIVERGED";
    return;
end

% --- hard constraint violations (these are the real "safety" failures) ---
tol = 1e-4;
if any(abs(theta) > params.thetamax + tol), cls.label="ENVELOPE VIOLATION"; return; end
if any(abs(p)     > params.pmax     + tol), cls.label="TRACK VIOLATION";    return; end
if any(abs(u)     > params.umax     + tol), cls.label="INPUT VIOLATION";    return; end


% --- fallback used (not necessarily failure, but report it) ---
if isfield(res,'fallback') && any(res.fallback)
    cls.label = "FALLBACK_USED";
end

% --- real-time violation (deployability criterion) ---
budget_ms = 1000*cfg.Ts;
if isfield(res,'metrics') && isfield(res.metrics,'solve_p95_ms')
    if res.metrics.solve_p95_ms > budget_ms
        cls.label = "RT VIOLATION";
        return;
    end
end
end
