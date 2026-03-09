function make_phase7_p95_vs_severity(T)

root = setup_paths();
figDir = fullfile(root,'figures');
%  fullfile(figDir, "  ->  fullfile(figDir, "
%   .png"   ->  .png")
% exportgraphics(gcf, fullfile(figDir, "F07_success_vs_theta0.png"), 'Resolution', 250);
% exportgraphics(gcf, fullfile(figDir, "F11_Jcl_vs_Np.png"), 'Resolution', 250);
 

% if ~exist("figures","dir"), mkdir("figures"); end

controllers = unique(T.controller,'stable');
figure('Color','w'); hold on; grid on;

for i=1:numel(controllers)
    Tc = T(strcmp(T.controller,controllers{i}),:);
    plot(Tc.severity, Tc.p95_mis_ms, '-o');
end

rt_ms = 1000 * unique(T.theta0_rad*0 + 1) * 0; %#ok<NASGU>
% better: use Ts from one stored config if you saved it; otherwise just annotate manually
xlabel('mismatch severity s');
ylabel('solve time p95 [ms]');
legend(controllers,'Location','best');
yline(20,'--','Budget');

title('p95 solver time vs combined mismatch');
exportgraphics(gcf,fullfile(figDir, "F7_p95_vs_mismatch_basetheta.png"),'Resolution',250);
end
