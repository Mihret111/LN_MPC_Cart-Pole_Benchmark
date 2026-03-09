function [res_nom, res_mis] = run_nominal_and_mismatch(cfg0, controller_type, theta0, plant_ov)

    % ---- nominal (no mismatch) ----
    cfgN = cfg0;
    cfgN.controller.type = controller_type;
    cfgN.x0 = [0;0;theta0;0];
    cfgN.meta.save_figures = false;
    cfgN.meta.save_results = true;
    cfgN.meta.name = sprintf("P7_nom_%s", controller_type);

    % IMPORTANT: no plant_override
    if isfield(cfgN,'plant_override'); cfgN = rmfield(cfgN,'plant_override'); end
    res_nom = run_experiment(cfgN);

    % ---- mismatch ----
    cfgM = cfg0;
    cfgM.controller.type = controller_type;
    cfgM.x0 = [0;0;theta0;0];
    cfgM.plant_override = plant_ov;
    cfgM.meta.save_figures = false;
    cfgM.meta.save_results = true;
    cfgM.meta.name = sprintf("P7_mis_%s", controller_type);

    res_mis = run_experiment(cfgM);
end