function ov = make_combined_plant_override(params_nom, s)
% Combined mismatch severity s in [0, 0.3] typically.

ov = struct();

% Masses
ov.m  = params_nom.m  * (1 + s);
ov.M  = params_nom.M  * (1 + s);     % comment out if too harsh

% Friction/damping (stronger mismatch)
ov.bx = params_nom.bx * (1 + 2*s);
ov.ct = params_nom.ct * (1 + 2*s);

% Geometry (milder mismatch)
ov.l  = params_nom.l  * (1 + 0.5*s); % comment out if too harsh

% Keep inertia consistent if used explicitly
if isfield(params_nom,'I')
    ov.I = (1/3) * ov.m * (ov.l^2);
end
% ------------------------------------------  ------------------

end
