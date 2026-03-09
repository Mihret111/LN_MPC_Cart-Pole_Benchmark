function make_phase7_boundary_plots(T, rt_budget_ms)

root = setup_paths();
figDir = fullfile(root,'figures');

if ~exist("figures","dir"), mkdir("figures"); end

controllers = unique(T.controller,'stable');

figure('Color','w'); hold on;
for i=1:numel(controllers)
    Tc = T(strcmp(T.controller,controllers{i}),:);
    plot(Tc.severity, rad2deg(Tc.theta0_max_stab), '-o');
end
grid on; xlabel('mismatch severity s'); ylabel('\theta_{0,max}^{stab} [deg]');
legend(controllers,'Location','best');
exportgraphics(gcf,fullfile(figDir, "F22_theta0_stable_vs_mismatch.png"),'Resolution',250);

figure('Color','w'); hold on;
for i=1:numel(controllers)
    Tc = T(strcmp(T.controller,controllers{i}),:);
    plot(Tc.severity, rad2deg(Tc.theta0_max_rt), '-o');
end
grid on; xlabel('mismatch severity s'); ylabel('\theta_{0,max}^{rt} [deg]');
title(sprintf('Deployable boundary (p95 \\le %.1f ms)', rt_budget_ms));
legend(controllers,'Location','best');
exportgraphics(gcf,fullfile(figDir, "F23_theta0_deployable_vs_mismatch.png"),'Resolution',250);
end
