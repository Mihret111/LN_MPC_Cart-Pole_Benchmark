function d = disturb_force(t, cfg)
% External force disturbance applied to the plant

d = 0;

if ~isfield(cfg,'disturb') || ~cfg.disturb.enabled
    return;
end

A = cfg.disturb.A;
type = lower(string(cfg.disturb.type));

switch type
    case "pulse"
        t0 = cfg.disturb.t0;
        T  = cfg.disturb.T;
        if t >= t0 && t < t0 + T
            d = A;
        end

    case "step"
        t0 = cfg.disturb.t0;
        if t >= t0
            d = A;
        end

    case "sine"
        t0 = cfg.disturb.t0;
        f  = cfg.disturb.f;
        if t >= t0
            d = A * sin(2*pi*f*(t - t0));
        end
end
end