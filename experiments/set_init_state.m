function cfg = set_init_state(cfg, x0)
% Try common names without breaking older code.
if isfield(cfg,'x0')
    cfg.x0 = x0;
elseif isfield(cfg,'x_init')
    cfg.x_init = x0;
elseif isfield(cfg,'init') && isstruct(cfg.init)
    cfg.init.x0 = x0;
else
    % fall back: create cfg.x0 
    cfg.x0 = x0;
end
end
